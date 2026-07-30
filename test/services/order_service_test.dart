import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/models/order_status.dart';
import 'package:styleconnect/services/order_service.dart';

void main() {
  final service = OrderService.instance;

  // OrderService.instance est un singleton partagé entre tous les tests de ce
  // fichier : on utilise un atelierId unique par test pour éviter toute
  // pollution croisée, plutôt que d'ajouter un mécanisme de reset réservé aux
  // tests dans le code de production.
  var atelierCounter = 0;
  String uniqueAtelierId() => 'osvc_test_atelier_${atelierCounter++}';

  group('createOrder — création/dédoublonnage automatique de client', () {
    test('creates a brand-new client when none matches', () async {
      final atelierId = uniqueAtelierId();

      final result = await service.createOrder(
        clientName: 'Aïcha Test',
        clientPhone: '0700000001',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
      );

      expect(result.isNewClient, isTrue);
      expect(result.order.status, OrderStatus.pending);
      expect(result.order.statusHistory, hasLength(1));
      expect(result.order.statusHistory.single.status, OrderStatus.pending);

      final client = service.clientById(result.order.clientId!);
      expect(client, isNotNull);
      expect(client!.orderCount, 1);
      expect(client.orderIds, [result.order.id]);
    });

    test('reuses an existing client matched by phone number', () async {
      final atelierId = uniqueAtelierId();

      final first = await service.createOrder(
        clientName: 'Client Un',
        clientPhone: '0700000002',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        price: 10000,
      );

      // Nom légèrement différent mais même téléphone : doit matcher le même client.
      final second = await service.createOrder(
        clientName: 'Client Un (surnom)',
        clientPhone: '0700000002',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        price: 5000,
      );

      expect(second.isNewClient, isFalse);
      expect(second.order.clientId, first.order.clientId);

      final client = service.clientById(first.order.clientId!)!;
      expect(client.orderCount, 2);
      expect(client.totalSpent, 15000);
      expect(client.orderIds, containsAll([first.order.id, second.order.id]));
    });

    test('createdByName is recorded as the author of the first status entry', () async {
      final atelierId = uniqueAtelierId();
      final result = await service.createOrder(
        clientName: 'Client Auteur',
        clientPhone: '0700000003',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        createdByName: 'Fatou',
      );

      expect(result.order.statusHistory.single.changedByName, 'Fatou');
    });

    test('falls back to "Styliste" when no author name is provided', () async {
      final atelierId = uniqueAtelierId();
      final result = await service.createOrder(
        clientName: 'Client Sans Auteur',
        clientPhone: '0700000004',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
      );

      expect(result.order.statusHistory.single.changedByName, 'Styliste');
    });
  });

  group('mesures — historique', () {
    test('createOrder appends a measurement snapshot only when values actually change', () async {
      final atelierId = uniqueAtelierId();

      final first = await service.createOrder(
        clientName: 'Client Mesures',
        clientPhone: '0700000005',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        measurements: const {'epaule': 38},
      );
      var client = service.clientById(first.order.clientId!)!;
      expect(client.measurementHistory, hasLength(1));
      expect(client.savedMeasurements, {'epaule': 38.0});

      // Même mesure, même valeur : pas de nouvelle entrée d'historique.
      await service.createOrder(
        clientName: 'Client Mesures',
        clientPhone: '0700000005',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        measurements: const {'epaule': 38},
      );
      client = service.clientById(first.order.clientId!)!;
      expect(client.measurementHistory, hasLength(1));

      // Valeur différente : nouvelle entrée d'historique.
      await service.createOrder(
        clientName: 'Client Mesures',
        clientPhone: '0700000005',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        measurements: const {'epaule': 40},
      );
      client = service.clientById(first.order.clientId!)!;
      expect(client.measurementHistory, hasLength(2));
      expect(client.savedMeasurements, {'epaule': 40.0});
    });

    test('updateClientMeasurements merges fields and dedupes unchanged updates', () async {
      final atelierId = uniqueAtelierId();
      final client = await service.addClient(
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        fullName: 'Client Profil',
        phone: '0700000006',
      );

      await service.updateClientMeasurements(client.id, const {'epaule': 38});
      await service.updateClientMeasurements(client.id, const {'epaule': 38}); // no-op
      var updated = service.clientById(client.id)!;
      expect(updated.measurementHistory, hasLength(1));

      await service.updateClientMeasurements(client.id, const {'poitrine': 90});
      updated = service.clientById(client.id)!;
      expect(updated.measurementHistory, hasLength(2));
      expect(updated.savedMeasurements, {'epaule': 38.0, 'poitrine': 90.0});
    });
  });

  group('statut — historique et transitions', () {
    test('updateOrderStatus appends a new entry each time, keeping the prior ones', () async {
      final atelierId = uniqueAtelierId();
      final result = await service.createOrder(
        clientName: 'Client Statut',
        clientPhone: '0700000007',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        createdByName: 'Fatou',
      );

      await service.updateOrderStatus(result.order.id, OrderStatus.inProgress, changedByName: 'Moussa');
      await service.updateOrderStatus(result.order.id, OrderStatus.completed, changedByName: 'Moussa');

      final order = service.orderById(result.order.id)!;
      expect(order.status, OrderStatus.completed);
      expect(order.statusHistory, hasLength(3));
      expect(order.statusHistory.map((c) => c.status), [
        OrderStatus.pending,
        OrderStatus.inProgress,
        OrderStatus.completed,
      ]);
      expect(order.statusHistory.last.changedByName, 'Moussa');
    });
  });

  group('assignTailor', () {
    test('assigns, reassigns, then clears the tailor', () async {
      final atelierId = uniqueAtelierId();
      final result = await service.createOrder(
        clientName: 'Client Couturier',
        clientPhone: '0700000008',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
      );
      expect(result.order.tailorId, isNull);

      await service.assignTailor(result.order.id, 'tailor_a');
      expect(service.orderById(result.order.id)!.tailorId, 'tailor_a');

      await service.assignTailor(result.order.id, 'tailor_b');
      expect(service.orderById(result.order.id)!.tailorId, 'tailor_b');

      await service.assignTailor(result.order.id, null);
      expect(service.orderById(result.order.id)!.tailorId, isNull);
    });
  });

  group('deleteOrder', () {
    test('removes the order and rolls back the client stats', () async {
      final atelierId = uniqueAtelierId();
      final result = await service.createOrder(
        clientName: 'Client Suppr',
        clientPhone: '0700000009',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        price: 20000,
      );

      await service.deleteOrder(result.order.id);

      expect(service.orderById(result.order.id), isNull);
      final client = service.clientById(result.order.clientId!)!;
      expect(client.orderCount, 0);
      expect(client.totalSpent, 0);
      expect(client.orderIds, isEmpty);
    });
  });

  group('stats', () {
    test('atelierStats counts orders by status, atelierRevenue sums completed orders only', () async {
      final atelierId = uniqueAtelierId();

      final a = await service.createOrder(
        clientName: 'Client A',
        clientPhone: '0700000010',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        price: 10000,
      );
      final b = await service.createOrder(
        clientName: 'Client B',
        clientPhone: '0700000011',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        price: 20000,
      );
      await service.createOrder(
        clientName: 'Client C',
        clientPhone: '0700000012',
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        price: 30000,
      );

      await service.updateOrderStatus(a.order.id, OrderStatus.completed, changedByName: 'X');
      await service.updateOrderStatus(b.order.id, OrderStatus.inProgress, changedByName: 'X');

      final stats = service.atelierStats(atelierId);
      expect(stats.totalOrders, 3);
      expect(stats.completedOrders, 1);
      expect(stats.inProgressOrders, 1);
      expect(stats.pendingOrders, 1);

      expect(service.atelierRevenue(atelierId), 10000);
    });
  });

  group('recherche client', () {
    test('findClientByPhone / findClientByName / clientExists / searchClients', () async {
      final atelierId = uniqueAtelierId();
      await service.addClient(
        atelierId: atelierId,
        atelierName: 'Atelier Test',
        fullName: 'Kadiatou Diallo',
        phone: '0799999999',
      );

      expect(service.findClientByPhone('0799999999', atelierId)?.fullName, 'Kadiatou Diallo');
      expect(service.findClientByName('kadiatou diallo', atelierId), isNotNull);
      expect(service.clientExists('Kadiatou Diallo', '0799999999', atelierId), isTrue);
      expect(service.clientExists('Quelqu\'un d\'autre', '0000000000', atelierId), isFalse);
      expect(service.searchClients('kadia', atelierId), hasLength(1));
      expect(service.searchClients('0799', atelierId), hasLength(1));
      expect(service.searchClients('inexistant', atelierId), isEmpty);
    });
  });
}
