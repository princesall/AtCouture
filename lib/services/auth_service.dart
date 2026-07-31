import 'dart:math';

import '../models/app_user.dart';
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
class AuthService {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();

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

    // ── Vérification d'expiration à CHAQUE connexion ──────────────────────
    // Si le plan payant de ce compte a expiré depuis la dernière connexion,
    // on déclenche automatiquement la notification système une seule fois
    // (le calcul des droits réels, lui, est dynamique via user.permissions
    // et se recalcule à chaque accès, pas seulement à la connexion).
    final permissions = user.permissions;
    if (permissions.isExpired && !_expirationNotified.contains(user.id)) {
      await SubscriptionService.instance.notifyExpiration(
        userId: user.id,
        expiredPlan: permissions.originalPlan ?? user.plan,
      );
      _expirationNotified.add(user.id);
    }

    _currentUser = user;
    return user;
  }

  Future<AppUser> registerStylist({
    required String fullName,
    required String atelierName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final normalizedEmail = email.trim().toLowerCase();
    final exists = _demoUsers.any((u) => u.email.toLowerCase() == normalizedEmail) ||
        CompanyService.instance.findAccountByEmail(normalizedEmail) != null;
    if (exists) {
      throw AuthException('Un compte existe déjà avec cet email');
    }

    if (password.length < 6) {
      throw AuthException('Le mot de passe doit contenir au moins 6 caractères');
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

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();
    final expectedPassword = _demoPasswords[normalizedEmail];
    if (expectedPassword == null || expectedPassword != currentPassword) {
      throw AuthException('Mot de passe actuel incorrect');
    }

    if (newPassword.length < 6) {
      throw AuthException('Le nouveau mot de passe doit contenir au moins 6 caractères');
    }

    _demoPasswords[normalizedEmail] = newPassword;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();
    final exists = _demoUsers.any((u) => u.email.toLowerCase() == normalizedEmail) ||
        CompanyService.instance.findAccountByEmail(normalizedEmail) != null;
    if (!exists) {
      throw AuthException('Aucun compte trouvé avec cet email');
    }
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  /// Met à jour un utilisateur existant dans _demoUsers (utilisé par AdminDemoData)
  static void updateUser(AppUser updatedUser) {
    final index = _demoUsers.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _demoUsers[index] = updatedUser;
    }
  }

  /// Retrouve un compte "principal" (admin, styliste solo, chef d'entreprise)
  /// par son ID — ne couvre PAS les chefs d'atelier / couturiers créés par
  /// un chef d'entreprise, voir CompanyService.findAccountById pour ceux-là.
  static AppUser? findById(String userId) =>
      _demoUsers.where((u) => u.id == userId).firstOrNull;

  /// Récupère un utilisateur par son ID (utilisé par AuthProvider pour rafraîchir)
  AppUser? getUserById(String userId) {
    return _demoUsers.where((u) => u.id == userId).firstOrNull;
  }

  bool get isDemoMode => !FirebaseService.isAvailable;

  /// Évite de renvoyer plusieurs fois le même message système d'expiration
  /// pour un compte donné durant la session démo.
  static final Set<String> _expirationNotified = {};

  /// Génère un mot de passe temporaire unique et imprévisible pour un compte
  /// créé par un Chef d'Entreprise (Chef d'atelier ou Couturier), et
  /// l'enregistre immédiatement pour cet email. En production, ce mot de
  /// passe serait envoyé par SMS/email avec obligation de le changer à la
  /// 1ère connexion ; ici il est simplement affiché une fois à l'écran par
  /// l'appelant.
  static String generateTemporaryPassword(String email) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    final password = List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
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

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
