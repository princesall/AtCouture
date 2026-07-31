import '../models/app_user.dart';
import '../models/atelier.dart';
import '../models/subscription_plan.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';
import '../services/order_service.dart';
import '../services/subscription_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modèle Styliste enrichi pour l'admin
// ─────────────────────────────────────────────────────────────────────────────

class StylistEntry {
  const StylistEntry({
    required this.user,
    required this.isOnline,
    this.subscriptionRequest,
  });

  final AppUser user;
  final bool isOnline;
  final SubscriptionRequest? subscriptionRequest;

  StylistEntry copyWith({
    AppUser? user,
    bool? isOnline,
    SubscriptionRequest? subscriptionRequest,
    bool clearRequest = false,
  }) {
    return StylistEntry(
      user: user ?? this.user,
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

// ─────────────────────────────────────────────────────────────────────────────
// Store admin — MUTABLE pour que les actions (Approuver/Refuser/Renouveler)
// aient un effet réel et persistant sur les comptes durant la session.
// Quand Firebase sera branché, ce store sera remplacé par des écoutes
// Firestore en temps réel (StreamBuilder sur la collection `users`).
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AdminDemoData {
  static final List<StylistEntry> _stylists = [];

  /// Ajoute un styliste à la liste admin (utilisé par le flux d'inscription)
  static Future<void> addStylist(AppUser user) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final entry = StylistEntry(user: user, isOnline: false);
    _stylists.add(entry);
  }

  /// Crée une demande d'abonnement pour un styliste
  static Future<void> requestSubscription(String userId, SubscriptionPlan requestedPlan) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];

    // Si une demande existe déjà, on la remplace
    final request = SubscriptionRequest(
      requestedPlan: requestedPlan,
      requestedAt: DateTime.now(),
      approved: false,
    );

    _stylists[index] = entry.copyWith(subscriptionRequest: request);
  }

  /// Vue en lecture pour l'UI — utilisez les méthodes ci-dessous pour modifier.
  static List<StylistEntry> get stylists => List.unmodifiable(_stylists);

  /// Retrouve N'IMPORTE QUEL compte de la plateforme par son ID, qu'il
  /// s'agisse d'un compte "principal" (admin, styliste solo, chef
  /// d'entreprise) ou d'un compte créé par un chef d'entreprise (chef
  /// d'atelier, couturier). Utilisé par l'écran Messages admin pour afficher
  /// le contexte complet du compte à côté d'un signalement.
  static AppUser? findAnyUserById(String userId) =>
      AuthService.findById(userId) ?? CompanyService.instance.findAccountById(userId);

  /// Un compte "Entreprise" (companyOwner) agrège l'activité de TOUS ses
  /// ateliers (via CompanyService.companyStats) ; un compte solo n'a que le
  /// sien (via son atelierId). Les helpers ci-dessous appliquent cette
  /// règle de façon cohérente pour un styliste donné.
  static ({int tailors, int orders, int clients, int revenue}) _statsFor(AppUser user) {
    final companyId = user.companyId;
    if (user.role == UserRole.companyOwner && companyId != null) {
      final stats = CompanyService.instance.companyStats(companyId);
      return (
        tailors: stats.totalTailors,
        orders: stats.totalOrders,
        clients: stats.totalClients,
        revenue: stats.totalRevenue,
      );
    }
    final atelierId = user.atelierId;
    if (atelierId == null) return (tailors: 0, orders: 0, clients: 0, revenue: 0);
    return (
      tailors: CompanyService.instance.tailorsOfAtelier(atelierId).length,
      orders: OrderService.instance.ordersOfAtelier(atelierId).length,
      clients: OrderService.instance.clientsOfAtelier(atelierId).length,
      revenue: OrderService.instance.atelierRevenue(atelierId),
    );
  }

  static int getStylistTailorCount(AppUser user) => _statsFor(user).tailors;
  static int getStylistOrderCount(AppUser user) => _statsFor(user).orders;
  static int getStylistClientCount(AppUser user) => _statsFor(user).clients;
  static int getStylistRevenue(AppUser user) => _statsFor(user).revenue;

  // KPIs globaux - Calculés dynamiquement à partir des vraies données de
  // TOUS les stylistes existants (jamais d'ID d'atelier codé en dur : les
  // ateliers/companyId réels sont générés à l'inscription/l'upgrade).
  static int get totalStylists => _stylists.length;
  static int get totalTailors =>
      _stylists.fold(0, (sum, s) => sum + getStylistTailorCount(s.user));
  static int get activeOrders =>
      _stylists.fold(0, (sum, s) => sum + getStylistOrderCount(s.user));
  static int get monthlyRevenue =>
      _stylists.fold(0, (sum, s) => sum + getStylistRevenue(s.user));

  static int get expiringIn7Days {
    final now = DateTime.now();
    final in7Days = now.add(const Duration(days: 7));
    return _stylists.where((s) =>
      s.user.planExpiresAt != null &&
      s.user.planExpiresAt!.isAfter(now) &&
      s.user.planExpiresAt!.isBefore(in7Days)
    ).length;
  }

  static int get pendingRequests =>
      _stylists.where((s) => s.subscriptionRequest != null && !s.subscriptionRequest!.approved).length;

  /// Liste de toutes les Entreprises (plan Entreprise) avec leurs ateliers —
  /// permet à l'Admin de visualiser la structure multi-ateliers de chaque compte.
  static List<Company> get companies => CompanyService.instance.allCompanies;

  // ── Actions admin réelles ────────────────────────────────────────────────

  /// Construit l'AppUser mis à jour pour un changement de plan, en gérant la
  /// promotion vers Chef d'Entreprise (role + companyId + création de la
  /// structure Company) quand le nouveau plan est Entreprise. Partagé par
  /// approveRequest ET applyManualPlanChange pour que les deux chemins aient
  /// EXACTEMENT le même comportement de promotion.
  static Future<AppUser> _applyPlan(AppUser user, SubscriptionPlan plan, DateTime expiresAt) async {
    final becomesEnterprise = plan == SubscriptionPlan.enterprise;
    final updatedUser = user.copyWith(
      plan: plan,
      planExpiresAt: expiresAt,
      role: becomesEnterprise ? UserRole.companyOwner : user.role,
      companyId: becomesEnterprise ? user.id : user.companyId,
    );

    if (becomesEnterprise && CompanyService.instance.companyForOwner(user.id) == null) {
      await CompanyService.instance.createCompanyForNewOwner(
        ownerId: user.id,
        ownerName: user.fullName,
        personalAtelierId: user.atelierId!,
        personalAtelierName: user.atelierName!,
      );
    }

    AuthService.updateUser(updatedUser);
    CompanyService.instance.updateUser(updatedUser);
    return updatedUser;
  }

  /// Approuve la demande d'abonnement d'un styliste : modifie RÉELLEMENT son
  /// plan (+ date d'expiration à +30 jours), envoie le message système, et
  /// si le nouveau plan est Entreprise, fait apparaître ce compte dans la
  /// liste "Entreprises" de l'admin.
  static Future<void> approveRequest(String userId) async {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final request = entry.subscriptionRequest;
    if (request == null) return;

    final newExpiry = DateTime.now().add(const Duration(days: 30));

    await SubscriptionService.instance.approveSubscriptionRequest(
      userId: entry.user.id,
      userFullName: entry.user.fullName,
      userAtelierId: entry.user.atelierId!,
      userAtelierName: entry.user.atelierName!,
      requestedPlan: request.requestedPlan,
      newExpiryDate: newExpiry,
      applyPlanToAccount: (plan, expiresAt) async {
        final updatedUser = await _applyPlan(entry.user, plan, expiresAt);
        _stylists[index] = entry.copyWith(user: updatedUser, clearRequest: true);
      },
    );
  }

  /// Refuse la demande : le plan reste inchangé, mais un message système
  /// explicite est envoyé au compte concerné.
  static Future<void> rejectRequest(String userId) async {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final request = entry.subscriptionRequest;
    if (request == null) return;

    await SubscriptionService.instance.rejectSubscriptionRequest(
      userId: entry.user.id,
      requestedPlan: request.requestedPlan,
    );

    _stylists[index] = entry.copyWith(clearRequest: true);
  }

  /// Renouvelle l'abonnement d'un compte (prolonge planExpiresAt), utilisé
  /// depuis l'onglet "Expirant" de la gestion des abonnements.
  static Future<void> renewSubscription(String userId, {int days = 365}) async {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final newExpiry = DateTime.now().add(Duration(days: days));

    await SubscriptionService.instance.renewSubscription(
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
  static Future<void> toggleActive(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final updatedUser = entry.user.copyWith(isActive: !entry.user.isActive);
    _stylists[index] = entry.copyWith(user: updatedUser);
  }

  /// Changement de plan manuel par l'admin (hors workflow de demande),
  /// utilisé depuis la fiche détaillée d'un styliste. Applique réellement
  /// le nouveau plan + envoie un message système, comme pour une approbation.
  static Future<void> applyManualPlanChange(String userId, SubscriptionPlan newPlan) async {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final newExpiry = DateTime.now().add(const Duration(days: 30));

    await SubscriptionService.instance.approveSubscriptionRequest(
      userId: entry.user.id,
      userFullName: entry.user.fullName,
      userAtelierId: entry.user.atelierId!,
      userAtelierName: entry.user.atelierName!,
      requestedPlan: newPlan,
      newExpiryDate: newExpiry,
      applyPlanToAccount: (plan, expiresAt) async {
        final updatedUser = await _applyPlan(entry.user, plan, expiresAt);
        _stylists[index] = entry.copyWith(user: updatedUser);
      },
    );
  }
}
