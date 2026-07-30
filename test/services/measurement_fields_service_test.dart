import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/services/measurement_fields_service.dart';

void main() {
  final service = MeasurementFieldsService.instance;

  // MeasurementFieldsService.instance est un singleton partagé entre tous les
  // tests de ce fichier : on utilise un atelierId unique par test pour éviter
  // toute pollution croisée, plutôt que d'ajouter un mécanisme de reset
  // réservé aux tests dans le code de production.
  var atelierCounter = 0;
  String uniqueAtelierId() => 'mfs_test_atelier_${atelierCounter++}';

  test('a brand-new atelier has no custom fields', () {
    expect(service.customFieldsFor(uniqueAtelierId()), isEmpty);
  });

  test('addCustomField registers a new field', () async {
    final atelierId = uniqueAtelierId();
    await service.addCustomField(atelierId, 'Tour de bras');
    expect(service.customFieldsFor(atelierId), ['Tour de bras']);
  });

  test('adding the same label twice does not duplicate it (case-insensitive)', () async {
    final atelierId = uniqueAtelierId();
    await service.addCustomField(atelierId, 'Tour de bras');
    await service.addCustomField(atelierId, 'tour de bras');
    await service.addCustomField(atelierId, 'TOUR DE BRAS');

    expect(service.customFieldsFor(atelierId), hasLength(1));
  });

  test('a blank label is ignored', () async {
    final atelierId = uniqueAtelierId();
    await service.addCustomField(atelierId, '   ');
    expect(service.customFieldsFor(atelierId), isEmpty);
  });

  test('fields are scoped per atelier', () async {
    final atelierA = uniqueAtelierId();
    final atelierB = uniqueAtelierId();
    await service.addCustomField(atelierA, 'Tour de bras');

    expect(service.customFieldsFor(atelierB), isEmpty);
  });

  test('customFieldsFor returns an unmodifiable list', () async {
    final atelierId = uniqueAtelierId();
    await service.addCustomField(atelierId, 'Tour de bras');

    expect(() => service.customFieldsFor(atelierId).add('x'), throwsUnsupportedError);
  });
}
