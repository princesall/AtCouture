import '../models/app_user.dart';
import '../models/atelier.dart';
import '../models/subscription_plan.dart';
import '../models/user_role.dart';
import '../services/company_service.dart';
import '../services/subscription_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modèle Styliste enrichi pour l'admin
// ─────────────────────────────────────────────────────────────────────────────

class StylistEntry {
  const StylistEntry({
    required this.user,
    required this.tailorCount,
    required this.orderCount,
    required this.totalRevenue,
    required this.isOnline,
    this.subscriptionRequest,
  });

  final AppUser user;
  final int tailorCount;
  final int orderCount;
  final int totalRevenue;
  final bool isOnline;
  final SubscriptionRequest? subscriptionRequest;

  StylistEntry copyWith({
    AppUser? user,
    int? tailorCount,
    int? orderCount,
    int? totalRevenue,
    bool? isOnline,
    SubscriptionRequest? subscriptionRequest,
    bool clearRequest = false,
  }) {
    return StylistEntry(
      user: user ?? this.user,
      tailorCount: tailorCount ?? this.tailorCount,
      orderCount: orderCount ?? this.orderCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      isOnline: isOnline ?? this.isOnline,
      subscriptionRequest: clearRequest ? null : (subscriptionRequest ?? this.subscriptionRequest),
    );
  }
}

class SubscriptionRequest {
  const SubscriptionRequest({
    required this.requestedPlan,
    required this.requestedAt,
    this.approved = false,
  });
  final SubscriptionPlan requestedPlan;
  final DateTime requestedAt;
  final bool approved;
}

class AdminMessage {
  const AdminMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.isReplied = false,
  });
  final String id;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final bool isReplied;
}

// ─────────────────────────────────────────────────────────────────────────────
// Store admin — MUTABLE pour que les actions (Approuver/Refuser/Renouveler)
// aient un effet réel et persistant sur les comptes durant la session.
// Quand Firebase sera branché, ce store sera remplacé par des écoutes
// Firestore en temps réel (StreamBuilder sur la collection `users`).
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AdminDemoData {
  static final List<StylistEntry> _stylists = [
    StylistEntry(
      user: AppUser(
        id: 'stylist_1',
        email: 'styliste@demo.ml',
        fullName: 'Aminata Diallo',
        phone: '+223 76 12 34 56',
        role: UserRole.stylist,
        atelierId: 'atelier_1',
        atelierName: 'Atelier Élégance Bamako',
        plan: SubscriptionPlan.starter,
        planExpiresAt: DateTime(2026, 12, 31),
        isActive: true,
        createdAt: DateTime(2026, 3, 15),
      ),
      tailorCount: 2,
      orderCount: 18,
      totalRevenue: 345000,
      isOnline: true,
      subscriptionRequest: SubscriptionRequest(
        requestedPlan: SubscriptionPlan.pro,
        requestedAt: DateTime(2026, 6, 27),
      ),
    ),
    StylistEntry(
      user: AppUser(
        id: 'stylist_2',
        email: 'ibrahim.toure@demo.ml',
        fullName: 'Ibrahim Touré',
        phone: '+223 65 98 76 54',
        role: UserRole.stylist,
        atelierId: 'atelier_2',
        atelierName: 'Maison Touré Couture',
        plan: SubscriptionPlan.starter,
        planExpiresAt: DateTime(2026, 7, 5),
        isActive: true,
        createdAt: DateTime(2026, 4, 1),
      ),
      tailorCount: 3,
      orderCount: 24,
      totalRevenue: 520000,
      isOnline: false,
      subscriptionRequest: SubscriptionRequest(
        requestedPlan: SubscriptionPlan.starter,
        requestedAt: DateTime(2026, 6, 26),
      ),
    ),
    StylistEntry(
      user: AppUser(
        id: 'stylist_3',
        email: 'fatoumata.coulibaly@demo.ml',
        fullName: 'Fatoumata Coulibaly',
        phone: '+223 78 45 12 63',
        role: UserRole.stylist,
        atelierId: 'atelier_3',
        atelierName: 'Coulibaly Fashion House',
        plan: SubscriptionPlan.pro,
        planExpiresAt: DateTime(2026, 9, 30),
        isActive: true,
        createdAt: DateTime(2026, 2, 10),
      ),
      tailorCount: 7,
      orderCount: 56,
      totalRevenue: 1250000,
      isOnline: true,
    ),
    StylistEntry(
      user: AppUser(
        id: 'stylist_4_legacy',
        email: 'legacy.keita@demo.ml',
        fullName: 'Compte Démo Legacy',
        phone: '+223 70 33 44 55',
        role: UserRole.stylist,
        atelierId: 'atelier_4',
        atelierName: 'Ancien Atelier',
        plan: SubscriptionPlan.pro,
        planExpiresAt: DateTime(2026, 12, 31),
        isActive: true,
        createdAt: DateTime(2026, 1, 5),
      ),
      tailorCount: 12,
      orderCount: 98,
      totalRevenue: 2780000,
      isOnline: true,
    ),
    StylistEntry(
      user: AppUser(
        id: 'stylist_5',
        email: 'aissata.bah@demo.ml',
        fullName: 'Aïssata Bah',
        phone: '+223 66 77 88 99',
        role: UserRole.stylist,
        atelierId: 'atelier_5',
        atelierName: 'Bah Couture',
        plan: SubscriptionPlan.free,
        isActive: false,
        createdAt: DateTime(2026, 5, 20),
      ),
      tailorCount: 0,
      orderCount: 3,
      totalRevenue: 45000,
      isOnline: false,
    ),
    StylistEntry(
      user: AppUser(
        id: 'stylist_6',
        email: 'kadiatou.diallo@demo.ml',
        fullName: 'Kadiatou Diallo',
        phone: '+223 79 12 56 78',
        role: UserRole.stylist,
        atelierId: 'atelier_6',
        atelierName: 'KD Style Bamako',
        plan: SubscriptionPlan.free,
        isActive: true,
        createdAt: DateTime(2026, 6, 10),
      ),
      tailorCount: 1,
      orderCount: 5,
      totalRevenue: 75000,
      isOnline: false,
    ),
  ];

  /// Vue en lecture pour l'UI — utilisez les méthodes ci-dessous pour modifier.
  static List<StylistEntry> get stylists => List.unmodifiable(_stylists);

  static final List<AdminMessage> messages = [
    AdminMessage(
      id: 'msg_1',
      senderName: 'Aminata Diallo',
      senderRole: 'Chef Styliste — Atelier Élégance',
      content: 'Bonjour, j\'aimerais passer au plan Pro. Pouvez-vous me confirmer comment procéder au paiement via Orange Money ?',
      sentAt: DateTime(2026, 6, 28, 14, 32),
      isRead: false,
    ),
    AdminMessage(
      id: 'msg_2',
      senderName: 'Ibrahim Touré',
      senderRole: 'Chef Styliste — Maison Touré',
      content: 'Mon abonnement Starter expire dans 10 jours. Je veux le renouveler. Quel est le numéro pour le paiement ?',
      sentAt: DateTime(2026, 6, 27, 9, 15),
      isRead: false,
    ),
    AdminMessage(
      id: 'msg_3',
      senderName: 'Moussa Keïta',
      senderRole: 'Chef d\'Entreprise — Groupe Keïta Couture',
      content: 'Est-ce qu\'il est possible d\'ajouter un 4ème atelier à notre compte Entreprise ? Nous ouvrons une nouvelle boutique à Kati.',
      sentAt: DateTime(2026, 6, 26, 16, 45),
      isRead: true,
      isReplied: true,
    ),
    AdminMessage(
      id: 'msg_4',
      senderName: 'Fatoumata Coulibaly',
      senderRole: 'Chef Styliste — Coulibaly Fashion',
      content: 'J\'ai un problème avec l\'upload des photos de mes modèles. La galerie ne se charge pas depuis hier.',
      sentAt: DateTime(2026, 6, 25, 11, 20),
      isRead: true,
    ),
    AdminMessage(
      id: 'msg_5',
      senderName: 'Kadiatou Diallo',
      senderRole: 'Chef Styliste — KD Style',
      content: 'Bonjour ! J\'ai commencé à utiliser l\'application. Comment puis-je inviter mon couturier à rejoindre mon espace ?',
      sentAt: DateTime(2026, 6, 24, 8, 5),
      isRead: true,
      isReplied: true,
    ),
  ];

  // KPIs globaux
  static const int totalStylists    = 127;
  static const int totalTailors     = 342;
  static const int activeOrders     = 89;
  static const int monthlyRevenue   = 4850000;
  static const int expiringIn7Days  = 5;

  static int get pendingRequests =>
      _stylists.where((s) => s.subscriptionRequest != null && !s.subscriptionRequest!.approved).length;

  static const int unreadMessages = 2;

  /// Liste de toutes les Entreprises (plan Entreprise) avec leurs ateliers —
  /// permet à l'Admin de visualiser la structure multi-ateliers de chaque compte.
  static List<Company> get companies => CompanyService.instance.allCompanies;

  // ── Actions admin réelles ────────────────────────────────────────────────

  /// Approuve la demande d'abonnement d'un styliste : modifie RÉELLEMENT son
  /// plan (+ date d'expiration à +30 jours), envoie le message système, et
  /// si le nouveau plan est Entreprise, fait apparaître ce compte dans la
  /// liste "Entreprises" de l'admin.
  static void approveRequest(String userId) {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final request = entry.subscriptionRequest;
    if (request == null) return;

    final newExpiry = DateTime.now().add(const Duration(days: 30));

    SubscriptionService.instance.approveSubscriptionRequest(
      userId: entry.user.id,
      userFullName: entry.user.fullName,
      requestedPlan: request.requestedPlan,
      newExpiryDate: newExpiry,
      applyPlanToAccount: (plan, expiresAt) {
        final updatedUser = entry.user.copyWith(plan: plan, planExpiresAt: expiresAt);
        _stylists[index] = entry.copyWith(user: updatedUser, clearRequest: true);
      },
    );
  }

  /// Refuse la demande : le plan reste inchangé, mais un message système
  /// explicite est envoyé au compte concerné.
  static void rejectRequest(String userId) {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final request = entry.subscriptionRequest;
    if (request == null) return;

    SubscriptionService.instance.rejectSubscriptionRequest(
      userId: entry.user.id,
      requestedPlan: request.requestedPlan,
    );

    _stylists[index] = entry.copyWith(clearRequest: true);
  }

  /// Renouvelle l'abonnement d'un compte (prolonge planExpiresAt), utilisé
  /// depuis l'onglet "Expirant" de la gestion des abonnements.
  static void renewSubscription(String userId, {int days = 365}) {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final newExpiry = DateTime.now().add(Duration(days: days));

    SubscriptionService.instance.renewSubscription(
      userId: entry.user.id,
      plan: entry.user.plan,
      newExpiryDate: newExpiry,
      applyPlanToAccount: (plan, expiresAt) {
        final updatedUser = entry.user.copyWith(plan: plan, planExpiresAt: expiresAt);
        _stylists[index] = entry.copyWith(user: updatedUser);
      },
    );
  }

  /// Bascule actif/inactif un compte (suspension admin).
  static void toggleActive(String userId) {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final updatedUser = entry.user.copyWith(isActive: !entry.user.isActive);
    _stylists[index] = entry.copyWith(user: updatedUser);
  }

  /// Changement de plan manuel par l'admin (hors workflow de demande),
  /// utilisé depuis la fiche détaillée d'un styliste. Applique réellement
  /// le nouveau plan + envoie un message système, comme pour une approbation.
  static void applyManualPlanChange(String userId, SubscriptionPlan newPlan) {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final newExpiry = DateTime.now().add(const Duration(days: 30));

    SubscriptionService.instance.approveSubscriptionRequest(
      userId: entry.user.id,
      userFullName: entry.user.fullName,
      requestedPlan: newPlan,
      newExpiryDate: newExpiry,
      applyPlanToAccount: (plan, expiresAt) {
        final updatedUser = entry.user.copyWith(plan: plan, planExpiresAt: expiresAt);
        _stylists[index] = entry.copyWith(user: updatedUser);
      },
    );
  }
}
