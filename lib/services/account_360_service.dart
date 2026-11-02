import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../core/utils/formatters.dart';
import '../data/admin_demo_data.dart';
import '../models/admin_account.dart';
import '../models/app_user.dart';
import '../models/atelier.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/platform_health.dart';
import '../models/subscription_request.dart';
import '../models/support_message.dart';
import '../models/user_role.dart';
import 'admin_audit_service.dart';
import 'admin_notes_service.dart';
import 'company_service.dart';
import 'feature_usage_service.dart';
import 'firebase_service.dart';
import 'order_service.dart';
import 'subscription_payment_service.dart';
import 'support_message_service.dart';

class Account360Exception implements Exception {
  const Account360Exception(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Charge et agrège toutes les données d'un compte pour la fiche 360.
///
/// Les requêtes Firestore n'utilisent qu'un seul champ d'égalité à la fois,
/// puis les tris/filtres sont faits en Dart : aucun index composite n'est
/// nécessaire pour démarrer.
class Account360Service {
  Account360Service._();
  static final Account360Service instance = Account360Service._();

  static const _cacheDuration = Duration(seconds: 30);
  static const _usageWindowDays = 30;

  final Map<String, ({Account360Data data, DateTime at})> _cache = {};

  Future<Account360Data> load(String userId, {bool force = false}) async {
    final cached = _cache[userId];
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.at) < _cacheDuration) {
      return cached.data;
    }

    final data = FirebaseService.isAvailable
        ? await _loadFirebase(userId)
        : await _loadDemo(userId);

    _cache[userId] = (data: data, at: DateTime.now());
    return data;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Firebase
  // ───────────────────────────────────────────────────────────────────────────

  Future<Account360Data> _loadFirebase(String userId) async {
    final warnings = <String>[];
    final firestore = FirebaseFirestore.instance;

    final userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw const Account360Exception('Compte introuvable.');
    }
    final user = AppUser.fromMap(userDoc.data()!, userId);

    Company? company;
    final companyId = user.companyId ?? (user.role == UserRole.companyOwner ? user.id : null);
    if (companyId != null) {
      try {
        final doc = await firestore.collection('companies').doc(companyId).get();
        if (doc.exists) company = Company.fromMap(doc.data()!, companyId);
      } catch (error) {
        warnings.add('Entreprise illisible : $error');
      }
    }

    final ateliers = await _loadAteliers(user, warnings);
    final team = await _loadTeam(user, ateliers, warnings);
    final orders = await _loadOrders(user, ateliers, warnings);
    final clients = await _loadClients(ateliers, warnings);

    final supportMessages = await _loadSupport(userId, warnings);
    final usage = await _loadUsage(userId, warnings);
    final pendingRequests = await _loadPendingRequests(userId, warnings);
    final payments =
        await SubscriptionPaymentService.instance.paymentsFor(userId);
    final notes = await AdminNotesService.instance.notesFor(userId);
    final auditLogs = await AdminAuditService.instance.forTarget(userId);

    final duplicateEmailCount = await _countSameEmail(user, warnings);
    final qualityAlerts = _buildQuality(
      user: user,
      orders: orders,
      ateliers: ateliers,
      duplicateEmailCount: duplicateEmailCount,
    );

    return Account360Data(
      user: user,
      company: company,
      ateliers: ateliers,
      team: team,
      orders: orders,
      clients: clients,
      supportMessages: supportMessages,
      usage: usage,
      pendingRequests: pendingRequests,
      payments: payments,
      notes: notes,
      auditLogs: auditLogs,
      qualityAlerts: qualityAlerts,
      generatedAt: DateTime.now(),
      warnings: warnings,
    );
  }

  Future<List<Atelier>> _loadAteliers(
    AppUser user,
    List<String> warnings,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final result = <String, Atelier>{};

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      if (user.role == UserRole.companyOwner) {
        snapshot = await firestore
            .collection('ateliers')
            .where('companyId', isEqualTo: user.id)
            .limit(100)
            .get();
      } else if (user.role == UserRole.stylist) {
        snapshot = await firestore
            .collection('ateliers')
            .where('headStylistId', isEqualTo: user.id)
            .limit(100)
            .get();
      } else {
        snapshot = await firestore
            .collection('ateliers')
            .where('headStylistId', isEqualTo: user.id)
            .limit(100)
            .get();
      }

      for (final doc in snapshot.docs) {
        result[doc.id] = Atelier.fromMap(doc.data(), doc.id);
      }
    } catch (error) {
      warnings.add('Ateliers illisibles : $error');
    }

    if (user.atelierId != null && !result.containsKey(user.atelierId)) {
      try {
        final doc = await firestore
            .collection('ateliers')
            .doc(user.atelierId)
            .get();
        if (doc.exists) {
          result[doc.id] = Atelier.fromMap(doc.data()!, doc.id);
        }
      } catch (error) {
        warnings.add('Atelier principal illisible : $error');
      }
    }

    if (result.isEmpty && user.atelierId != null) {
      result[user.atelierId!] = Atelier(
        id: user.atelierId!,
        name: user.atelierName ?? 'Atelier',
        headStylistId: user.id,
        headStylistName: user.fullName,
        headStylistPhone: user.phone,
        companyId: user.companyId,
        createdAt: user.createdAt,
      );
    }

    return result.values.toList();
  }

  Future<List<AppUser>> _loadTeam(
    AppUser user,
    List<Atelier> ateliers,
    List<String> warnings,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final result = <String, AppUser>{};

    Future<void> fetch(Query<Map<String, dynamic>> query) async {
      try {
        final snapshot = await query.limit(200).get();
        for (final doc in snapshot.docs) {
          if (doc.id == user.id) continue;
          result[doc.id] = AppUser.fromMap(doc.data(), doc.id);
        }
      } catch (error) {
        warnings.add('Équipe illisible : $error');
      }
    }

    final companyId = user.companyId ?? (user.role == UserRole.companyOwner ? user.id : null);
    if (companyId != null) {
      await fetch(
        firestore.collection('users').where('companyId', isEqualTo: companyId),
      );
    }

    for (final atelier in ateliers) {
      await fetch(
        firestore.collection('users').where('atelierId', isEqualTo: atelier.id),
      );
    }

    return result.values.toList();
  }

  Future<List<Order>> _loadOrders(
    AppUser user,
    List<Atelier> ateliers,
    List<String> warnings,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final result = <String, Order>{};

    if (user.role == UserRole.tailor) {
      try {
        final snapshot = await firestore
            .collection('orders')
            .where('tailorId', isEqualTo: user.id)
            .limit(500)
            .get();
        for (final doc in snapshot.docs) {
          result[doc.id] = Order.fromMap(doc.data(), doc.id);
        }
      } catch (error) {
        warnings.add('Commandes illisibles : $error');
      }
    } else {
      for (final atelier in ateliers) {
        try {
          final snapshot = await firestore
              .collection('orders')
              .where('atelierId', isEqualTo: atelier.id)
              .limit(500)
              .get();
          for (final doc in snapshot.docs) {
            result[doc.id] = Order.fromMap(doc.data(), doc.id);
          }
        } catch (error) {
          warnings.add('Commandes de ${atelier.name} illisibles : $error');
        }
      }
    }

    final orders = result.values.toList();
    orders.sort((a, b) {
      final aDate = a.createdAt ??
          (a.statusHistory.isNotEmpty
              ? a.statusHistory.first.changedAt
              : DateTime.now());
      final bDate = b.createdAt ??
          (b.statusHistory.isNotEmpty
              ? b.statusHistory.first.changedAt
              : DateTime.now());
      return bDate.compareTo(aDate);
    });
    return orders;
  }

  Future<List<Client>> _loadClients(
    List<Atelier> ateliers,
    List<String> warnings,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final result = <String, Client>{};

    for (final atelier in ateliers) {
      try {
        final snapshot = await firestore
            .collection('clients')
            .where('atelierId', isEqualTo: atelier.id)
            .limit(500)
            .get();
        for (final doc in snapshot.docs) {
          result[doc.id] = Client.fromMap(doc.data(), doc.id);
        }
      } catch (error) {
        warnings.add('Clients de ${atelier.name} illisibles : $error');
      }
    }

    final clients = result.values.toList();
    clients.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return clients;
  }

  Future<List<SupportMessage>> _loadSupport(
    String userId,
    List<String> warnings,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('supportMessages')
          .where('senderId', isEqualTo: userId)
          .limit(100)
          .get();
      final messages = snapshot.docs
          .map((doc) => SupportMessage.fromMap(doc.data(), doc.id))
          .toList();
      messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return messages;
    } catch (error) {
      warnings.add('Messages support illisibles : $error');
      return const [];
    }
  }

  Future<List<FeatureUsageStat>> _loadUsage(
    String userId,
    List<String> warnings,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('featureEvents')
          .where('userId', isEqualTo: userId)
          .limit(1000)
          .get();
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        return FeatureUsageEvent(
          feature: data['feature'] as String? ?? 'inconnue',
          userId: data['userId'] as String?,
          createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
      return _aggregateUsage(events);
    } catch (error) {
      warnings.add('Télémétrie d\'usage illisible : $error');
      return _aggregateUsage(const []);
    }
  }

  Future<List<SubscriptionRequest>> _loadPendingRequests(
    String userId,
    List<String> warnings,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('subscriptionRequests')
          .where('userId', isEqualTo: userId)
          .limit(20)
          .get();
      final requests = <SubscriptionRequest>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';
        if (status == 'pending') {
          requests.add(SubscriptionRequest.fromMap(data, doc.id));
        }
      }
      requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return requests;
    } catch (error) {
      warnings.add('Demandes d\'abonnement illisibles : $error');
      return const [];
    }
  }

  Future<int> _countSameEmail(AppUser user, List<String> warnings) async {
    if (user.email.trim().isEmpty) return 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email.trim())
          .limit(5)
          .get();
      return snapshot.docs.length;
    } catch (error) {
      warnings.add('Vérification des doublons impossible : $error');
      return 1;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Démo
  // ───────────────────────────────────────────────────────────────────────────

  Future<Account360Data> _loadDemo(String userId) async {
    final user = AdminDemoData.findAnyUserById(userId);
    if (user == null) {
      throw const Account360Exception('Compte introuvable en mode démo.');
    }

    final ateliers = <Atelier>[];
    if (user.role == UserRole.companyOwner) {
      ateliers.addAll(CompanyService.instance.ateliersOfCompany(user.id));
    }
    if (ateliers.isEmpty && user.atelierId != null) {
      ateliers.add(
        Atelier(
          id: user.atelierId!,
          name: user.atelierName ?? 'Atelier',
          headStylistId: user.id,
          headStylistName: user.fullName,
          headStylistPhone: user.phone,
          companyId: user.companyId,
          createdAt: user.createdAt,
        ),
      );
    }

    final team = <String, AppUser>{};
    for (final atelier in ateliers) {
      for (final tailor in CompanyService.instance.tailorsOfAtelier(atelier.id)) {
        if (tailor.id != user.id) team[tailor.id] = tailor;
      }
    }
    for (final account in CompanyService.instance.allStaffAccounts) {
      if (account.id == user.id) continue;
      if (account.companyId == user.id ||
          ateliers.any((atelier) => atelier.id == account.atelierId)) {
        team[account.id] = account;
      }
    }

    final orders = <String, Order>{};
    if (user.role == UserRole.tailor) {
      for (final atelier in ateliers) {
        for (final order
            in OrderService.instance.ordersOfAtelier(atelier.id)) {
          if (order.tailorId == user.id) orders[order.id] = order;
        }
      }
    } else {
      for (final atelier in ateliers) {
        for (final order
            in OrderService.instance.ordersOfAtelier(atelier.id)) {
          orders[order.id] = order;
        }
      }
    }

    final clients = <String, Client>{};
    for (final atelier in ateliers) {
      for (final client in OrderService.instance.clientsOfAtelier(atelier.id)) {
        clients[client.id] = client;
      }
    }

    final orderList = orders.values.toList()
      ..sort((a, b) {
        final aDate = a.createdAt ??
            (a.statusHistory.isNotEmpty
                ? a.statusHistory.first.changedAt
                : DateTime.now());
        final bDate = b.createdAt ??
            (b.statusHistory.isNotEmpty
                ? b.statusHistory.first.changedAt
                : DateTime.now());
        return bDate.compareTo(aDate);
      });
    final clientList = clients.values.toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    final support = SupportMessageService.instance.messagesFrom(user.id);
    final usage = _aggregateUsage(FeatureUsageService.instance.localEvents);

    final entry =
        AdminDemoData.stylists.where((entry) => entry.user.id == user.id).firstOrNull;
    final pending = <SubscriptionRequest>[
      if (entry?.subscriptionRequest != null) entry!.subscriptionRequest!,
    ];

    final existing = await SubscriptionPaymentService.instance.paymentsFor(user.id);
    final notes = await AdminNotesService.instance.notesFor(user.id);
    final auditLogs = await AdminAuditService.instance.forTarget(user.id);

    final companyOwnerId =
        user.companyId ?? (user.role == UserRole.companyOwner ? user.id : null);

    return Account360Data(
      user: user,
      company: companyOwnerId == null
          ? null
          : CompanyService.instance.companyForOwner(companyOwnerId),
      ateliers: ateliers,
      team: team.values.toList(),
      orders: orderList,
      clients: clientList,
      supportMessages: support,
      usage: usage,
      pendingRequests: pending,
      payments: existing,
      notes: notes,
      auditLogs: auditLogs,
      qualityAlerts: _buildQuality(
        user: user,
        orders: orderList,
        ateliers: ateliers,
        duplicateEmailCount: 1,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Agrégations
  // ───────────────────────────────────────────────────────────────────────────

  List<FeatureUsageStat> _aggregateUsage(List<FeatureUsageEvent> events) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: _usageWindowDays));
    final recent = events.where((event) => event.createdAt.isAfter(cutoff));

    final byFeature = <String, List<FeatureUsageEvent>>{};
    for (final event in recent) {
      byFeature.putIfAbsent(event.feature, () => []).add(event);
    }

    final keys = <String>{...FeatureCatalog.all.keys, ...byFeature.keys};
    final stats = <FeatureUsageStat>[];
    for (final key in keys) {
      final featureEvents = byFeature[key] ?? const <FeatureUsageEvent>[];
      var last7 = 0;
      var previous7 = 0;
      DateTime? lastUsedAt;
      for (final event in featureEvents) {
        final age = now.difference(event.createdAt).inDays;
        if (age <= 7) {
          last7++;
        } else if (age <= 14) {
          previous7++;
        }
        if (lastUsedAt == null || event.createdAt.isAfter(lastUsedAt)) {
          lastUsedAt = event.createdAt;
        }
      }
      stats.add(
        FeatureUsageStat(
          feature: key,
          events: featureEvents.length,
          uniqueUsers: featureEvents.isEmpty ? 0 : 1,
          last7: last7,
          previous7: previous7,
          lastUsedAt: lastUsedAt,
        ),
      );
    }
    stats.sort((a, b) => b.events.compareTo(a.events));
    return stats;
  }

  List<AccountQualityAlert> _buildQuality({
    required AppUser user,
    required List<Order> orders,
    required List<Atelier> ateliers,
    required int duplicateEmailCount,
  }) {
    final alerts = <AccountQualityAlert>[];
    final now = DateTime.now();

    if (user.phone.trim().isEmpty) {
      alerts.add(
        const AccountQualityAlert(
          kind: AccountQualityKind.missingPhone,
          label: 'Téléphone manquant',
          detail: 'Impossible de relancer ce compte par WhatsApp ou SMS.',
          severity: 2,
        ),
      );
    }

    if (user.role != UserRole.admin && ateliers.isEmpty) {
      alerts.add(
        const AccountQualityAlert(
          kind: AccountQualityKind.missingAtelier,
          label: 'Aucun atelier rattaché',
          detail: 'Le compte ne peut pas être relié à une activité atelier.',
          severity: 2,
        ),
      );
    }

    if (duplicateEmailCount > 1) {
      alerts.add(
        AccountQualityAlert(
          kind: AccountQualityKind.duplicateEmail,
          label: 'Email en doublon',
          detail: '$duplicateEmailCount comptes utilisent ${user.email}.',
          severity: 3,
        ),
      );
    }

    if (user.role != UserRole.admin) {
      final lastActivity = user.lastLoginAt ?? user.createdAt;
      if (lastActivity != null) {
        final days = now.difference(lastActivity).inDays;
        if (days >= 30) {
          final kind = days >= 90
              ? AccountQualityKind.inactive90
              : (days >= 60
                  ? AccountQualityKind.inactive60
                  : AccountQualityKind.inactive30);
          alerts.add(
            AccountQualityAlert(
              kind: kind,
              label: 'Inactif depuis $days jours',
              detail: 'Dernière activité connue : '
                  '${lastActivity.day.toString().padLeft(2, '0')}/'
                  '${lastActivity.month.toString().padLeft(2, '0')}/'
                  '${lastActivity.year}',
              severity: days >= 90 ? 3 : 2,
            ),
          );
        }
      }
    }

    final dormant = orders.where((order) {
      if (order.status == OrderStatus.completed) return false;
      final last = order.statusHistory.isNotEmpty
          ? order.statusHistory.last.changedAt
          : order.createdAt;
      return last != null && now.difference(last).inDays >= 14;
    }).length;
    if (dormant > 0) {
      alerts.add(
        AccountQualityAlert(
          kind: AccountQualityKind.dormantOrder,
          label: '$dormant commande${dormant > 1 ? 's' : ''} sans activité',
          detail: 'Aucun changement de statut depuis plus de 14 jours.',
          severity: 2,
        ),
      );
    }

    final expiry = user.planExpiresAt;
    if (expiry != null) {
      // Jours calendaires : une échéance demain compte pour 1 jour, et un
      // abonnement expiré depuis quelques heures reste bien « expiré ».
      final days = Formatters.daysUntil(expiry, from: now);
      if (expiry.isBefore(now)) {
        alerts.add(
          AccountQualityAlert(
            kind: AccountQualityKind.expired,
            label: 'Abonnement expiré',
            detail: days == 0
                ? 'Échéance dépassée aujourd\'hui.'
                : 'Expiré depuis ${days.abs()} jours.',
            severity: 3,
          ),
        );
      } else if (days <= 7) {
        alerts.add(
          AccountQualityAlert(
            kind: AccountQualityKind.expiringSoon,
            label: days == 0 ? 'Expire aujourd\'hui' : 'Expire dans $days jours',
            detail: 'Une relance ou un renouvellement est recommandé.',
            severity: 2,
          ),
        );
      }
    }

    alerts.sort((a, b) => b.severity.compareTo(a.severity));
    return alerts;
  }
}
