import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/core/utils/plan_permissions.dart';
import 'package:styleconnect/models/subscription_plan.dart';

void main() {
  group('PlanPermissions.forUser — expiration', () {
    test('the free plan never expires, even with a past date', () {
      final permissions = PlanPermissions.forUser(
        plan: SubscriptionPlan.free,
        planExpiresAt: DateTime(2000, 1, 1),
      );

      expect(permissions.isExpired, isFalse);
      expect(permissions.plan, SubscriptionPlan.free);
    });

    test('a paid plan without an expiry date is treated as active', () {
      final permissions = PlanPermissions.forUser(plan: SubscriptionPlan.pro, planExpiresAt: null);

      expect(permissions.isExpired, isFalse);
      expect(permissions.plan, SubscriptionPlan.pro);
      expect(permissions.hasPdfExport, isTrue);
    });

    test('a paid plan past its expiry date falls back to free features', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final permissions = PlanPermissions.forUser(plan: SubscriptionPlan.pro, planExpiresAt: past);

      expect(permissions.isExpired, isTrue);
      expect(permissions.plan, SubscriptionPlan.free);
      expect(permissions.originalPlan, SubscriptionPlan.pro);
      expect(permissions.hasPdfExport, isFalse);
    });

    test('a paid plan with a future expiry date keeps its features', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final permissions = PlanPermissions.forUser(plan: SubscriptionPlan.pro, planExpiresAt: future);

      expect(permissions.isExpired, isFalse);
      expect(permissions.plan, SubscriptionPlan.pro);
      expect(permissions.hasPdfExport, isTrue);
    });

    test('an expired plan\'s locked message mentions renewal, not upsell', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final permissions = PlanPermissions.forUser(plan: SubscriptionPlan.pro, planExpiresAt: past);

      expect(permissions.pdfExportLockedMessage, contains('expiré'));
    });
  });

  group('PlanPermissions — quotas et fonctionnalités', () {
    test('the free plan includes saved measurements (explicit product decision)', () {
      final permissions = PlanPermissions.of(SubscriptionPlan.free);
      expect(permissions.hasSavedMeasurements, isTrue);
    });

    test('canAddClient respects the free plan limit of 20', () {
      final permissions = PlanPermissions.of(SubscriptionPlan.free);
      expect(permissions.canAddClient(19), isTrue);
      expect(permissions.canAddClient(20), isFalse);
    });

    test('unlimited plans always allow adding more', () {
      final permissions = PlanPermissions.of(SubscriptionPlan.pro);
      expect(permissions.isUnlimitedClients, isTrue);
      expect(permissions.canAddClient(999999), isTrue);
    });

    test('canAddTailor / canAddPhoto respect the starter plan limits', () {
      final permissions = PlanPermissions.of(SubscriptionPlan.starter);
      expect(permissions.canAddTailor(4), isTrue);
      expect(permissions.canAddTailor(5), isFalse);
      expect(permissions.isUnlimitedOrders, isTrue);
      expect(permissions.canAddPhoto(2), isTrue);
      expect(permissions.canAddPhoto(3), isFalse);
    });

    test('only the Entreprise plan can manage multiple ateliers', () {
      expect(PlanPermissions.of(SubscriptionPlan.enterprise).canManageMultipleAteliers, isTrue);
      expect(PlanPermissions.of(SubscriptionPlan.pro).canManageMultipleAteliers, isFalse);
    });
  });
}
