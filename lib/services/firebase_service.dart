import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initialise Firebase si configuré, sinon mode démo local.
class FirebaseService {
  static bool _initialized = false;
  static bool _available = false;

  static bool get isAvailable => _available;

  static Future<bool> initialize() async {
    if (_initialized) return _available;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Persistance hors-ligne : activée par défaut sur mobile, mais doit
      // être explicitement demandée sur Flutter Web (voir Settings.
      // persistenceEnabled) — sans quoi Firestore ne fonctionne pas du tout
      // en coupure réseau sur navigateur.
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      _available = true;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('✓ Firebase initialisé (projet ${DefaultFirebaseOptions.currentPlatform.projectId})');
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
