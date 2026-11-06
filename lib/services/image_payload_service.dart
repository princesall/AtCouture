import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

/// Erreur destinée à l'utilisateur (message déjà rédigé en français).
///
/// Distincte d'une exception Firebase parce qu'elle doit remonter telle quelle
/// à l'écran : `friendlyFirebaseError` remplace tout message inconnu par
/// « Une erreur est survenue ».
class ImagePayloadException implements Exception {
  const ImagePayloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Stocke une image (logo d'atelier, photo de commande) et retourne la chaîne
/// à enregistrer dans Firestore.
///
/// Deux modes, choisis automatiquement :
///
/// 1. **Firebase Storage** (mode nominal) : le fichier est envoyé à
///    [storagePath] et l'URL de téléchargement est retournée.
/// 2. **Data-URL base64** (repli) : tant que le projet Firebase n'a pas de
///    bucket Storage — c'est le cas actuellement, faute de facturation — les
///    octets de l'image sont encodés en base64 et retournés sous la forme
///    `data:image/jpeg;base64,...`.
///
/// Le repli est **temporaire par construction** : il ne se déclenche que
/// lorsque Storage échoue. Une fois Blaze activé et les règles déployées, les
/// nouveaux envois repartent vers Storage sans modification de code, et les
/// images déjà en base64 continuent de s'afficher (voir `decodeDataUrl`).
class ImagePayloadService {
  ImagePayloadService._();

  /// Préfixe d'une image encodée en base64.
  static const String dataUrlMarker = 'data:';

  /// Longueur maximale d'une data-URL unique.
  ///
  /// Un document Firestore est plafonné à 1 Mio (1 048 576 octets) ; la
  /// chaîne base64 est de l'ASCII pur, donc sa longueur ≈ son poids en
  /// octets. On garde ~150 Ko de marge pour les autres champs du document.
  static const int maxDataUrlLength = 900000;

  /// Budget cumulé des photos d'une même commande, quand elles sont stockées
  /// en base64 dans le document `orders/{id}` (modelPhotos + fabricPhotos).
  ///
  /// Plus serré que [maxDataUrlLength] parce que le document d'une commande
  /// contient aussi les mesures, l'historique des statuts et l'acompte. À
  /// ~40–65 Ko la photo, cela laisse la place à une dizaine de photos, ce qui
  /// couvre les formules 1 et 3 photos et reste correct pour la formule
  /// 10 photos. Avec Storage (plan Blaze), cette limite disparaît : chaque
  /// photo vit dans son propre fichier.
  static const int maxOrderPhotosLength = 700000;

  /// `true` / `false` = dernier résultat connu de Firebase Storage,
  /// `null` = pas encore testé.
  ///
  /// Après un premier échec on cesse d'interroger Storage pour la session :
  /// cela évite de faire patienter l'utilisateur à chaque envoi alors que le
  /// bucket est absent. L'état n'est pas persisté, donc un redémarrage
  /// réessaie Storage — impossible de rester bloqué en base64 après
  /// l'activation de Blaze.
  static bool? _storageAvailable;

  /// Indique si [url] est une image encodée en base64 (repli sans Storage).
  static bool isDataUrl(String? url) =>
      url != null && url.startsWith(dataUrlMarker);

  /// Indique si les images sont actuellement stockées en base64.
  static bool get isUsingFallback => _storageAvailable == false;

  /// Envoie [file] vers [storagePath] (Firebase Storage) ou, si Storage est
  /// indisponible, l'encode en data-URL base64.
  ///
  /// En mode démo (Firebase indisponible), retourne le chemin local : les
  /// aperçus continuent de fonctionner pendant la session.
  static Future<String> store({
    required String storagePath,
    required XFile file,
  }) async {
    if (!FirebaseService.isAvailable) return file.path;

    if (_storageAvailable != false) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw const ImagePayloadException(
            "Le fichier image sélectionné est vide.",
          );
        }

        final ref = FirebaseStorage.instance.ref(storagePath);
        await ref.putData(
          bytes,
          SettableMetadata(
            contentType: contentTypeFor(file),
            // Le chemin ne change pas d'une modification à l'autre ; ce cache
            // court évite qu'une ancienne image reste affichée après un
            // remplacement, tout en limitant les téléchargements répétés.
            cacheControl: 'public, max-age=300',
          ),
        );
        final url = await ref.getDownloadURL();
        _storageAvailable = true;
        return url;
      } on ImagePayloadException {
        rethrow;
      } catch (e) {
        // Bucket absent, règles non déployées ou réseau coupé : on bascule sur
        // le repli base64 plutôt que d'échouer, pour que l'image soit quand
        // même enregistrée.
        _storageAvailable = false;
        debugPrint('⚠ Storage indisponible ($e) → repli sur une data-URL base64.');
      }
    }

    return toDataUrl(file);
  }

  /// Encode [file] en data-URL base64.
  static Future<String> toDataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImagePayloadException(
        "Le fichier image sélectionné est vide.",
      );
    }

    // Le base64 gonfle le volume d'environ un tiers : on estime avant
    // d'encoder pour produire un message d'erreur compréhensible.
    final estimatedLength = (bytes.length * 4) ~/ 3 + 64;
    if (estimatedLength > maxDataUrlLength) {
      final ko = (bytes.length / 1024).round();
      throw ImagePayloadException(
        "L'image choisie est trop lourde ($ko Ko) pour être enregistrée. "
        'Choisissez une image plus petite.',
      );
    }

    return '$dataUrlMarker${contentTypeFor(file)};base64,'
        '${base64Encode(bytes)}';
  }

  /// Supprime le fichier stocké à [storagePath], s'il existe.
  ///
  /// Best-effort : un fichier absent (compte créé avant l'arrivée de Storage,
  /// image stockée en base64, ou déjà supprimé) ne doit pas faire échouer
  /// l'appelant, dont l'objectif est seulement de vider le champ Firestore.
  static Future<void> delete(String storagePath) async {
    if (!FirebaseService.isAvailable) return;
    try {
      await FirebaseStorage.instance.ref(storagePath).delete();
    } catch (e) {
      debugPrint('⚠ Suppression impossible de $storagePath : $e');
    }
  }

  /// Cache des images base64 déjà décodées, indexé par la data-URL complète.
  ///
  /// Sans lui, `Image.memory` recevrait un nouveau `Uint8List` à chaque
  /// reconstruction : `MemoryImage` ne reconnaîtrait pas l'image comme déjà
  /// chargée et la redécoderait à chaque fois. On ne garde que les dernières
  /// entrées (un écran n'affiche qu'une poignée de photos à la fois).
  static final Map<String, Uint8List> _decodedCache = <String, Uint8List>{};
  static const int _decodedCacheLimit = 16;

  /// Décode une data-URL en octets prêts pour `Image.memory`, ou `null` si
  /// elle est illisible (l'appelant retombe alors sur son image de secours).
  static Uint8List? decodeDataUrl(String url) {
    final cached = _decodedCache[url];
    if (cached != null) return cached;

    final comma = url.indexOf(',');
    if (comma == -1 || comma + 1 >= url.length) return null;

    try {
      final bytes = base64Decode(url.substring(comma + 1));
      if (bytes.isEmpty) return null;
      if (_decodedCache.length >= _decodedCacheLimit) {
        _decodedCache.remove(_decodedCache.keys.first);
      }
      _decodedCache[url] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Réinitialise la mémoire du dernier échec Storage. Utile dans les tests et
  /// après un changement de projet Firebase.
  @visibleForTesting
  static void resetStorageAvailability() => _storageAvailable = null;

  static String contentTypeFor(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.startsWith('image/')) return mime;

    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
