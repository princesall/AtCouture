import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/services/order_service.dart';

/// Non-régression sur les opérations de gestion des fiches clients, ajoutées
/// parce qu'un client était jusqu'ici impossible à modifier ou à supprimer
/// (une faute de frappe sur un nom ou un numéro était donc définitive).
///
/// Ces tests s'exécutent en mode démo (Firebase non initialisé), comme le reste
/// de la suite : OrderService y utilise ses listes en mémoire.
void main() {
  final service = OrderService.instance;

  test('updateClient met à jour nom, téléphone et email de la fiche', () async {
    final atelierId = 'atelier_test_update_${DateTime.now().microsecondsSinceEpoch}';
    final client = await service.addClient(
      atelierId: atelierId,
      atelierName: 'Atelier Test',
      fullName: 'Awa Traore',
      phone: '70000001',
      idempotencyKey: 'client-$atelierId',
    );

    await service.updateClient(
      clientId: client.id,
      fullName: 'Awa Traore Diallo',
      phone: '70000002',
      email: 'awa@example.ml',
    );

    final updated = service.clientById(client.id);
    expect(updated, isNotNull);
    expect(updated!.fullName, 'Awa Traore Diallo');
    expect(updated.phone, '70000002');
    expect(updated.email, 'awa@example.ml');
  });

  test('deleteClient est refusé tant qu\'une commande est liée au client', () async {
    final atelierId = 'atelier_test_delete_${DateTime.now().microsecondsSinceEpoch}';
    final result = await service.createOrder(
      clientName: 'Moussa Keita',
      clientPhone: '70000003',
      atelierId: atelierId,
      atelierName: 'Atelier Test',
      idempotencyKey: 'order-$atelierId',
    );
    final clientId = result.order.clientId!;

    // Supprimer la fiche rendrait la commande orpheline : elle disparaîtrait
    // des statistiques du client mais resterait dans celles de l'atelier.
    expect(await service.deleteClient(clientId), isFalse);
    expect(service.clientById(clientId), isNotNull);

    // Sans commande liée, la suppression est autorisée.
    await service.deleteOrder(result.order.id);
    expect(await service.deleteClient(clientId), isTrue);
    expect(service.clientById(clientId), isNull);
  });

  test('updateClient ne modifie pas les autres fiches du même atelier', () async {
    final atelierId = 'atelier_test_scope_${DateTime.now().microsecondsSinceEpoch}';
    final other = await service.addClient(
      atelierId: atelierId,
      atelierName: 'Atelier Test',
      fullName: 'Fatoumata Sissoko',
      phone: '70000004',
      idempotencyKey: 'other-$atelierId',
    );
    final target = await service.addClient(
      atelierId: atelierId,
      atelierName: 'Atelier Test',
      fullName: 'Ibrahim Cisse',
      phone: '70000005',
      idempotencyKey: 'target-$atelierId',
    );

    await service.updateClient(
      clientId: target.id,
      fullName: 'Ibrahim Cisse Jr',
      phone: '70000006',
    );

    expect(service.clientById(target.id)!.fullName, 'Ibrahim Cisse Jr');
    expect(service.clientById(other.id)!.fullName, 'Fatoumata Sissoko');
    expect(service.clientById(other.id)!.phone, '70000004');
  });
}
