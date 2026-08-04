import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/atelier.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_request.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';
import '../services/firebase_service.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// Store admin — MUTABLE pour que les actions (Approuver/Refuser/Renouveler)
// aient un effet réel et persistant sur les comptes durant la session. En
// mode Firebase, `_stylists` devient un CACHE tenu à jour par une écoute
// Firestore sur users where role in [stylist, companyOwner] — les mêmes
// getters synchrones ci-dessous continuent de fonctionner sans changement de
// signature pour les écrans admin.
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AdminDemoData {
  static final List<StylistEntry> _stylists = [];

  static bool _synced = false;
  static final Set<String> _syncedRequests = {};
  static final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = [];

  static void _ensureSynced() {
    if (!FirebaseService.isAvailable) return;
    if (_synced) return;
    _synced = true;

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['stylist', 'companyOwner'])
          .snapshots()
          .listen((snap) {
        final currentIds = snap.docs.map((d) => d.id).toSet();
        _stylists.removeWhere((s) => !currentIds.contains(s.user.id));

        for (final doc in snap.docs) {
          final user = AppUser.fromMap(doc.data(), doc.id);
          final index = _stylists.indexWhere((s) => s.user.id == user.id);
          if (index == -1) {
            _stylists.add(StylistEntry(user: user, isOnline: false));
          } else {
            _stylists[index] = _stylists[index].copyWith(user: user);
          }
          _ensureRequestSynced(user.id);
        }
      }),
    );
  }

  static void _ensureRequestSynced(String userId) {
    if (!_syncedRequests.add(userId)) return;

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('subscriptionRequests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snap) {
        final index = _stylists.indexWhere((s) => s.user.id == userId);
        if (index == -1) return;
        final doc = snap.docs.firstOrNull;
        _stylists[index] = _stylists[index].copyWith(
          subscriptionRequest: doc != null ? SubscriptionRequest.fromMap(doc.data(), doc.id) : null,
          clearRequest: doc == null,
        );
      }),
    );
  }

  /// Ajoute un styliste à la liste admin (utilisé par le flux d'inscription
  /// en mode démo — en mode Firebase, la liste se met à jour toute seule via
  /// l'écoute Firestore dès qu'un nouveau compte apparaît).
  static Future<void> addStylist(AppUser user) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final entry = StylistEntry(user: user, isOnline: false);
    _stylists.add(entry);
  }

  /// Crée une demande d'abonnement pour un styliste
  static Future<void> requestSubscription(String userId, SubscriptionPlan requestedPlan) async {
    if (FirebaseService.isAvailable) {
      final request = SubscriptionRequest(
        userId: userId,
        requestedPlan: requestedPlan,
        requestedAt: DateTime.now(),
      );
      await FirebaseFirestore.instance.collection('subscriptionRequests').add(request.toMap());
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];

    // Si une demande existe déjà, on la remplace
    final request = SubscriptionRequest(
      userId: userId,
      requestedPlan: requestedPlan,
      requestedAt: DateTime.now(),
    );

    _stylists[index] = entry.copyWith(subscriptionRequest: request);
  }

  /// Vue en lecture pour l'UI — utilisez les méthodes ci-dessous pour modifier.
  static List<StylistEntry> get stylists {
    _ensureSynced();
    return List.unmodifiable(_stylists);
  }

  /// Retrouve N'IMPORTE QUEL compte de la plateforme par son ID, qu'il
  /// s'agisse d'un compte "principal" (admin, styliste solo, chef
  /// d'entreprise) ou d'un compte créé par un chef d'entreprise (chef
  /// d'atelier, couturier). Utilisé par l'écran Messages admin pour afficher
  /// le contexte complet du compte à côté d'un signalement.
  static AppUser? findAnyUserById(String userId) =>
      AuthService.findById(userId) ??
      CompanyService.instance.findAccountById(userId) ??
      _stylists.where((s) => s.user.id == userId).firstOrNull?.user;

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
  static int get totalStylists {
    _ensureSynced();
    return _stylists.length;
  }

  static int get totalTailors =>
      stylists.fold(0, (sum, s) => sum + getStylistTailorCount(s.user));
  static int get activeOrders =>
      stylists.fold(0, (sum, s) => sum + getStylistOrderCount(s.user));
  static int get monthlyRevenue =>
      stylists.fold(0, (sum, s) => sum + getStylistRevenue(s.user));

  /// Abonnés PAYANTS actuellement actifs (plan payant + non expiré),
  /// groupés par plan. Le plan Découverte (gratuit) n'est jamais compté.
  /// Un compte dont l'abonnement a expiré retombe sur les droits Découverte
  /// (voir AppUser.permissions) : il n'est donc plus compté ici tant qu'il
  /// n'a pas renouvelé, même si son champ `plan` affiche encore l'ancien plan.
  static Map<SubscriptionPlan, int> get paidSubscribersByPlan {
    final counts = <SubscriptionPlan, int>{};
    for (final s in stylists) {
      final user = s.user;
      if (user.plan == SubscriptionPlan.free) continue;
      if (user.permissions.isExpired) continue;
      counts[user.plan] = (counts[user.plan] ?? 0) + 1;
    }
    return counts;
  }

  static int get paidSubscribersCount =>
      paidSubscribersByPlan.values.fold(0, (a, b) => a + b);

  /// Revenu d'ABONNEMENT mensuel de StyleConnect : somme du prix des plans
  /// payants actuellement actifs. À ne pas confondre avec `monthlyRevenue`,
  /// qui mesure le volume d'affaires des ateliers auprès de LEURS clients.
  static int get subscriptionRevenue =>
      paidSubscribersByPlan.entries.fold(0, (sum, e) => sum + e.key.price * e.value);

  static int get expiringIn7Days {
    final now = DateTime.now();
    final in7Days = now.add(const Duration(days: 7));
    return stylists.where((s) =>
      s.user.planExpiresAt != null &&
      s.user.planExpiresAt!.isAfter(now) &&
      s.user.planExpiresAt!.isBefore(in7Days)
    ).length;
  }

  static int get pendingRequests =>
      stylists.where((s) => s.subscriptionRequest != null && !s.subscriptionRequest!.approved).length;

  /// Liste de toutes les Entreprises (plan Entreprise) avec leurs ateliers —
  /// permet à l'Admin de visualiser la structure multi-ateliers de chaque compte.
  static List<Company> get companies => CompanyService.instance.allCompanies;

  // ── Actions admin réelles ────────────────────────────────────────────────

  /// Construit l'AppUser mis à jour pour un changement de plan, en gérant la
  /// promotion vers Chef d'Entreprise (role + companyId + création de la
  /// structure Company) quand le nouveau plan est Entreprise. Partagé par
  /// approveRequest, renewSubscription ET applyManualPlanChange pour que les
  /// trois chemins aient EXACTEMENT le même comportement de promotion.
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

    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'plan': updatedUser.plan.id,
        'planExpiresAt': updatedUser.planExpiresAt?.toIso8601String(),
        'role': updatedUser.role.name,
        'companyId': updatedUser.companyId,
      });
    } else {
      AuthService.updateUser(updatedUser);
      CompanyService.instance.updateUser(updatedUser);
    }
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
      requestDocId: request.id,
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
      requestDocId: request.id,
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
      applyPlanToAccount: (plan, expiresAt) async {
        final updatedUser = await _applyPlan(entry.user, plan, expiresAt);
        _stylists[index] = entry.copyWith(user: updatedUser);
      },
    );
  }

  /// Bascule actif/inactif un compte (suspension admin).
  static Future<void> toggleActive(String userId) async {
    final index = _stylists.indexWhere((s) => s.user.id == userId);
    if (index == -1) return;
    final entry = _stylists[index];
    final updatedUser = entry.user.copyWith(isActive: !entry.user.isActive);

    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': updatedUser.isActive,
      });
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

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
