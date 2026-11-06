import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

/// Envoi / suppression du logo d'atelier (et plus généralement de la photo
/// de profil) dans Firebase Storage.
///
/// Pourquoi ce service existe : à l'inscription, l'ancien code enregistrait
/// directement `XFile.path` dans `users.photoUrl`. Ce chemin ne désigne un
/// fichier que sur l'appareil qui a choisi l'image — sur un autre téléphone,
/// après réinstallation ou sur le web, l'avatar retombait donc sur les
/// initiales, et il était impossible de le modifier ensuite. On stocke
/// désormais une vraie URL téléchargeable, à un emplacement stable
/// (`profile_logos/{uid}/logo`) pour qu'un nouveau logo remplace l'ancien.
class ProfileLogoService {
  ProfileLogoService._();

  static Reference _reference(String userId) =>
      FirebaseStorage.instance.ref('profile_logos/$userId/logo');

  /// Envoie [file] et retourne l'URL publique à enregistrer dans
  /// `users/{uid}.photoUrl`. En mode démo (Firebase indisponible), retourne
  /// simplement le chemin local : l'aperçu fonctionne pendant la session.
  static Future<String> upload({
    required String userId,
    required XFile file,
  }) async {
    if (!FirebaseService.isAvailable) return file.path;

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

  /// Supprime le logo stocké. Best-effort : si le fichier n'existe pas (compte
  /// créé avant l'arrivée de Storage, ou déjà supprimé), on ignore l'erreur —
  /// l'essentiel est que `users.photoUrl` soit remis à null.
  static Future<void> delete(String userId) async {
    if (!FirebaseService.isAvailable) return;
    try {
      await _reference(userId).delete();
    } catch (e) {
      debugPrint('⚠ Suppression du logo impossible pour $userId : $e');
    }
  }

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
