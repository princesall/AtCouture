import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/models/client.dart';

Client _baseClient() => const Client(
      id: 'client_1',
      fullName: 'Aïcha Test',
      phone: '0700000000',
      atelierId: 'atelier_1',
      atelierName: 'Atelier Test',
    );

void main() {
  group('Client.initials', () {
    test('takes the first letter of the first two words', () {
      expect(_baseClient().initials, 'AT');
    });

    test('falls back to a single letter for a one-word name', () {
      final client = _baseClient().copyWith(fullName: 'Madonna');
      expect(client.initials, 'M');
    });

    test('returns "?" for an empty name', () {
      final client = _baseClient().copyWith(fullName: '');
      expect(client.initials, '?');
    });
  });

  group('Client.copyWith', () {
    test('preserves fields that are not overridden', () {
      final client = _baseClient();
      final updated = client.copyWith(totalSpent: 5000);

      expect(updated.totalSpent, 5000);
      expect(updated.fullName, client.fullName);
      expect(updated.id, client.id);
    });
  });

  group('Client toMap/fromMap', () {
    test('round-trips including the measurement history', () {
      final client = _baseClient().copyWith(
        savedMeasurements: {'epaule': 40.0},
        measurementHistory: [
          MeasurementSnapshot(measurements: const {'epaule': 38.0}, recordedAt: DateTime(2026, 1, 1)),
          MeasurementSnapshot(measurements: const {'epaule': 40.0}, recordedAt: DateTime(2026, 2, 1)),
        ],
      );

      final restored = Client.fromMap(client.toMap(), client.id);

      expect(restored.fullName, client.fullName);
      expect(restored.savedMeasurements, client.savedMeasurements);
      expect(restored.measurementHistory, hasLength(2));
      expect(restored.measurementHistory.last.measurements['epaule'], 40.0);
    });

    test('fromMap defaults missing fields safely', () {
      final restored = Client.fromMap(const {}, 'client_x');

      expect(restored.fullName, '');
      expect(restored.orderIds, isEmpty);
      expect(restored.measurementHistory, isEmpty);
      expect(restored.savedMeasurements, isNull);
    });
  });
}
