import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/models/order_status.dart';

void main() {
  group('OrderStatus.canTransitionTo', () {
    test('pending can only move to inProgress or problem', () {
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.inProgress), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.problem), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.completed), isFalse);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.pending), isFalse);
    });

    test('inProgress can only move to completed or problem', () {
      expect(OrderStatus.inProgress.canTransitionTo(OrderStatus.completed), isTrue);
      expect(OrderStatus.inProgress.canTransitionTo(OrderStatus.problem), isTrue);
      expect(OrderStatus.inProgress.canTransitionTo(OrderStatus.pending), isFalse);
    });

    test('problem can only move to inProgress or completed', () {
      expect(OrderStatus.problem.canTransitionTo(OrderStatus.inProgress), isTrue);
      expect(OrderStatus.problem.canTransitionTo(OrderStatus.completed), isTrue);
      expect(OrderStatus.problem.canTransitionTo(OrderStatus.pending), isFalse);
    });

    test('completed is a terminal state — no transition is allowed', () {
      for (final next in OrderStatus.values) {
        expect(OrderStatus.completed.canTransitionTo(next), isFalse);
      }
    });
  });

  group('OrderStatusChange', () {
    test('round-trips through toMap/fromMap', () {
      final change = OrderStatusChange(
        status: OrderStatus.inProgress,
        changedAt: DateTime(2026, 7, 30, 12),
        changedByName: 'Aïcha',
      );

      final restored = OrderStatusChange.fromMap(change.toMap());

      expect(restored, change);
    });

    test('fromMap falls back to pending for an unknown status string', () {
      final restored = OrderStatusChange.fromMap({
        'status': 'not_a_real_status',
        'changedAt': DateTime(2026).toIso8601String(),
        'changedByName': 'X',
      });

      expect(restored.status, OrderStatus.pending);
    });

    test('fromMap falls back to "Inconnu" when changedByName is missing', () {
      final restored = OrderStatusChange.fromMap({
        'status': 'pending',
        'changedAt': DateTime(2026).toIso8601String(),
      });

      expect(restored.changedByName, 'Inconnu');
    });
  });
}
