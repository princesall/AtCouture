import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Champs de mesures personnalisés définis par un atelier, en plus des 5
/// champs standards (épaule, poitrine, taille, hanche, longueur). Chaque
/// styliste travaille différemment selon le type de vêtement confectionné ;
/// un champ ajouté une fois ("Tour de bras", "Longueur manche"...) est
/// ensuite proposé pour tous les clients suivants du même atelier, plutôt
/// que d'obliger à le retaper à chaque commande.
///
/// PERSISTANCE — corrige un bug de perte de données : ce catalogue vivait
/// UNIQUEMENT en mémoire (seul service de l'application dans ce cas, sans
/// branche Firestore contrairement aux autres). Un champ ajouté disparaissait
/// donc au redémarrage de l'application, et n'était jamais visible depuis un
/// autre appareil du même atelier. Il est désormais stocké dans Firestore,
/// un document par atelier (measurementFields/{atelierId} → { labels: [...] }),
/// écouté en temps réel comme les autres services.
class MeasurementFieldsService {
  MeasurementFieldsService._();
  static final MeasurementFieldsService instance = MeasurementFieldsService._();

  /// Source de vérité en mode démo, cache tenu à jour par écoute Firestore
  /// en mode réel.
  final Map<String, List<String>> _customLabelsByAtelier = {};

  final Set<String> _syncedAteliers = {};
  final List<StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _subscriptions = [];

  List<String> customFieldsFor(String atelierId) {
    _ensureSynced(atelierId);
    return List.unmodifiable(_customLabelsByAtelier[atelierId] ?? const []);
  }

  void _ensureSynced(String atelierId) {
    if (!FirebaseService.isAvailable) return;
    if (!_syncedAteliers.add(atelierId)) return;

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('measurementFields')
          .doc(atelierId)
          .snapshots()
          .listen(
        (doc) {
          final data = doc.data();
          if (data == null) return;
          final labels = (data['labels'] as List?)?.map((e) => e as String).toList();
          if (labels != null) _customLabelsByAtelier[atelierId] = labels;
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('⚠️ sync champs de mesures ($atelierId) interrompue : $error');
        },
      ),
    );
  }

  /// Écrit le catalogue de l'atelier dans Firestore.
  ///
  /// Un échec est journalisé mais N'INTERROMPT PAS l'action : le champ reste
  /// utilisable pour la session en cours (la valeur est déjà dans la carte
  /// locale) et sera réécrit au prochain ajout/retrait. C'est volontaire —
  /// mieux vaut un champ de mesure exploitable tout de suite qu'un dialogue
  /// qui plante parce que le réseau est coupé, ou parce que la règle
  /// `measurementFields` n'a pas encore été déployée (voir firestore.rules).
  Future<void> _persist(String atelierId) async {
    if (!FirebaseService.isAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('measurementFields').doc(atelierId).set(
        {
          'labels': _customLabelsByAtelier[atelierId] ?? <String>[],
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('⚠️ champ de mesure non enregistré côté serveur (atelier $atelierId) : $error');
    }
  }

  /// Ajoute un nouveau champ de mesure pour l'atelier, s'il n'existe pas déjà
  /// (comparaison insensible à la casse pour éviter les doublons du type
  /// "Tour de bras" / "tour de bras").
  Future<void> addCustomField(String atelierId, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    final list = _customLabelsByAtelier.putIfAbsent(atelierId, () => []);
    final alreadyExists = list.any((l) => l.toLowerCase() == trimmed.toLowerCase());
    if (!alreadyExists) list.add(trimmed);

    await _persist(atelierId);
  }

  /// Retire ce champ du catalogue de l'atelier — il ne sera plus proposé
  /// pour les prochaines commandes/clients. N'efface PAS une valeur déjà
  /// enregistrée sous ce label sur un client existant (voir
  /// OrderService.updateClientMeasurements pour ça, action séparée et
  /// volontaire côté fiche client).
  Future<void> removeCustomField(String atelierId, String label) async {
    _customLabelsByAtelier[atelierId]?.removeWhere((l) => l.toLowerCase() == label.toLowerCase());
    await _persist(atelierId);
  }
}
