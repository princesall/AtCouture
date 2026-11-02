import 'package:flutter_test/flutter_test.dart';

import 'package:styleconnect/core/utils/formatters.dart';

void main() {
  group('Formatters.daysUntil', () {
    test('compte des jours calendaires, pas des tranches de 24 h', () {
      final from = DateTime(2026, 11, 1, 23, 30);

      expect(Formatters.daysUntil(DateTime(2026, 11, 1, 23, 45), from: from), 0);
      expect(Formatters.daysUntil(DateTime(2026, 11, 2, 9), from: from), 1);
      expect(Formatters.daysUntil(DateTime(2026, 11, 13, 0, 5), from: from), 12);
    });

    test('renvoie un nombre négatif pour une date passée', () {
      final from = DateTime(2026, 11, 1, 8);

      expect(Formatters.daysUntil(DateTime(2026, 10, 31, 23), from: from), -1);
      expect(Formatters.daysUntil(DateTime(2026, 10, 28), from: from), -4);
    });

    test('franchit correctement les fins de mois et d\'année', () {
      expect(
        Formatters.daysUntil(
          DateTime(2027, 1, 1),
          from: DateTime(2026, 12, 31, 22),
        ),
        1,
      );
      expect(
        Formatters.daysUntil(
          DateTime(2027, 2, 28),
          from: DateTime(2027, 1, 31),
        ),
        28,
      );
    });
  });
}
