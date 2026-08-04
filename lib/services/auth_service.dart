import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;

import '../models/app_user.dart';
import '../models/atelier.dart';
import '../data/admin_demo_data.dart';
import '../models/subscription_plan.dart';
import '../models/user_role.dart';
import 'company_service.dart';
import 'firebase_service.dart';
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

    final doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
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
    var user = _demoUsers.where((u) => u.email.toLowerCase() == normalizedEmail).firstOrNull;

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

    _currentUser = user;
    return user;
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
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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

    _currentUser = user;
    return user;
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
        return 'Connexion impossible. Réessayez.';
    }
  }

  Future<AppUser> registerStylist({
    required String fullName,
    required String atelierName,
    required String email,
    required String phone,
    required String password,
    String? logoPath,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (password.length < 6) {
      throw AuthException('Le mot de passe doit contenir au moins 6 caractères');
    }

    if (FirebaseService.isAvailable) {
      return _registerStylistFirebase(
        fullName: fullName,
        atelierName: atelierName,
        email: normalizedEmail,
        phone: phone,
        password: password,
        logoPath: logoPath,
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final exists = _demoUsers.any((u) => u.email.toLowerCase() == normalizedEmail) ||
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
      photoUrl: logoPath,
      plan: SubscriptionPlan.free,
      createdAt: now,
    );

    _demoUsers.add(user);
    _demoPasswords[user.email] = password;
    // Mettre à jour la vue admin pour inclure ce styliste fraîchement créé
    await AdminDemoData.addStylist(user);
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
    String? logoPath,
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

    return _createStylistAccount(
      uid: credential.user!.uid,
      email: email,
      fullName: fullName,
      phone: phone,
      atelierName: atelierName,
      photoUrl: logoPath,
    );
  }

  /// Écrit users/{uid} + ateliers/{id} pour un nouveau compte styliste, une
  /// fois le compte Firebase Auth déjà créé (email/mot de passe OU Google —
  /// voir _registerStylistFirebase et completeGoogleSignUp). Partagé pour que
  /// les deux chemins d'inscription produisent EXACTEMENT la même structure
  /// de données.
  Future<AppUser> _createStylistAccount({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String atelierName,
    String? photoUrl,
  }) async {
    // Voir _signInFirebase : sans ce rafraîchissement, l'écriture Firestore
    // qui suit peut partir avant que le jeton ne soit attaché au SDK et se
    // faire rejeter par les règles (permission-denied) alors que le compte
    // Firebase Auth vient tout juste d'être créé avec succès.
    await fb_auth.FirebaseAuth.instance.currentUser?.getIdToken(true);

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
      photoUrl: photoUrl,
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
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await google.GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  /// Connexion/inscription via Google. Deux issues possibles :
  /// - [GoogleSignInExisting] : le compte existait déjà, connexion normale.
  /// - [GoogleSignInNeedsProfile] : première connexion, il manque encore le
  ///   nom d'atelier et le téléphone — l'appelant doit rediriger vers l'écran
  ///   de complétion puis appeler [completeGoogleSignUp].
  Future<GoogleSignInResult> signInWithGoogle() async {
    if (!FirebaseService.isAvailable) {
      throw AuthException('Connexion Google indisponible en mode démo.');
    }

    fb_auth.UserCredential credential;
    try {
      if (kIsWeb) {
        credential = await fb_auth.FirebaseAuth.instance
            .signInWithPopup(fb_auth.GoogleAuthProvider());
      } else {
        await _ensureGoogleSignInInitialized();
        late final google.GoogleSignInAccount account;
        try {
          account = await google.GoogleSignIn.instance.authenticate();
        } on google.GoogleSignInException catch (e) {
          if (e.code == google.GoogleSignInExceptionCode.canceled) {
            throw AuthException('Connexion annulée');
          }
          throw AuthException('Connexion Google impossible. Réessayez.');
        }
        final idToken = account.authentication.idToken;
        credential = await fb_auth.FirebaseAuth.instance.signInWithCredential(
          fb_auth.GoogleAuthProvider.credential(idToken: idToken),
        );
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_firebaseAuthErrorMessage(e));
    }

    await credential.user!.getIdToken(true);
    final uid = credential.user!.uid;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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

  /// Finalise un compte démarré via Google (voir [GoogleSignInNeedsProfile])
  /// une fois que le styliste a renseigné nom d'atelier + téléphone.
  Future<AppUser> completeGoogleSignUp({
    required String uid,
    required String email,
    required String fullName,
    required String atelierName,
    required String phone,
    String? photoUrl,
  }) {
    return _createStylistAccount(
      uid: uid,
      email: email,
      fullName: fullName,
      phone: phone,
      atelierName: atelierName,
      photoUrl: photoUrl,
    );
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
      throw AuthException('Le nouveau mot de passe doit contenir au moins 6 caractères');
    }

    if (FirebaseService.isAvailable) {
      return _changePasswordFirebase(currentPassword: currentPassword, newPassword: newPassword);
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

    await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).update({
      'mustChangePassword': false,
    });

    final updatedUser = _currentUser!.copyWith(mustChangePassword: false);
    _currentUser = updatedUser;
    return updatedUser;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (FirebaseService.isAvailable) {
      try {
        await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: normalizedEmail);
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          throw AuthException('Aucun compte trouvé avec cet email');
        }
        throw AuthException('Impossible d\'envoyer l\'email. Réessayez.');
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final exists = _demoUsers.any((u) => u.email.toLowerCase() == normalizedEmail) ||
        CompanyService.instance.findAccountByEmail(normalizedEmail) != null;
    if (!exists) {
      throw AuthException('Aucun compte trouvé avec cet email');
    }
  }

  Future<void> signOut() async {
    if (FirebaseService.isAvailable) {
      await fb_auth.FirebaseAuth.instance.signOut();
      _currentUser = null;
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
    final password = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    _demoPasswords[email.trim().toLowerCase()] = password;
    return password;
  }

  static final Map<String, String> _demoPasswords = {
    'admin@styleconnect.ml': 'admin123',
  };

  static final List<AppUser> _demoUsers = [
    // Uniquement l'admin pour les tests
    AppUser(
      id: 'admin_1',
      email: 'admin@styleconnect.ml',
      fullName: 'Admin StyleConnect',
      phone: '+223 70 00 00 01',
      role: UserRole.admin,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
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
