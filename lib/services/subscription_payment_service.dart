import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../core/utils/subscription_periods.dart';
import '../data/admin_demo_data.dart';
import '../models/admin_account.dart';
import '../models/app_user.dart';
import '../models/subscription_plan.dart';
import 'admin_audit_service.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'subscription_service.dart';

class SubscriptionPaymentException implements Exception {
  const SubscriptionPaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Enregistre les paiements d'abonnement et prolonge réellement le compte.
///
/// Un paiement n'est pas un simple reçu : il calcule la période couverte,
/// met à jour `planExpiresAt` (et le plan si nécessaire), envoie une
/// notification au compte, puis écrit une ligne d'audit.
class SubscriptionPaymentService {
  SubscriptionPaymentService._();
  static final SubscriptionPaymentService instance =
      SubscriptionPaymentService._();

  static const _collection = 'subscriptionPayments';
  static const _maxLocal = 300;

  final List<SubscriptionPayment> _localPayments = [];

  Future<SubscriptionPayment> recordPayment({
    required AppUser user,
    required SubscriptionPlan plan,
    required int amount,
    required SubscriptionPaymentMethod method,
    required int periodMonths,
    String? reference,
    String? note,
  }) async {
    if (amount <= 0) {
      throw const SubscriptionPaymentException(
        'Le montant doit être supérieur à zéro.',
      );
    }
    if (periodMonths <= 0 || periodMonths > 24) {
      throw const SubscriptionPaymentException(
        'La période doit être comprise entre 1 et 24 mois.',
      );
    }

    final now = DateTime.now();
    final currentExpiry = user.planExpiresAt;
    final periodStart =
        currentExpiry != null && currentExpiry.isAfter(now) ? currentExpiry : now;
    final periodEnd = SubscriptionPeriods.addMonths(periodStart, periodMonths);
    final actor = await _actor();

    final payment = SubscriptionPayment(
      id: 'pay_${now.microsecondsSinceEpoch}',
      userId: user.id,
      userFullName: user.fullName,
      plan: plan,
      amount: amount,
      method: method,
      periodMonths: periodMonths,
      periodStart: periodStart,
      periodEnd: periodEnd,
      createdAt: now,
      reference: _clean(reference),
      note: _clean(note),
      recordedById: actor.id,
      recordedByName: actor.name,
    );

    DocumentReference<Map<String, dynamic>>? firebaseRef;
    SubscriptionPayment saved = payment;

    if (FirebaseService.isAvailable) {
      firebaseRef = FirebaseFirestore.instance.collection(_collection).doc();
      saved = SubscriptionPayment(
        id: firebaseRef.id,
        userId: payment.userId,
        userFullName: payment.userFullName,
        plan: payment.plan,
        amount: payment.amount,
        method: payment.method,
        periodMonths: payment.periodMonths,
        periodStart: payment.periodStart,
        periodEnd: payment.periodEnd,
        createdAt: payment.createdAt,
        reference: payment.reference,
        note: payment.note,
        recordedById: payment.recordedById,
        recordedByName: payment.recordedByName,
      );
      await firebaseRef.set(saved.toMap());
    }

    AppUser? updated;
    try {
      updated = await AdminDemoData.applyPlanWithExpiry(
        user.id,
        plan,
        periodEnd,
      );
      if (updated == null) {
        throw const SubscriptionPaymentException(
          'Ce compte n\'est pas géré par la console (plan non applicable).',
        );
      }
    } catch (error) {
      if (firebaseRef != null) {
        try {
          await firebaseRef.delete();
        } catch (_) {}
      }
      rethrow;
    }

    if (!FirebaseService.isAvailable) {
      _localPayments.insert(0, saved);
      if (_localPayments.length > _maxLocal) {
        _localPayments.removeRange(_maxLocal, _localPayments.length);
      }
    }

    try {
      await SubscriptionService.instance.sendPaymentConfirmation(
        userId: user.id,
        planName: plan.name,
        amountLabel: Formatters.formatCurrency(amount),
        expiryLabel: Formatters.date.format(periodEnd),
      );
    } catch (error) {
      debugPrint('⚠ confirmation de paiement non envoyée : $error');
    }

    AdminAuditService.instance.recordAsync(
      action: 'payment.record',
      targetType: 'user',
      targetId: user.id,
      targetName: user.fullName,
      details:
          '${Formatters.formatCurrency(amount)} · ${method.label} · $periodMonths mois · ${plan.name}',
    );

    return saved;
  }

  Future<List<SubscriptionPayment>> paymentsFor(String userId) async {
    if (!FirebaseService.isAvailable) {
      return localPaymentsFor(userId);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(200)
          .get();
      final payments = snapshot.docs
          .map((doc) => SubscriptionPayment.fromMap(doc.data(), doc.id))
          .toList();
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return payments;
    } catch (error) {
      debugPrint('⚠ paiements d\'abonnement illisibles : $error');
      return localPaymentsFor(userId);
    }
  }

  List<SubscriptionPayment> localPaymentsFor(String userId) =>
      _localPayments.where((payment) => payment.userId == userId).toList();

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<({String id, String name})> _actor() async {
    try {
      final current = fb_auth.FirebaseAuth.instance.currentUser;
      if (current != null) {
        return (id: current.uid, name: current.email ?? 'Admin');
      }
    } catch (_) {}
    final demoAdmin =
        AuthService.demoUsers.where((user) => user.isAdmin).firstOrNull;
    return (
      id: demoAdmin?.id ?? 'admin_debug',
      name: demoAdmin?.fullName ?? 'Admin démo',
    );
  }
}
