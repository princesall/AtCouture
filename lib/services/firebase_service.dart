import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initialise Firebase si configuré, sinon mode démo local.
class FirebaseService {
  static bool _initialized = false;
  static bool _available = false;

  static bool get isAvailable => _available;

  static Future<bool> initialize() async {
    if (_initialized) return _available;

    // Firebase Web nécessite firebase_options.dart — ignoré en mode démo.
    if (kIsWeb) {
      _available = false;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('⚠ Mode démo Web — Firebase non configuré');
      }
      return false;
    }

    // Aucun GoogleService-Info.plist n'est fourni pour l'instant. Sur iOS,
    // contrairement à Android, Firebase.initializeApp() sans ce fichier fait
    // planter l'app nativement au lancement au lieu de lever une exception
    // Dart récupérable par le catch ci-dessous. À retirer une fois un vrai
    // projet Firebase configuré pour iOS.
    if (Platform.isIOS) {
      _available = false;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('⚠ Mode démo iOS — Firebase non configuré');
      }
      return false;
    }

    try {
      await Firebase.initializeApp();
      _available = true;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('✓ Firebase initialisé');
      }
    } catch (e) {
      _available = false;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('⚠ Mode démo — Firebase non configuré: $e');
      }
    }

    return _available;
  }
}
