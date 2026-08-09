/// Champs de mesures personnalisés définis par un atelier, en plus des 5
/// champs standards (épaule, poitrine, taille, hanche, longueur). Chaque
/// styliste travaille différemment selon le type de vêtement confectionné ;
/// un champ ajouté une fois ("Tour de bras", "Longueur manche"...) est
/// ensuite proposé pour tous les clients suivants du même atelier, plutôt
/// que d'obliger à le retaper à chaque commande.
class MeasurementFieldsService {
  MeasurementFieldsService._();
  static final MeasurementFieldsService instance = MeasurementFieldsService._();

  final Map<String, List<String>> _customLabelsByAtelier = {};

  List<String> customFieldsFor(String atelierId) =>
      List.unmodifiable(_customLabelsByAtelier[atelierId] ?? const []);

  /// Ajoute un nouveau champ de mesure pour l'atelier, s'il n'existe pas déjà
  /// (comparaison insensible à la casse pour éviter les doublons du type
  /// "Tour de bras" / "tour de bras").
  Future<void> addCustomField(String atelierId, String label) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    final list = _customLabelsByAtelier.putIfAbsent(atelierId, () => []);
    final alreadyExists = list.any((l) => l.toLowerCase() == trimmed.toLowerCase());
    if (!alreadyExists) list.add(trimmed);
  }

  /// Retire ce champ du catalogue de l'atelier — il ne sera plus proposé
  /// pour les prochaines commandes/clients. N'efface PAS une valeur déjà
  /// enregistrée sous ce label sur un client existant (voir
  /// OrderService.updateClientMeasurements pour ça, action séparée et
  /// volontaire côté fiche client).
  Future<void> removeCustomField(String atelierId, String label) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _customLabelsByAtelier[atelierId]?.removeWhere((l) => l.toLowerCase() == label.toLowerCase());
  }
}
