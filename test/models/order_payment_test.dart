import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/models/order.dart';
import 'package:styleconnect/models/order_payment.dart';
import 'package:styleconnect/models/order_status.dart';

Order _order({
  int? price,
  int? deposit,
  List<OrderPayment> payments = const [],
  DateTime? createdAt,
}) =>
    Order(
      id: 'order_pay_1',
      clientName: 'Client Test',
      clientPhone: '0700000000',
      atelierId: 'atelier_1',
      atelierName: 'Atelier Test',
      status: OrderStatus.pending,
      price: price,
      deposit: deposit,
      payments: payments,
      createdAt: createdAt,
    );

OrderPayment _payment(int amount, {DateTime? at, PaymentMethod? method}) =>
    OrderPayment(
      id: 'p_$amount',
      amount: amount,
      paidAt: at ?? DateTime(2026, 1, 1),
      method: method ?? PaymentMethod.cash,
    );

void main() {
  group('Order — total versé et solde', () {
    test('totalPaid additionne tous les versements', () {
      final order = _order(
        price: 150000,
        payments: [_payment(50000), _payment(60000)],
      );

      expect(order.totalPaid, 110000);
    });

    test('balanceDue = prix − total versé', () {
      final order = _order(
        price: 150000,
        payments: [_payment(50000), _payment(60000)],
      );

      expect(order.balanceDue, 40000);
      expect(order.hasOutstandingBalance, isTrue);
    });

    test('balanceDue ne devient jamais négatif (trop-perçu)', () {
      final order = _order(
        price: 100000,
        payments: [_payment(80000), _payment(50000)],
      );

      expect(order.totalPaid, 130000);
      expect(order.balanceDue, 0);
      expect(order.hasOutstandingBalance, isFalse);
    });

    test('balanceDue vaut 0 quand le prix n\'est pas renseigné', () {
      final order = _order(payments: [_payment(50000)]);

      expect(order.totalPaid, 50000);
      expect(order.balanceDue, 0);
    });

    test('une commande sans versement affiche le prix comme reste dû', () {
      final order = _order(price: 75000);

      expect(order.totalPaid, 0);
      expect(order.balanceDue, 75000);
    });
  });

  group('Order.toMap / fromMap — versements', () {
    test('round-trips the payments list', () {
      final order = _order(
        price: 150000,
        payments: [
          _payment(50000, at: DateTime(2026, 1, 5), method: PaymentMethod.cash),
          _payment(60000, at: DateTime(2026, 2, 5), method: PaymentMethod.wave),
        ],
      );

      final restored = Order.fromMap(order.toMap(), order.id);

      expect(restored.payments, hasLength(2));
      expect(restored.totalPaid, 110000);
      expect(restored.balanceDue, 40000);
      expect(restored.payments.last.method, PaymentMethod.wave);
    });

    test('migre l\'ancien acompte unique en un versement daté', () {
      // Document écrit avant l'arrivée de `payments`.
      final legacy = {
        'clientName': 'Client Hérité',
        'clientPhone': '0700000001',
        'atelierId': 'atelier_1',
        'atelierName': 'Atelier Test',
        'status': 'pending',
        'price': 150000,
        'deposit': 50000,
        'createdAt': '2026-01-10T09:30:00.000',
      };

      final restored = Order.fromMap(legacy, 'order_legacy');

      expect(restored.payments, hasLength(1));
      expect(restored.totalPaid, 50000);
      expect(restored.balanceDue, 100000);
      // La date du versement hérité est celle de la création de la commande,
      // pour ne pas fausser les totaux encaissés d'un mois.
      expect(restored.payments.single.paidAt, DateTime(2026, 1, 10, 9, 30));
      expect(restored.payments.single.note, 'Acompte initial');
    });

    test('la liste de versements prime sur l\'ancien acompte', () {
      final restored = Order.fromMap({
        'clientName': 'Client Mixte',
        'clientPhone': '0700000002',
        'atelierId': 'atelier_1',
        'atelierName': 'Atelier Test',
        'price': 100000,
        'deposit': 90000,
        'payments': [
          {'id': 'p1', 'amount': 30000, 'paidAt': '2026-03-01T10:00:00.000'},
        ],
      }, 'order_mix');

      expect(restored.payments, hasLength(1));
      expect(restored.totalPaid, 30000);
      expect(restored.balanceDue, 70000);
    });

    test('toMap maintient `deposit` en miroir du total versé', () {
      final order = _order(
        price: 150000,
        deposit: 50000,
        payments: [_payment(50000), _payment(60000)],
      );

      final map = order.toMap();

      expect(map['deposit'], 110000);
      expect(map['payments'], hasLength(2));
    });

    test('aucun acompte hérité ne crée de versement fantôme', () {
      final restored = Order.fromMap({
        'clientName': 'Client Sans Acompte',
        'clientPhone': '0700000003',
        'atelierId': 'atelier_1',
        'atelierName': 'Atelier Test',
        'price': 200000,
        'deposit': 0,
      }, 'order_zero');

      expect(restored.payments, isEmpty);
      expect(restored.balanceDue, 200000);
    });
  });

  group('OrderPayment.fromMap', () {
    test('supporte un moyen de paiement inconnu sans lever', () {
      final payment = OrderPayment.fromMap({
        'id': 'p1',
        'amount': 25000,
        'paidAt': '2026-04-01T08:00:00.000',
        'method': 'cheque_marocain',
      });

      expect(payment.method, PaymentMethod.cash);
      expect(payment.amount, 25000);
    });

    test('round-trips amount, date et moyen', () {
      final payment = _payment(
        60000,
        at: DateTime(2026, 5, 20, 14, 15),
        method: PaymentMethod.orangeMoney,
      );

      final restored = OrderPayment.fromMap(payment.toMap());

      expect(restored.amount, 60000);
      expect(restored.method, PaymentMethod.orangeMoney);
      expect(restored.paidAt, DateTime(2026, 5, 20, 14, 15));
    });
  });
}
