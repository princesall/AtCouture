import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/core/utils/subscription_periods.dart';

void main() {
  group('SubscriptionPeriods', () {
    test('ajoute des mois calendaires en bornant le jour', () {
      expect(
        SubscriptionPeriods.addMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
      expect(
        SubscriptionPeriods.addMonths(DateTime(2028, 1, 31), 1),
        DateTime(2028, 2, 29),
      );
      expect(
        SubscriptionPeriods.addMonths(DateTime(2026, 11, 30), 3),
        DateTime(2027, 2, 28),
      );
    });

    test('le renouvellement part de l\'échéance encore valide', () {
      final now = DateTime(2026, 11, 2, 10);
      final expiry = DateTime(2027, 5, 2, 10);

      expect(SubscriptionPeriods.renewalStart(expiry, now: now), expiry);
      expect(
        SubscriptionPeriods.renewalEnd(expiry, 1, now: now),
        DateTime(2027, 6, 2, 10),
      );
    });

    test('une échéance dépassée repart d\'aujourd\'hui', () {
      final now = DateTime(2026, 11, 2, 10);
      final expiry = DateTime(2026, 10, 1);

      expect(SubscriptionPeriods.renewalStart(expiry, now: now), now);
      expect(
        SubscriptionPeriods.renewalEnd(expiry, 12, now: now),
        DateTime(2027, 11, 2, 10),
      );
    });

    test('la durée est bornée entre 1 et 12 mois', () {
      final expiry = DateTime(2026, 11, 2, 10);
      final now = DateTime(2026, 10, 2, 10);

      expect(
        SubscriptionPeriods.renewalEnd(expiry, 0, now: now),
        DateTime(2026, 12, 2, 10),
      );
      expect(
        SubscriptionPeriods.renewalEnd(expiry, 24, now: now),
        DateTime(2027, 11, 2, 10),
      );
    });
  });
}
