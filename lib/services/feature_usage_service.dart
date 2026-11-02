import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import 'firebase_service.dart';

class FeatureUsageEvent {
  const FeatureUsageEvent({
    required this.feature,
    required this.createdAt,
    this.userId,
  });

  final String feature;
  final DateTime createdAt;
  final String? userId;

  Map<String, dynamic> toMap() => {
        'feature': feature,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': AppConstants.appVersion,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      };
}

/// Télémétrie produit minimale : un événement par usage réel d'une
/// fonctionnalité. Aucune donnée personnelle n'est envoyée (ni nom, ni email,
/// ni contenu de commande) — uniquement la clé de fonctionnalité et l'UID.
///
/// En mode démo, les événements restent en mémoire pour que la console puisse
/// afficher quelque chose sans Firebase.
class FeatureUsageService {
  FeatureUsageService._();
  static final FeatureUsageService instance = FeatureUsageService._();

  static const _maxLocalEvents = 500;
  static const _dedupeWindow = Duration(seconds: 20);
  static const _maxEventsPerSession = 300;

  final List<FeatureUsageEvent> _localEvents = [];
  final Map<String, DateTime> _lastTrackedAt = {};
  int _sessionWrites = 0;

  List<FeatureUsageEvent> get localEvents => List.unmodifiable(_localEvents);

  /// Enregistre un usage. Ne bloque jamais l'action métier : l'écriture
  /// Firestore est faite en arrière-plan et toute erreur est ignorée.
  void track(String feature, {bool dedupe = false}) {
    unawaited(_track(feature, dedupe: dedupe));
  }

  Future<void> _track(String feature, {required bool dedupe}) async {
    final now = DateTime.now();

    if (dedupe) {
      final last = _lastTrackedAt[feature];
      if (last != null && now.difference(last) < _dedupeWindow) return;
    }
    _lastTrackedAt[feature] = now;

    final uid = _currentUid();
    // En mode démo, on rattache l'événement à une session locale pour que
    // l'onglet Adoption affiche au moins un utilisateur identifié.
    final event = FeatureUsageEvent(
      feature: feature,
      createdAt: now,
      userId: uid ?? (FirebaseService.isAvailable ? null : 'demo_local'),
    );

    if (!FirebaseService.isAvailable || uid == null) {
      _addLocal(event);
      return;
    }

    if (_sessionWrites >= _maxEventsPerSession) return;
    _sessionWrites++;

    try {
      await FirebaseFirestore.instance
          .collection('featureEvents')
          .add(event.toMap());
    } catch (error) {
      debugPrint('⚠ télémétrie usage ignorée ($feature) : $error');
    }
  }

  String? _currentUid() {
    try {
      return fb_auth.FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  void _addLocal(FeatureUsageEvent event) {
    _localEvents.add(event);
    if (_localEvents.length > _maxLocalEvents) {
      _localEvents.removeRange(0, _localEvents.length - _maxLocalEvents);
    }
  }

  /// Utilisé par les tests et le mode démo pour repartir d'une base propre.
  void clearLocalEvents() => _localEvents.clear();
}
