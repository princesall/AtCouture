import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';
import 'image_payload_service.dart';

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
/// Le stockage lui-même (Firebase Storage, ou data-URL base64 en repli quand
/// le projet n'a pas de bucket) est mutualisé dans [ImagePayloadService], pour
/// que le logo et les photos de commande ne divergent pas.
class ProfileLogoService {
  ProfileLogoService._();

  /// Préfixe d'une image encodée en base64 dans `users.photoUrl`.
  static const String dataUrlMarker = ImagePayloadService.dataUrlMarker;

  /// Longueur maximale de la data-URL écrite dans Firestore.
  static const int maxDataUrlLength = ImagePayloadService.maxDataUrlLength;

  /// Indique si [url] est une image encodée en base64 (repli sans Storage).
  static bool isDataUrl(String? url) => ImagePayloadService.isDataUrl(url);

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

    return ImagePayloadService.store(
      // Emplacement stable : un nouveau logo remplace l'ancien.
      storagePath: 'profile_logos/$userId/logo',
      file: file,
    );
  }

  /// Supprime le logo stocké. Best-effort : si le fichier n'existe pas (compte
  /// créé avant l'arrivée de Storage, logo stocké en base64, ou déjà
  /// supprimé), on ignore l'erreur — l'essentiel est que `users.photoUrl`
  /// soit remis à null.
  static Future<void> delete(String userId) async {
    if (!FirebaseService.isAvailable) return;
    // Rien à supprimer côté Storage si le repli base64 est actif : l'image
    // vit uniquement dans le document Firestore.
    if (ProfileLogoService._usingFallback) return;
    try {
      await ImagePayloadService.delete('profile_logos/$userId/logo');
    } catch (e) {
      debugPrint('⚠ Suppression du logo impossible pour $userId : $e');
    }
  }

  static bool get _usingFallback => ImagePayloadService.isUsingFallback;
}
