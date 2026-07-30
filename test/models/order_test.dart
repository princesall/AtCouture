import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/models/order.dart';
import 'package:styleconnect/models/order_status.dart';

Order _baseOrder() => const Order(
      id: 'order_1',
      clientName: 'Client Test',
      clientPhone: '0700000000',
      atelierId: 'atelier_1',
      atelierName: 'Atelier Test',
      status: OrderStatus.pending,
      tailorId: 'tailor_1',
    );

void main() {
  group('Order.copyWith — assignation du couturier', () {
    test('clearTailor removes the assigned tailor', () {
      final order = _baseOrder();
      expect(order.tailorId, 'tailor_1');

      final cleared = order.copyWith(clearTailor: true);

      expect(cleared.tailorId, isNull);
    });

    test('passing a new tailorId reassigns it', () {
      final reassigned = _baseOrder().copyWith(tailorId: 'tailor_2');
      expect(reassigned.tailorId, 'tailor_2');
    });

    test('omitting tailorId keeps the previous assignment', () {
      final updated = _baseOrder().copyWith(description: 'Nouvelle robe');
      expect(updated.tailorId, 'tailor_1');
    });
  });

  group('Order.statusLabel', () {
    test('matches each OrderStatus', () {
      expect(_baseOrder().copyWith(status: OrderStatus.pending).statusLabel, 'En attente');
      expect(_baseOrder().copyWith(status: OrderStatus.inProgress).statusLabel, 'En cours');
      expect(_baseOrder().copyWith(status: OrderStatus.completed).statusLabel, 'Terminé');
      expect(_baseOrder().copyWith(status: OrderStatus.problem).statusLabel, 'Problème');
    });
  });

  group('Order toMap/fromMap', () {
    test('round-trips including the status history', () {
      final order = _baseOrder().copyWith(
        statusHistory: [
          OrderStatusChange(status: OrderStatus.pending, changedAt: DateTime(2026, 1, 1), changedByName: 'Aïcha'),
          OrderStatusChange(status: OrderStatus.inProgress, changedAt: DateTime(2026, 1, 2), changedByName: 'Aïcha'),
        ],
      );

      final restored = Order.fromMap(order.toMap(), order.id);

      expect(restored.status, order.status);
      expect(restored.tailorId, order.tailorId);
      expect(restored.statusHistory, hasLength(2));
      expect(restored.statusHistory.last.status, OrderStatus.inProgress);
    });

    test('fromMap defaults to pending status with empty history when missing', () {
      final restored = Order.fromMap(const {}, 'order_x');

      expect(restored.status, OrderStatus.pending);
      expect(restored.statusHistory, isEmpty);
    });
  });
}
