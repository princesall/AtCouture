import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

/// Envoi / suppression du logo d'atelier (et plus généralement de la photo
/// de profil).
///
/// Pourquoi ce service existe : à l'inscription, l'ancien code enregistrait
/// directement `XFile.path` dans `users.photoUrl`. Ce chemin ne désigne un
/// fichier que sur l'appareil qui a choisi l'image — sur un autre téléphone,
/// après réinstallation ou sur le web, l'avatar retombait donc sur les
/// initiales, et il était impossible de le modifier ensuite. Le champ contient
/// désormais une valeur directement affichable partout.
///
/// Deux modes de stockage, choisis automatiquement :
///
/// 1. **Firebase Storage** (mode nominal) : le fichier est envoyé à
///    l'emplacement stable `profile_logos/{uid}/logo` et `users.photoUrl`
///    reçoit l'URL de téléchargement. Utilisé dès que le projet Firebase
///    dispose de Storage (plan Blaze + bucket créé).
/// 2. **Data-URL base64** (repli) : tant que le bucket n'existe pas — c'est le
///    cas actuellement, le projet n'a pas de facturation — l'image
///    redimensionnée est encodée en base64 et écrite telle quelle dans
///    `users.photoUrl`, sous la forme `data:image/jpeg;base64,...`. Firestore
///    accepte jusqu'à 1 Mio par document et un logo de 512 px pèse quelques
///    dizaines de Ko, donc cela tient très largement.
///
/// Le repli est **temporaire par construction** : il ne se déclenche que
/// lorsque Storage échoue. Le jour où Blaze est activé et les règles
/// déployées, les nouveaux logos repartent automatiquement vers Storage sans
/// aucune modification de code, et les anciens logos base64 continuent de
/// s'afficher (voir `_AvatarImage` dans common_widgets.dart).
class ProfileLogoService {
  ProfileLogoService._();

  /// Préfixe d'une image encodée en base64 dans `users.photoUrl`.
  static const String dataUrlMarker = 'data:';

  /// Longueur maximale de la data-URL écrite dans Firestore.
  ///
  /// Un document Firestore est plafonné à 1 Mio (1 048 576 octets) ; la
  /// chaîne base64 est de l'ASCII pur, donc sa longueur ≈ son poids en octets.
  /// On garde ~150 Ko de marge pour les autres champs du document (nom,
  /// email, téléphone, plan, atelier…).
  static const int maxDataUrlLength = 900000;

  /// `true` / `false` = dernier résultat connu de Firebase Storage,
  /// `null` = pas encore testé.
  ///
  /// Après un premier échec on cesse d'interroger Storage pour la session en
  /// cours : cela évite de faire patienter l'utilisateur à chaque envoi alors
  /// que le bucket est absent. L'état n'est pas persisté, donc un redémarrage
  /// de l'app réessaie Storage — impossible de rester bloqué en base64 après
  /// l'activation de Blaze.
  static bool? _storageAvailable;

  static Reference _reference(String userId) =>
      FirebaseStorage.instance.ref('profile_logos/$userId/logo');

  /// Indique si [url] est une image encodée en base64 (repli sans Storage).
  static bool isDataUrl(String? url) =>
      url != null && url.startsWith(dataUrlMarker);

  /// Envoie [file] et retourne ce qu'il faut enregistrer dans
  /// `users/{uid}.photoUrl` : une URL de téléchargement Storage, ou une
  /// data-URL base64 si Storage est indisponible.
  ///
  /// En mode démo (Firebase indisponible), retourne simplement le chemin
  /// local : l'aperçu fonctionne pendant la session.
  static Future<String> upload({
    required String userId,
    required XFile file,
  }) async {
    if (!FirebaseService.isAvailable) return file.path;

    if (_storageAvailable != false) {
      try {
        final url = await _uploadToStorage(userId, file);
        _storageAvailable = true;
        return url;
      } catch (e) {
        // Bucket absent, règles non déployées, réseau coupé : on bascule sur
        // le repli base64 plutôt que d'échouer, pour que le logo soit quand
        // même enregistré.
        _storageAvailable = false;
        debugPrint('⚠ Storage indisponible ($e) → repli sur une data-URL base64.');
      }
    }

    return _toDataUrl(file);
  }

  static Future<String> _uploadToStorage(String userId, XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('Le fichier image sélectionné est vide.');
    }

    final ref = _reference(userId);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeFor(file),
        // Le nom du fichier ne change pas d'une modification à l'autre ; ce
        // cache court évite qu'un ancien logo reste affiché après un
        // remplacement, tout en limitant les téléchargements répétés.
        cacheControl: 'public, max-age=300',
      ),
    );
    return ref.getDownloadURL();
  }

  /// Repli sans Storage : encode l'image en data-URL base64.
  static Future<String> _toDataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('Le fichier image sélectionné est vide.');
    }

    // Estimation avant encodage, pour un message d'erreur compréhensible :
    // le base64 gonfle le volume d'environ un tiers.
    final estimatedLength = (bytes.length * 4) ~/ 3 + 64;
    if (estimatedLength > maxDataUrlLength) {
      final ko = (bytes.length / 1024).round();
      throw StateError(
        "L'image choisie est trop lourde ($ko Ko) pour être enregistrée. "
        'Choisissez une image plus petite.',
      );
    }

    return '$dataUrlMarker${_contentTypeFor(file)};base64,'
        '${base64Encode(bytes)}';
  }

  /// Supprime le logo stocké. Best-effort : si le fichier n'existe pas (compte
  /// créé avant l'arrivée de Storage, logo stocké en base64, ou déjà
  /// supprimé), on ignore l'erreur — l'essentiel est que `users.photoUrl`
  /// soit remis à null.
  static Future<void> delete(String userId) async {
    if (!FirebaseService.isAvailable) return;
    if (_storageAvailable == false) return;
    try {
      await _reference(userId).delete();
    } catch (e) {
      debugPrint('⚠ Suppression du logo impossible pour $userId : $e');
    }
  }

  /// Réinitialise la mémoire du dernier échec Storage. Utile dans les tests et
  /// après un changement de projet Firebase.
  @visibleForTesting
  static void resetStorageAvailability() => _storageAvailable = null;

  static String _contentTypeFor(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.startsWith('image/')) return mime;

    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
