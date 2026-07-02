import '../data/admin_demo_data.dart';
import '../models/app_user.dart';
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

    final expectedPassword = _demoPasswords[user.email.toLowerCase()] ?? _defaultCreatedAccountPassword;
    if (expectedPassword != password) {
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
      SubscriptionService.instance.notifyExpiration(
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

    // Rend le nouveau compte visible côté Admin (liste des comptes stylistes) :
    // tout compte créé doit apparaître immédiatement dans l'espace Admin.
    AdminDemoData.addStylistAccount(user);

    _currentUser = user;
    return user;
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

  bool get isDemoMode => !FirebaseService.isAvailable;

  /// Évite de renvoyer plusieurs fois le même message système d'expiration
  /// pour un compte donné durant la session démo.
  static final Set<String> _expirationNotified = {};

  /// Mot de passe par défaut pour tout compte créé par un Chef d'Entreprise
  /// (Chef d'atelier ou Couturier) qui n'a pas encore changé son mot de
  /// passe initial. En production, ce serait un mot de passe temporaire
  /// envoyé par SMS/email avec obligation de le changer à la 1ère connexion.
  static const String _defaultCreatedAccountPassword = 'bienvenue123';

  static final Map<String, String> _demoPasswords = {
    'admin@styleconnect.ml': 'admin123',
    'styliste@demo.ml': 'demo123',
    'couturier@demo.ml': 'demo123',
    'entreprise@demo.ml': 'entreprise123',
  };

  static final List<AppUser> _demoUsers = [
    AppUser(
      id: 'admin_1',
      email: 'admin@styleconnect.ml',
      fullName: 'Admin StyleConnect',
      phone: '+223 70 00 00 01',
      role: UserRole.admin,
      createdAt: DateTime(2026, 1, 1),
    ),
    AppUser(
      id: 'stylist_1',
      email: 'styliste@demo.ml',
      fullName: 'Aminata Diallo',
      phone: '+223 76 12 34 56',
      role: UserRole.stylist,
      atelierId: 'atelier_1',
      atelierName: 'Atelier Élégance Bamako',
      plan: SubscriptionPlan.starter,
      planExpiresAt: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 3, 15),
    ),
    AppUser(
      id: 'tailor_1',
      email: 'couturier@demo.ml',
      fullName: 'Moussa Keita',
      phone: '+223 65 98 76 54',
      role: UserRole.tailor,
      atelierId: 'atelier_1',
      atelierName: 'Atelier Élégance Bamako',
      createdAt: DateTime(2026, 4, 1),
    ),
    AppUser(
      id: 'owner_1',
      email: 'entreprise@demo.ml',
      fullName: 'Moussa Keïta',
      phone: '+223 70 33 44 55',
      role: UserRole.companyOwner,
      atelierId: 'atelier_owner_1',
      atelierName: 'Keïta Prestige — Siège (Moussa Keïta)',
      companyId: 'owner_1',
      plan: SubscriptionPlan.enterprise,
      planExpiresAt: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 1, 5),
    ),
  ];
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
