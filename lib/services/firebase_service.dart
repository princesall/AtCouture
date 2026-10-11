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
      // Journalisé AUSSI en release (et non plus seulement en debug) : c'est le
      // seul moyen de vérifier d'un coup d'œil, sur un appareil réel, que
      // l'application tourne bien sur Firebase et NON en mode démo. Sans ce
      // message, un APK release mal configuré (permission INTERNET absente,
      // google-services.json erroné...) se comportait comme un mode démo
      // silencieux, sans le moindre indice pour le diagnostic.
      debugPrint('✓ Firebase initialisé (projet ${DefaultFirebaseOptions.currentPlatform.projectId})');
    } catch (e) {
      _available = false;
      _initialized = true;
      debugPrint('⚠ MODE DÉMO — Firebase NON configuré, les données ne sont PAS persistées : $e');
    }

    return _available;
  }
}
