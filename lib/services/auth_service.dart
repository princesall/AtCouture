import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:image_picker/image_picker.dart';

import '../core/constants/google_auth_config.dart';
import '../models/app_user.dart';
import '../models/atelier.dart';
import '../data/admin_demo_data.dart';
import '../models/subscription_plan.dart';
import '../models/platform_health.dart';
import '../models/user_role.dart';
import 'company_service.dart';
import 'feature_usage_service.dart';
import 'firebase_service.dart';
import 'platform_telemetry_service.dart';
import 'profile_logo_service.dart';
import 'subscription_service.dart';

/// Service d'authentification unique pour TOUS les types de comptes :
/// Admin, Chef d'Entreprise, Chef d'atelier (solo ou créé par une Entreprise),
/// Couturier. Une seule page de connexion ; c'est ce service qui retrouve
/// le bon compte et son rôle, puis le router (app_router.dart) dirige
/// automatiquement vers le bon espace selon `user.role`.
///
/// Chaque méthode se branche sur FirebaseService.isAvailable : si un projet
/// Firebase réel est connecté, elle utilise Firebase Auth + Firestore ; sinon
/// elle retombe sur la logique démo en mémoire (inchangée), qui reste un
/// vrai mode de secours utilisable (dev local, captures d'écran, tests).
class AuthService {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
  }

  /// Restaure la session au démarrage de l'app. En mode démo, il n'y a
  /// jamais de session persistée (comportement actuel inchangé) ; en mode
  /// Firebase, on relit la session Firebase Auth déjà ouverte sur l'appareil
  /// puis le document users/{uid} correspondant.
  Future<void> initialize() async {
    if (!FirebaseService.isAvailable) return;

    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(fbUser.uid)
        .get();
    if (doc.exists) {
      _currentUser = AppUser.fromMap(doc.data()!, fbUser.uid);
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (FirebaseService.isAvailable) {
      return _signInFirebase(normalizedEmail, password);
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));

    // 1. Cherche d'abord parmi les comptes "principaux" (admin, stylistes
    //    solo, companyOwner, inscriptions directes).
    var user = _demoUsers
        .where((u) => u.email.toLowerCase() == normalizedEmail)
        .firstOrNull;

    // 2. Si non trouvé, cherche parmi les comptes créés dynamiquement par un
    //    Chef d'Entreprise (Chefs d'atelier et Couturiers) — c'est cette
    //    recherche qui permet à TOUT compte créé par un chef de se connecter
    //    depuis la même page de connexion unique.
    user ??= CompanyService.instance.findAccountByEmail(normalizedEmail);

    if (user == null) {
      throw AuthException('Email ou mot de passe incorrect');
    }

    final expectedPassword = _demoPasswords[user.email.toLowerCase()];
    if (expectedPassword == null || expectedPassword != password) {
      throw AuthException('Email ou mot de passe incorrect');
    }

    if (!user.isActive) {
      throw AuthException('Ce compte a été suspendu');
    }

    await _checkExpirationAndNotify(user);

    // Trace la connexion pour les contrôles d'inactivité de l'admin. En mode
    // démo, on met aussi à jour les stores en mémoire pour que la console
    // voie immédiatement la nouvelle date.
    final signedInUser = user.copyWith(lastLoginAt: DateTime.now());
    final demoIndex = _demoUsers.indexWhere((u) => u.id == signedInUser.id);
    if (demoIndex != -1) _demoUsers[demoIndex] = signedInUser;
    CompanyService.instance.updateUser(signedInUser);

    _currentUser = signedInUser;
    return signedInUser;
  }

  Future<AppUser> _signInFirebase(String email, String password) async {
    fb_auth.UserCredential credential;
    try {
      credential = await fb_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_firebaseAuthErrorMessage(e));
    }

    // Force le rafraîchissement du jeton avant le premier appel Firestore :
    // sur Web, l'attachement du jeton au SDK Firestore après une connexion
    // se fait via un listener asynchrone, il peut ne pas être prêt si on
    // enchaîne une requête Firestore immédiatement — sans ça, la requête
    // partait parfois non authentifiée et se faisait rejeter par les règles.
    await credential.user!.getIdToken(true);

    final uid = credential.user!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) {
      await fb_auth.FirebaseAuth.instance.signOut();
      throw AuthException('Compte introuvable. Contactez le support.');
    }

    final user = AppUser.fromMap(doc.data()!, uid);
    if (!user.isActive) {
      await fb_auth.FirebaseAuth.instance.signOut();
      throw AuthException('Ce compte a été suspendu');
    }

    await _checkExpirationAndNotify(user);

    final signedInUser = user.copyWith(lastLoginAt: DateTime.now());

    // Écriture non bloquante : si les règles Firestore ne sont pas encore
    // déployées (ou en cas de coupure réseau), la connexion doit réussir
    // quand même. Le champ ne sert qu'au diagnostic admin.
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastLoginAt': signedInUser.lastLoginAt!.toIso8601String(),
      });
    } catch (_) {}

    _currentUser = signedInUser;
    return signedInUser;
  }

  /// Déclenche la notification système d'expiration une seule fois par
  /// session si le plan payant de ce compte a expiré depuis la dernière
  /// connexion (le calcul des droits réels, lui, est dynamique via
  /// user.permissions et se recalcule à chaque accès, pas seulement ici).
  Future<void> _checkExpirationAndNotify(AppUser user) async {
    final permissions = user.permissions;
    if (permissions.isExpired && !_expirationNotified.contains(user.id)) {
      await SubscriptionService.instance.notifyExpiration(
        userId: user.id,
        expiredPlan: permissions.originalPlan ?? user.plan,
      );
      _expirationNotified.add(user.id);
    }
  }

  String _firebaseAuthErrorMessage(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Email ou mot de passe incorrect';
      case 'user-disabled':
        return 'Ce compte a été suspendu';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      default:
        // Inclut le code brut : sans accès aux logs natifs (sideload iOS
        // notamment), c'est le seul moyen de diagnostiquer une erreur non
        // mappée ci-dessus (ex: app-not-authorized, internal-error,
        // sms-region-restriction côté Console Firebase).
        return 'Connexion impossible (${e.code}). Réessayez.';
    }
  }

  Future<AppUser> registerStylist({
    required String fullName,
    required String atelierName,
    required String email,
    required String phone,
    required String password,
    XFile? logoFile,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (password.length < 6) {
      throw AuthException(
        'Le mot de passe doit contenir au moins 6 caractères',
      );
    }

    if (FirebaseService.isAvailable) {
      final user = await _registerStylistFirebase(
        fullName: fullName,
        atelierName: atelierName,
        email: normalizedEmail,
        phone: phone,
        password: password,
        logoFile: logoFile,
      );
      FeatureUsageService.instance.track(FeatureKeys.authRegister);
      return user;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final exists =
        _demoUsers.any((u) => u.email.toLowerCase() == normalizedEmail) ||
        CompanyService.instance.findAccountByEmail(normalizedEmail) != null;
    if (exists) {
      throw AuthException('Un compte existe déjà avec cet email');
    }

    final now = DateTime.now();
    final user = AppUser(
      id: 'stylist_${now.millisecondsSinceEpoch}',
      email: normalizedEmail,
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.stylist,
      atelierId: 'atelier_${now.millisecondsSinceEpoch}',
      atelierName: atelierName.trim(),
      photoUrl: logoFile?.path,
      plan: SubscriptionPlan.free,
      createdAt: now,
    );

    _demoUsers.add(user);
    _demoPasswords[user.email] = password;
    // Mettre à jour la vue admin pour inclure ce styliste fraîchement créé
    await AdminDemoData.addStylist(user);
    FeatureUsageService.instance.track(FeatureKeys.authRegister);
    _currentUser = user;
    return user;
  }

  /// Crée le compte Firebase Auth du styliste ET, dans la même écriture
  /// atomique, son propre document ateliers/{id} — les règles Firestore
  /// (orders/clients) exigent qu'un atelier existe pour autoriser l'accès à
  /// ses commandes/clients, même pour un atelier solo (companyId absent).
  Future<AppUser> _registerStylistFirebase({
    required String fullName,
    required String atelierName,
    required String email,
    required String phone,
    required String password,
    XFile? logoFile,
  }) async {
    fb_auth.UserCredential credential;
    try {
      credential = await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthException('Un compte existe déjà avec cet email');
      }
      throw AuthException(_firebaseAuthErrorMessage(e));
    }

    try {
      return await _createStylistAccount(
        uid: credential.user!.uid,
        email: email,
        fullName: fullName,
        phone: phone,
        atelierName: atelierName,
        logoFile: logoFile,
      );
    } catch (_) {
      // Le compte Firebase Auth vient d'être créé mais son document
      // users/{uid} n'existe pas encore (upload du logo ou écriture Firestore
      // en échec). Sans ce nettoyage, la personne restait avec un compte
      // « fantôme » : la connexion suivante échouait sur « Compte
      // introuvable », sans aucun moyen de réessayer l'inscription avec le
      // même email.
      try {
        await credential.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Écrit users/{uid} + ateliers/{id} pour un nouveau compte styliste, une
  /// fois le compte Firebase Auth déjà créé (email/mot de passe OU Google —
  /// voir _registerStylistFirebase et completeGoogleSignUp). Partagé pour que
  /// les deux chemins d'inscription produisent EXACTEMENT la même structure
  /// de données.
  ///
  /// Le logo choisi à l'inscription est enregistré AVANT l'écriture du
  /// document (voir ProfileLogoService) : on stocke une URL téléchargeable
  /// (Firebase Storage) ou, si Storage est indisponible, l'image encodée en
  /// base64. Dans les deux cas, jamais le chemin local de l'appareil, sinon le
  /// logo n'apparaissait que sur le téléphone qui avait créé le compte.
  Future<AppUser> _createStylistAccount({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String atelierName,
    XFile? logoFile,
    String? photoUrl,
  }) async {
    // Voir _signInFirebase : sans ce rafraîchissement, l'écriture Firestore
    // qui suit peut partir avant que le jeton ne soit attaché au SDK et se
    // faire rejeter par les règles (permission-denied) alors que le compte
    // Firebase Auth vient tout juste d'être créé avec succès.
    await fb_auth.FirebaseAuth.instance.currentUser?.getIdToken(true);

    String? resolvedPhotoUrl = photoUrl;
    if (logoFile != null) {
      try {
        resolvedPhotoUrl = await ProfileLogoService.upload(
          userId: uid,
          file: logoFile,
        );
      } catch (e, stack) {
        PlatformTelemetryService.instance.recordError(
          e,
          stack,
          context: 'profile logo upload (inscription)',
        );
        throw AuthException(
          "Le logo n'a pas pu être envoyé. Vérifiez votre connexion puis réessayez.",
        );
      }
    }

    final now = DateTime.now();
    final atelierId = 'atelier_${now.millisecondsSinceEpoch}';

    final user = AppUser(
      id: uid,
      email: email,
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.stylist,
      atelierId: atelierId,
      atelierName: atelierName.trim(),
      photoUrl: resolvedPhotoUrl,
      plan: SubscriptionPlan.free,
      createdAt: now,
    );
    final atelier = Atelier(
      id: atelierId,
      name: atelierName.trim(),
      headStylistId: uid,
      headStylistName: fullName.trim(),
      createdAt: now,
    );

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    batch.set(firestore.collection('users').doc(uid), user.toMap());
    batch.set(firestore.collection('ateliers').doc(atelierId), atelier.toMap());
    await batch.commit();

    _currentUser = user;
    return user;
  }

  bool _googleSignInInitialized = false;

  /// `GoogleSignIn.initialize()` doit être appelé une seule fois avant tout
  /// autre appel — voir la doc du package. Sans effet sur Web (branche
  /// jamais utilisée là, voir signInWithGoogle).
  ///
  /// Les identifiants OAuth sont passés explicitement :
  /// - iOS : il n'y a pas de GoogleService-Info.plist dans le bundle (Firebase
  ///   est configuré via DefaultFirebaseOptions), donc sans `clientId` le SDK
  ///   Google ne peut pas construire sa configuration et `initialize()`
  ///   échouait (clientConfigurationError) avant même d'ouvrir la fenêtre.
  /// - Android/iOS : `serverClientId` (client OAuth « Web ») est indispensable
  ///   pour que Google renvoie un idToken dont l'audience est acceptée par
  ///   Firebase Auth ; sans lui `account.authentication.idToken` est null.
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await google.GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleAuthConfig.iosClientId
          : null,
      serverClientId: GoogleAuthConfig.webClientId,
    );
    _googleSignInInitialized = true;
  }

  /// Connexion/inscription via Google. Deux issues possibles :
  /// - [GoogleSignInExisting] : le compte existait déjà, connexion normale.
  /// - [GoogleSignInNeedsProfile] : première connexion, il manque encore le
  ///   nom d'atelier et le téléphone — l'appelant doit rediriger vers l'écran
  ///   de complétion puis appeler [completeGoogleSignUp].
  Future<GoogleSignInResult> signInWithGoogle() async {
    if (!FirebaseService.isAvailable) {
      throw AuthException(
        'Connexion Google indisponible : Firebase n\'a pas pu démarrer. '
        'Vérifiez votre connexion internet puis relancez l\'application.',
      );
    }

    final credential = await _googleFirebaseCredential();

    await credential.user!.getIdToken(true);
    final uid = credential.user!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      final user = AppUser.fromMap(doc.data()!, uid);
      if (!user.isActive) {
        await fb_auth.FirebaseAuth.instance.signOut();
        throw AuthException('Ce compte a été suspendu');
      }
      await _checkExpirationAndNotify(user);
      _currentUser = user;
      return GoogleSignInExisting(user);
    }

    return GoogleSignInNeedsProfile(
      uid: uid,
      email: credential.user!.email ?? '',
      fullName: credential.user!.displayName ?? '',
      photoUrl: credential.user!.photoURL,
    );
  }

  /// Obtient un credential Firebase Auth auprès de Google, en traduisant
  /// CHAQUE échec en message actionnable (et en le traçant pour l'admin).
  ///
  /// Auparavant, seul `authenticate()` était intercepté : une erreur de
  /// configuration — domaine non autorisé, `initialize()` en échec, idToken
  /// absent — remontait brute jusqu'au `catch (_)` de AuthProvider et
  /// s'affichait comme « Connexion Google impossible. Réessayez. », sans
  /// aucune indication de la vraie cause.
  Future<fb_auth.UserCredential> _googleFirebaseCredential() async {
    try {
      if (kIsWeb) {
        // Web : le SDK Firebase gère lui-même la fenêtre Google, le plugin
        // google_sign_in n'est pas utilisé (pas d'initialize() ici).
        return await fb_auth.FirebaseAuth.instance.signInWithPopup(
          fb_auth.GoogleAuthProvider(),
        );
      }

      await _ensureGoogleSignInInitialized();
      final account = await google.GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          'Google n\'a pas renvoyé de jeton d\'identité. Vérifiez le client '
          'OAuth « Web » du projet dans Firebase Console → Authentication → '
          'Google, puis réessayez.',
        );
      }
      return await fb_auth.FirebaseAuth.instance.signInWithCredential(
        fb_auth.GoogleAuthProvider.credential(idToken: idToken),
      );
    } on AuthException {
      rethrow;
    } on fb_auth.FirebaseAuthException catch (e) {
      _reportGoogleFailure(e);
      throw AuthException(_googleSignInErrorMessage(e));
    } on google.GoogleSignInException catch (e) {
      _reportGoogleFailure(e);
      throw AuthException(_googleSignInExceptionMessage(e));
    } on PlatformException catch (e) {
      _reportGoogleFailure(e);
      throw AuthException(
        'Connexion Google impossible (${e.code}). Réessayez.',
      );
    }
  }

  /// Trace l'échec côté télémétrie : sans cela, un refus de connexion Google
  /// en production (domaine, fournisseur désactivé, clé OAuth révoquée) ne
  /// laissait aucune trace exploitable côté admin.
  void _reportGoogleFailure(Object error) {
    debugPrint('⚠ Connexion Google refusée : $error');
    PlatformTelemetryService.instance.recordError(
      error,
      StackTrace.current,
      context: 'google sign-in',
    );
  }

  /// Message utilisateur pour un refus du SDK Firebase Auth (web notamment).
  /// Le code Firebase est conservé quand il n'est pas connu : c'est le seul
  /// moyen de diagnostiquer une configuration sans les logs natifs.
  String _googleSignInErrorMessage(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'unauthorized-domain':
        final host = kIsWeb ? Uri.base.host : '';
        final domaine = host.isEmpty ? 'ce domaine' : '« $host »';
        return 'Domaine $domaine non autorisé pour la connexion Google. '
            'Ajoutez-le dans Firebase Console → Authentication → Paramètres → '
            'Domaines autorisés.';
      case 'operation-not-allowed':
        return 'La connexion Google est désactivée. Activez-la dans Firebase '
            'Console → Authentication → Méthode de connexion → Google.';
      case 'popup-blocked':
        return 'La fenêtre Google a été bloquée par le navigateur. Autorisez '
            'les pop-ups pour ce site puis réessayez.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'user-cancelled':
        return 'Connexion annulée';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet email via une autre méthode de '
            'connexion. Connectez-vous avec votre mot de passe.';
      case 'network-request-failed':
        return 'Connexion impossible. Vérifiez votre réseau puis réessayez.';
      case 'web-storage-unsupported':
        return 'Votre navigateur bloque le stockage local nécessaire à la '
            'connexion Google (navigation privée ?).';
      default:
        return 'Connexion Google impossible (${e.code}). Réessayez.';
    }
  }

  /// Message utilisateur pour un échec du plugin natif google_sign_in.
  String _googleSignInExceptionMessage(google.GoogleSignInException e) {
    final details = e.description == null ? '' : ' (${e.description})';
    switch (e.code) {
      case google.GoogleSignInExceptionCode.canceled:
        return 'Connexion annulée';
      case google.GoogleSignInExceptionCode.interrupted:
        return 'Connexion interrompue. Réessayez.';
      case google.GoogleSignInExceptionCode.uiUnavailable:
        return 'Connexion Google impossible pour le moment. Réessayez.';
      case google.GoogleSignInExceptionCode.userMismatch:
        return 'Un autre compte Google est déjà connecté sur cet appareil. '
            'Déconnectez-le puis réessayez.';
      case google.GoogleSignInExceptionCode.clientConfigurationError:
      case google.GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In n\'est pas correctement configuré sur cette '
            'plateforme$details.';
      case google.GoogleSignInExceptionCode.unknownError:
        return 'Connexion Google impossible. Réessayez.';
    }
  }

  /// Finalise un compte démarré via Google (voir [GoogleSignInNeedsProfile])
  /// une fois que le styliste a renseigné nom d'atelier + téléphone.
  Future<AppUser> completeGoogleSignUp({
    required String uid,
    required String email,
    required String fullName,
    required String atelierName,
    required String phone,
    XFile? logoFile,
    String? photoUrl,
  }) {
    return _createStylistAccount(
      uid: uid,
      email: email,
      fullName: fullName,
      phone: phone,
      atelierName: atelierName,
      logoFile: logoFile,
      photoUrl: photoUrl,
    );
  }

  /// Ajoute / remplace / supprime le logo de l'atelier du compte connecté.
  ///
  /// [photoFile] null signifie « supprimer le logo ». L'image part vers
  /// Firebase Storage (URL de téléchargement) ou, si Storage est
  /// indisponible, y est encodée en base64, puis le résultat est écrit dans
  /// users/{uid}.photoUrl — un seul chemin d'écriture, partagé par le profil
  /// et l'inscription, pour éviter que le champ ne contienne parfois un chemin
  /// local et parfois une URL.
  Future<AppUser> updateProfilePhoto({
    required String userId,
    XFile? photoFile,
  }) async {
    final current = _currentUser;
    if (current == null || current.id != userId) {
      throw AuthException('Session expirée, reconnectez-vous.');
    }

    String? newPhotoUrl;
    if (photoFile != null) {
      try {
        newPhotoUrl = await ProfileLogoService.upload(
          userId: userId,
          file: photoFile,
        );
      } catch (e, stack) {
        PlatformTelemetryService.instance.recordError(
          e,
          stack,
          context: 'profile logo upload (profil)',
        );
        throw AuthException(
          "Le logo n'a pas pu être envoyé. Vérifiez votre connexion puis réessayez.",
        );
      }
    }

    if (FirebaseService.isAvailable) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'photoUrl': newPhotoUrl},
        );
      } catch (e, stack) {
        PlatformTelemetryService.instance.recordError(
          e,
          stack,
          context: 'profile logo firestore (profil)',
        );
        throw AuthException(
          "Impossible d'enregistrer le logo. Vérifiez votre connexion puis réessayez.",
        );
      }
    }

    final updated = current.copyWith(
      photoUrl: newPhotoUrl,
      clearPhotoUrl: newPhotoUrl == null,
    );
    _currentUser = updated;

    if (!FirebaseService.isAvailable) {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index != -1) _demoUsers[index] = updated;
      // Couvre les comptes créés par un Chef d'Entreprise, qui vivent dans
      // CompanyService plutôt que dans _demoUsers.
      CompanyService.instance.updateUser(updated);
    }

    if (newPhotoUrl == null) {
      await ProfileLogoService.delete(userId);
    }
    return updated;
  }

  /// Met à jour les informations de profil du compte connecté : nom complet,
  /// téléphone, nom et adresse de l'atelier.
  ///
  /// Le nom de l'atelier est volontairement écrit à DEUX endroits :
  /// `users/{uid}.atelierName` (copie dénormalisée, lue partout pour
  /// l'affichage — tableau de bord, commandes, profil) et
  /// `ateliers/{atelierId}.name` (source de vérité partagée avec les autres
  /// membres de l'atelier). Les deux sont écrites dans le MÊME batch : sans
  /// ça, le styliste verrait son nouveau nom dans son profil pendant que ses
  /// couturiers continueraient de voir l'ancien.
  ///
  /// L'email n'est pas modifiable ici : changer l'adresse de connexion exige
  /// une réauthentification et une vérification par email (voir
  /// FirebaseAuth.verifyBeforeUpdateEmail) ; une erreur en cours de route
  /// peut enfermer l'utilisateur hors de son compte. Traité séparément.
  Future<AppUser> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? atelierName,
    String? atelierAddress,
  }) async {
    final current = _currentUser;
    if (current == null || current.id != userId) {
      throw AuthException('Session expirée, reconnectez-vous.');
    }

    final newFullName = fullName?.trim();
    final newPhone = phone?.trim();
    final newAtelierName = atelierName?.trim();
    final newAddress = atelierAddress?.trim();

    if (newFullName != null) {
      if (newFullName.length < 2) {
        throw AuthException('Indiquez votre nom complet.');
      }
    }
    if (newPhone != null) {
      // Même règle que la création de client : au moins 8 chiffres, pour
      // éviter un numéro tronqué qui rendrait le contact WhatsApp inopérant.
      final digits = newPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 8) {
        throw AuthException(
          'Le numéro de téléphone doit contenir au moins 8 chiffres.',
        );
      }
    }
    if (newAtelierName != null && newAtelierName.isEmpty) {
      throw AuthException("Le nom de l'atelier ne peut pas être vide.");
    }

    final updated = current.copyWith(
      fullName: newFullName,
      phone: newPhone,
      atelierName: newAtelierName,
    );

    if (FirebaseService.isAvailable) {
      final firestore = FirebaseFirestore.instance;
      try {
        final batch = firestore.batch();
        batch.update(firestore.collection('users').doc(userId), {
          'fullName': updated.fullName,
          'phone': updated.phone,
          'atelierName': updated.atelierName,
        });

        // L'atelier n'existe pas pour tous les comptes (un Chef d'Entreprise
        // n'a pas forcément d'atelierId) : on ne l'écrit que s'il y en a un.
        final atelierId = current.atelierId;
        if (atelierId != null &&
            (newAtelierName != null || newAddress != null)) {
          batch.update(firestore.collection('ateliers').doc(atelierId), {
            'name': ?newAtelierName,
            'address': ?newAddress,
            // headStylistName n'est modifiable QUE par le Chef d'Entreprise
            // (voir firestore.rules : isAtelierHead n'a droit qu'à
            // name/address/tailorIds). L'écrire pour un simple chef d'atelier
            // ferait échouer TOUT le batch en permission-denied.
            if (current.isCompanyOwner) 'headStylistName': updated.fullName,
          });
        }

        await batch.commit();
      } catch (e, stack) {
        PlatformTelemetryService.instance.recordError(
          e,
          stack,
          context: 'profile update (profil)',
        );
        throw AuthException(
          "Impossible d'enregistrer vos informations. Vérifiez votre connexion puis réessayez.",
        );
      }
    } else {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index != -1) _demoUsers[index] = updated;
      // Couvre les comptes créés par un Chef d'Entreprise, qui vivent dans
      // CompanyService plutôt que dans _demoUsers.
      CompanyService.instance.updateUser(updated);
    }

    _currentUser = updated;
    return updated;
  }

  /// Change le mot de passe du compte connecté et, s'il s'agissait encore
  /// d'un mot de passe temporaire (voir CompanyService.createTailor /
  /// createAtelierHead), lève l'obligation de le changer — voir
  /// AppUser.mustChangePassword et AppRouter.redirect qui bloque tout accès
  /// tant que ce champ est true. Retourne l'utilisateur à jour pour que
  /// l'appelant (AuthProvider) rafraîchisse son état sans requête supplémentaire.
  Future<AppUser> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw AuthException(
        'Le nouveau mot de passe doit contenir au moins 6 caractères',
      );
    }

    if (FirebaseService.isAvailable) {
      return _changePasswordFirebase(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();
    final expectedPassword = _demoPasswords[normalizedEmail];
    if (expectedPassword == null || expectedPassword != currentPassword) {
      throw AuthException('Mot de passe actuel incorrect');
    }
    if (_currentUser == null) {
      throw AuthException('Session expirée, reconnectez-vous.');
    }

    _demoPasswords[normalizedEmail] = newPassword;

    final updatedUser = _currentUser!.copyWith(mustChangePassword: false);
    _currentUser = updatedUser;
    final demoIndex = _demoUsers.indexWhere((u) => u.id == updatedUser.id);
    if (demoIndex != -1) _demoUsers[demoIndex] = updatedUser;
    // Couvre les couturiers/chefs d'atelier créés dynamiquement, qui vivent
    // dans CompanyService plutôt que _demoUsers — no-op si l'id n'y est pas.
    CompanyService.instance.updateUser(updatedUser);

    return updatedUser;
  }

  Future<AppUser> _changePasswordFirebase({
    required String currentPassword,
    required String newPassword,
  }) async {
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null || fbUser.email == null || _currentUser == null) {
      throw AuthException('Session expirée, reconnectez-vous.');
    }
    try {
      final credential = fb_auth.EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(credential);
      await fbUser.updatePassword(newPassword);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AuthException('Mot de passe actuel incorrect');
      }
      throw AuthException('Impossible de changer le mot de passe. Réessayez.');
    }

    await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).update(
      {'mustChangePassword': false},
    );

    final updatedUser = _currentUser!.copyWith(mustChangePassword: false);
    _currentUser = updatedUser;
    return updatedUser;
  }

  /// Email de réinitialisation.
  ///
  /// IMPORTANT (diagnostic) : `sendPasswordResetEmail` peut très bien réussir
  /// sans qu'aucun email ne parte. Avec la protection contre l'énumération
  /// des comptes (activée par défaut sur les projets récents), Firebase
  /// renvoie un succès générique même quand l'adresse n'existe pas dans
  /// Authentication. On journalise donc le résultat et on traduit CHAQUE
  /// code d'erreur Firebase, au lieu d'un « Réessayez » qui masquait la
  /// vraie cause (domaine non autorisé, SMTP absent, quota atteint...).
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!_emailPattern.hasMatch(normalizedEmail)) {
      throw AuthException('Adresse email invalide');
    }

    if (FirebaseService.isAvailable) {
      final auth = fb_auth.FirebaseAuth.instance;
      // Les modèles d'email Firebase sont localisés : sans cela, un compte
      // francophone peut recevoir (ou filtrer) un email en anglais.
      auth.setLanguageCode('fr');
      try {
        await auth.sendPasswordResetEmail(email: normalizedEmail);
        // Visible dans la console (flutter run) ET dans les logs de release :
        // c'est le seul moyen de distinguer « Firebase a accepté » de
        // « l'email est réellement parti ».
        debugPrint(
          '✓ Réinitialisation acceptée par Firebase pour $normalizedEmail '
          '(si aucun email n\'arrive : spam, compte absent de Authentication, '
          'ou SMTP non configuré).',
        );
      } on fb_auth.FirebaseAuthException catch (e) {
        debugPrint(
          '⚠ Réinitialisation refusée pour $normalizedEmail : '
          '${e.code} — ${e.message}',
        );
        PlatformTelemetryService.instance.recordError(
          e,
          StackTrace.current,
          context: 'password reset',
        );
        throw AuthException(_passwordResetErrorMessage(e));
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final exists =
        _demoUsers.any((u) => u.email.toLowerCase() == normalizedEmail) ||
        CompanyService.instance.findAccountByEmail(normalizedEmail) != null;
    if (!exists) {
      throw AuthException('Aucun compte trouvé avec cet email');
    }
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Message actionnable pour l'admin/utilisateur, avec le code Firebase
  /// conservé quand il n'est pas connu : sans lui, impossible de diagnostiquer
  /// une configuration (SMTP, domaine, provider désactivé) côté console.
  static String _passwordResetErrorMessage(fb_auth.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Adresse email invalide.',
      'user-not-found' =>
        'Aucun compte Firebase Auth ne correspond à cet email. '
            'Vérifiez l\'adresse dans Authentication → Users.',
      'too-many-requests' =>
        'Trop de demandes en peu de temps. Réessayez dans quelques minutes.',
      'network-request-failed' =>
        'Connexion impossible. Vérifiez votre réseau puis réessayez.',
      'unauthorized-domain' || 'unauthorized-continue-uri' =>
        'Domaine non autorisé dans Firebase '
            '(Authentication → Settings → Authorized domains).',
      'operation-not-allowed' =>
        'La connexion par email/mot de passe est désactivée dans '
            'Firebase Authentication.',
      'internal-error' =>
        'Firebase n\'a pas pu envoyer l\'email. Vérifiez '
            'Authentication → Templates / SMTP.',
      _ => 'Impossible d\'envoyer l\'email (${e.code}).',
    };
  }

  Future<void> signOut() async {
    stopWatchingOwnUserDoc();

    if (FirebaseService.isAvailable) {
      await fb_auth.FirebaseAuth.instance.signOut();
      _currentUser = null;
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _ownUserSubscription;

  /// Surveille en continu le document Firestore du compte connecté et
  /// notifie l'appelant à CHAQUE changement, pas seulement isActive : un
  /// plan changé par l'admin pendant que la session est déjà ouverte doit
  /// débloquer les nouvelles fonctionnalités immédiatement, sans attendre une
  /// reconnexion — jusqu'ici seul AuthProvider.initialize() relisait ce
  /// document, une seule fois au démarrage du shell (StylistShell/
  /// CompanyShell/TailorShell), donc un upgrade approuvé en session restait
  /// invisible côté permissions malgré la notification système déjà reçue.
  /// Sert aussi à détecter une suspension en direct (c'est l'appelant qui
  /// vérifie updatedUser.isActive et décide de déconnecter, voir
  /// AuthProvider._watchOwnUser) — voir firestore.rules: isActiveUser(), qui
  /// coupe déjà l'accès aux données métier mais pas la session elle-même.
  void watchOwnUserDoc(void Function(AppUser user) onUpdate) {
    _ownUserSubscription?.cancel();
    final user = _currentUser;
    if (!FirebaseService.isAvailable || user == null) return;

    _ownUserSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .snapshots()
        .listen(
          (doc) {
            if (!doc.exists) return;
            onUpdate(AppUser.fromMap(doc.data()!, doc.id));
          },
          // Sans handler, une écoute refusée (règles Firestore, coupure réseau)
          // remontait en exception NON gérée et laissait l'application sur un état
          // périmé — un compte suspendu en direct ou un plan validé par l'admin
          // n'était alors jamais détecté, sans le moindre message.
          onError: (Object error, StackTrace stack) {
            PlatformTelemetryService.instance.recordError(
              error,
              stack,
              context: 'auth firestore',
            );
            debugPrint('⚠️ watchOwnUserDoc interrompu : $error');
          },
        );
  }

  void stopWatchingOwnUserDoc() {
    _ownUserSubscription?.cancel();
    _ownUserSubscription = null;
  }

  /// Met à jour un utilisateur existant dans _demoUsers (utilisé par AdminDemoData).
  /// Mode démo uniquement — AdminDemoData sera branché sur Firestore dans un
  /// prochain passage, les écritures admin passeront alors directement par
  /// FirebaseFirestore.instance.collection('users').doc(id).update(...).
  static void updateUser(AppUser updatedUser) {
    final index = _demoUsers.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _demoUsers[index] = updatedUser;
    }
  }

  /// Comptes créés en mémoire (mode démo uniquement). Utilisé par la console
  /// admin pour compter les utilisateurs sans Firebase.
  static List<AppUser> get demoUsers => List.unmodifiable(_demoUsers);

  /// Retrouve un compte "principal" (admin, styliste solo, chef d'entreprise)
  /// par son ID — ne couvre PAS les chefs d'atelier / couturiers créés par
  /// un chef d'entreprise, voir CompanyService.findAccountById pour ceux-là.
  /// Mode démo uniquement (liste en mémoire) ; AdminDemoData relit
  /// directement Firestore une fois branché.
  static AppUser? findById(String userId) =>
      _demoUsers.where((u) => u.id == userId).firstOrNull;

  /// Récupère un utilisateur par son ID (utilisé par AuthProvider.refreshUser
  /// pour rafraîchir le compte connecté après une action admin, ex:
  /// approbation d'abonnement). En mode Firebase, relit Firestore pour
  /// refléter les changements faits côté admin.
  Future<AppUser?> getUserById(String userId) async {
    if (FirebaseService.isAvailable) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      final user = AppUser.fromMap(doc.data()!, userId);
      if (_currentUser?.id == userId) _currentUser = user;
      return user;
    }
    return _demoUsers.where((u) => u.id == userId).firstOrNull;
  }

  bool get isDemoMode => !FirebaseService.isAvailable;

  /// Évite de renvoyer plusieurs fois le même message système d'expiration
  /// pour un compte donné durant la session.
  static final Set<String> _expirationNotified = {};

  /// Génère un mot de passe temporaire unique et imprévisible pour un compte
  /// créé par un Chef d'Entreprise (Chef d'atelier ou Couturier), et
  /// l'enregistre immédiatement pour cet email. En production, ce mot de
  /// passe serait envoyé par SMS/email avec obligation de le changer à la
  /// 1ère connexion ; ici il est simplement affiché une fois à l'écran par
  /// l'appelant. Mode démo uniquement — CompanyService gère la création des
  /// comptes Firebase Auth correspondants une fois branché.
  static String generateTemporaryPassword(String email) {
    // 8 caractères sur cet alphabet ~= 47 bits d'entropie : largement
    // suffisant pour un mot de passe à usage unique (voir
    // AppUser.mustChangePassword, forcé au premier login), tout en restant
    // facile à relire/retaper pour la personne qui le reçoit.
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    final password = List.generate(
      8,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    _demoPasswords[email.trim().toLowerCase()] = password;
    return password;
  }

  static final Map<String, String> _demoPasswords = {};

  static final List<AppUser> _demoUsers = [];

  /// Développement uniquement : injecte un compte admin de démonstration pour
  /// lancer `lib/main_admin.dart` sans projet Firebase.
  ///
  /// `kDebugMode` est une constante de compilation : en release, le corps de
  /// cette méthode et les identifiants qu'elle contient sont éliminés du
  /// binaire par le compilateur. Aucun mot de passe admin n'est donc livré
  /// dans l'application mobile ni dans la console déployée.
  static void seedDebugAdmin() {
    if (!kDebugMode) return;
    const email = 'admin@styleconnect.ml';
    if (_demoUsers.any((u) => u.email == email)) return;
    _demoUsers.add(
      AppUser(
        id: 'admin_debug',
        email: email,
        fullName: 'Admin StyleConnect',
        phone: '+223 70 00 00 01',
        role: UserRole.admin,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    _demoPasswords[email] = 'admin123';
  }
}

/// Résultat de AuthService.signInWithGoogle — voir GoogleSignInExisting et
/// GoogleSignInNeedsProfile.
sealed class GoogleSignInResult {}

/// Le compte existait déjà côté Firestore : connexion normale, déjà terminée.
class GoogleSignInExisting extends GoogleSignInResult {
  GoogleSignInExisting(this.user);
  final AppUser user;
}

/// Première connexion Google pour ce compte : le compte Firebase Auth existe
/// mais son document users/{uid} pas encore — il manque le nom d'atelier et
/// le téléphone (que Google ne fournit pas) avant de pouvoir le créer. voir
/// AuthService.completeGoogleSignUp.
class GoogleSignInNeedsProfile extends GoogleSignInResult {
  GoogleSignInNeedsProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
