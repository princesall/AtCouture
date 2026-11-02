import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import 'app_user.dart';
import 'atelier.dart';
import 'client.dart';
import 'order.dart';
import 'order_status.dart';
import 'platform_health.dart';
import 'subscription_plan.dart';
import 'subscription_request.dart';
import 'support_message.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notes internes
// ─────────────────────────────────────────────────────────────────────────────

class AdminNote {
  const AdminNote({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  factory AdminNote.fromMap(Map<String, dynamic> map, String id) => AdminNote(
        id: id,
        text: map['text'] as String? ?? '',
        authorId: map['authorId'] as String? ?? '',
        authorName: map['authorName'] as String? ?? 'Admin',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Journal d'audit
// ─────────────────────────────────────────────────────────────────────────────

class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.targetName,
    this.details,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String targetType;
  final String targetId;
  final String? targetName;
  final String? details;
  final DateTime createdAt;

  factory AdminAuditLog.fromMap(Map<String, dynamic> map, String id) =>
      AdminAuditLog(
        id: id,
        actorId: map['actorId'] as String? ?? '',
        actorName: map['actorName'] as String? ?? 'Admin',
        action: map['action'] as String? ?? 'unknown',
        targetType: map['targetType'] as String? ?? 'user',
        targetId: map['targetId'] as String? ?? '',
        targetName: map['targetName'] as String?,
        details: map['details'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'targetName': targetName,
        'details': details,
        'createdAt': createdAt.toIso8601String(),
      };

  String get label => switch (action) {
        'subscription.approve' => 'Abonnement approuvé',
        'subscription.reject' => 'Demande d\'abonnement refusée',
        'subscription.renew' => 'Abonnement renouvelé',
        'subscription.plan_change' => 'Plan modifié',
        'account.suspend' => 'Compte suspendu',
        'account.reactivate' => 'Compte réactivé',
        'payment.record' => 'Paiement d\'abonnement enregistré',
        'note.add' => 'Note interne ajoutée',
        'note.delete' => 'Note interne supprimée',
        'support.preview' => 'Aperçu support ouvert',
        _ => action,
      };

  IconData get icon => switch (action) {
        'subscription.approve' => Icons.check_circle_rounded,
        'subscription.reject' => Icons.cancel_rounded,
        'subscription.renew' => Icons.autorenew_rounded,
        'subscription.plan_change' => Icons.workspace_premium_rounded,
        'account.suspend' => Icons.block_rounded,
        'account.reactivate' => Icons.lock_open_rounded,
        'payment.record' => Icons.payments_rounded,
        'note.add' || 'note.delete' => Icons.sticky_note_2_outlined,
        'support.preview' => Icons.visibility_rounded,
        _ => Icons.history_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Paiements d'abonnement
// ─────────────────────────────────────────────────────────────────────────────

enum SubscriptionPaymentMethod {
  orangeMoney('Orange Money'),
  moovMoney('Moov Money'),
  cash('Espèces'),
  bankTransfer('Virement bancaire');

  const SubscriptionPaymentMethod(this.label);
  final String label;

  static SubscriptionPaymentMethod parse(String? raw) =>
      SubscriptionPaymentMethod.values.firstWhere(
        (method) => method.name == raw,
        orElse: () => SubscriptionPaymentMethod.cash,
      );
}

class SubscriptionPayment {
  const SubscriptionPayment({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.plan,
    required this.amount,
    required this.method,
    required this.periodMonths,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
    this.reference,
    this.note,
    this.recordedById,
    this.recordedByName,
  });

  final String id;
  final String userId;
  final String userFullName;
  final SubscriptionPlan plan;
  final int amount;
  final SubscriptionPaymentMethod method;
  final int periodMonths;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;
  final String? reference;
  final String? note;
  final String? recordedById;
  final String? recordedByName;

  String get receiptNumber {
    final suffix = id.length > 6 ? id.substring(id.length - 6) : id;
    return 'SC-${createdAt.year}-${suffix.toUpperCase()}';
  }

  factory SubscriptionPayment.fromMap(Map<String, dynamic> map, String id) =>
      SubscriptionPayment(
        id: id,
        userId: map['userId'] as String? ?? '',
        userFullName: map['userFullName'] as String? ?? '',
        plan: SubscriptionPlan.values.firstWhere(
          (plan) => plan.id == map['planId'],
          orElse: () => SubscriptionPlan.free,
        ),
        amount: (map['amount'] as num?)?.toInt() ?? 0,
        method: SubscriptionPaymentMethod.parse(map['method'] as String?),
        periodMonths: (map['periodMonths'] as num?)?.toInt() ?? 1,
        periodStart: DateTime.tryParse(map['periodStart'] as String? ?? '') ??
            DateTime.now(),
        periodEnd: DateTime.tryParse(map['periodEnd'] as String? ?? '') ??
            DateTime.now(),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        reference: map['reference'] as String?,
        note: map['note'] as String?,
        recordedById: map['recordedById'] as String?,
        recordedByName: map['recordedByName'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userFullName': userFullName,
        'planId': plan.id,
        'amount': amount,
        'method': method.name,
        'periodMonths': periodMonths,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'reference': reference,
        'note': note,
        'recordedById': recordedById,
        'recordedByName': recordedByName,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Alertes de qualité propres à un compte
// ─────────────────────────────────────────────────────────────────────────────

enum AccountQualityKind {
  missingPhone,
  missingAtelier,
  duplicateEmail,
  inactive30,
  inactive60,
  inactive90,
  dormantOrder,
  expiringSoon,
  expired,
}

class AccountQualityAlert {
  const AccountQualityAlert({
    required this.kind,
    required this.label,
    this.detail,
    required this.severity,
  });

  final AccountQualityKind kind;
  final String label;
  final String? detail;

  /// 1 = information, 2 = à surveiller, 3 = critique.
  final int severity;

  IconData get icon => switch (kind) {
        AccountQualityKind.missingPhone => Icons.phone_disabled_rounded,
        AccountQualityKind.missingAtelier => Icons.store_mall_directory_outlined,
        AccountQualityKind.duplicateEmail => Icons.content_copy_rounded,
        AccountQualityKind.inactive30 ||
        AccountQualityKind.inactive60 ||
        AccountQualityKind.inactive90 =>
          Icons.schedule_rounded,
        AccountQualityKind.dormantOrder => Icons.receipt_long_outlined,
        AccountQualityKind.expiringSoon => Icons.hourglass_bottom_rounded,
        AccountQualityKind.expired => Icons.event_busy_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Chronologie
// ─────────────────────────────────────────────────────────────────────────────

enum AccountEventKind {
  accountCreated,
  login,
  subscriptionRequest,
  payment,
  order,
  support,
  note,
  audit,
}

class AccountTimelineEvent {
  const AccountTimelineEvent({
    required this.kind,
    required this.title,
    required this.date,
    this.subtitle,
    required this.icon,
  });

  final AccountEventKind kind;
  final String title;
  final String? subtitle;
  final DateTime date;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Fiche 360
// ─────────────────────────────────────────────────────────────────────────────

class Account360Data {
  const Account360Data({
    required this.user,
    required this.ateliers,
    required this.team,
    required this.orders,
    required this.clients,
    required this.supportMessages,
    required this.usage,
    required this.pendingRequests,
    required this.payments,
    required this.notes,
    required this.auditLogs,
    required this.qualityAlerts,
    required this.generatedAt,
    this.company,
    this.warnings = const [],
  });

  final AppUser user;
  final Company? company;
  final List<Atelier> ateliers;
  final List<AppUser> team;
  final List<Order> orders;
  final List<Client> clients;
  final List<SupportMessage> supportMessages;
  final List<FeatureUsageStat> usage;
  final List<SubscriptionRequest> pendingRequests;
  final List<SubscriptionPayment> payments;
  final List<AdminNote> notes;
  final List<AdminAuditLog> auditLogs;
  final List<AccountQualityAlert> qualityAlerts;
  final DateTime generatedAt;
  final List<String> warnings;

  int get totalRevenue =>
      orders.fold(0, (sum, order) => sum + (order.price ?? 0));

  int get cashCollected =>
      orders.fold(0, (sum, order) => sum + order.totalPaid);

  int get outstanding =>
      orders.fold(0, (sum, order) => sum + order.balanceDue);

  int get activeOrders =>
      orders.where((order) => order.status != OrderStatus.completed).length;

  int get subscriptionPaid =>
      payments.fold(0, (sum, payment) => sum + payment.amount);

  int get teamCount => team.length;

  int get clientCount => clients.length;

  int get usageEvents =>
      usage.fold(0, (sum, stat) => sum + stat.events);

  int? get daysBeforeExpiry {
    final expiry = user.planExpiresAt;
    if (expiry == null) return null;
    return Formatters.daysUntil(expiry);
  }

  SubscriptionPayment? get lastPayment {
    if (payments.isEmpty) return null;
    final sorted = [...payments]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  SubscriptionRequest? get pendingRequest =>
      pendingRequests.isEmpty ? null : pendingRequests.first;

  bool get hasExpired {
    final expiry = user.planExpiresAt;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  bool get expiringSoon {
    final days = daysBeforeExpiry;
    return days != null && days >= 0 && days <= 7 && !hasExpired;
  }

  List<AccountTimelineEvent> get timeline {
    final events = <AccountTimelineEvent>[];

    if (user.createdAt != null) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.accountCreated,
          title: 'Création du compte',
          subtitle: '${user.role.label} · ${user.atelierName ?? user.email}',
          date: user.createdAt!,
          icon: Icons.person_add_alt_1_rounded,
        ),
      );
    }

    if (user.lastLoginAt != null) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.login,
          title: 'Dernière connexion',
          date: user.lastLoginAt!,
          icon: Icons.login_rounded,
        ),
      );
    }

    for (final request in pendingRequests) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.subscriptionRequest,
          title: 'Demande de plan ${request.requestedPlan.name}',
          subtitle: 'En attente de décision',
          date: request.requestedAt,
          icon: Icons.workspace_premium_rounded,
        ),
      );
    }

    for (final payment in payments) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.payment,
          title:
              'Paiement de ${Formatters.formatCurrency(payment.amount)}',
          subtitle:
              '${payment.plan.name} · ${payment.periodMonths} mois · ${payment.method.label}',
          date: payment.createdAt,
          icon: Icons.payments_rounded,
        ),
      );
    }

    for (final note in notes.take(8)) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.note,
          title: 'Note interne',
          subtitle: note.text,
          date: note.createdAt,
          icon: Icons.sticky_note_2_outlined,
        ),
      );
    }

    for (final log in auditLogs) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.audit,
          title: log.label,
          subtitle: log.details ?? 'Par ${log.actorName}',
          date: log.createdAt,
          icon: log.icon,
        ),
      );
    }

    for (final order in orders.take(8)) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.order,
          title: 'Commande #${order.id}',
          subtitle:
              '${order.clientName} · ${order.status.label} · ${Formatters.formatCurrency(order.price ?? 0)}',
          date: order.createdAt ??
              (order.statusHistory.isNotEmpty
                  ? order.statusHistory.first.changedAt
                  : DateTime.now()),
          icon: Icons.receipt_long_rounded,
        ),
      );
    }

    for (final message in supportMessages.take(6)) {
      events.add(
        AccountTimelineEvent(
          kind: AccountEventKind.support,
          title: 'Message support',
          subtitle: message.content,
          date: message.sentAt,
          icon: Icons.forum_rounded,
        ),
      );
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events.take(40).toList();
  }
}
