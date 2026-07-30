import '../models/client.dart';
import '../models/order.dart';
import '../models/order_status.dart';

/// Service de gestion des commandes avec création automatique de clients
/// Quand une commande est créée, le client est automatiquement créé s'il n'existe pas
/// et la commande est liée au client via clientId
class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  // ── Données démo en mémoire ──────────────────────────────────────────────
  final List<Order> _orders = [];
  final List<Client> _clients = [];

  // Initialiser les données de démo
  void _initDemoData() {
    // Plus de données de démo - application vide pour tests
  }

  // ── Compteurs pour génération d'IDs démo ─────────────────────────────────
  int _orderIdCounter = 1000;
  int _clientIdCounter = 2000;
  String _nextOrderId() => 'order_${_orderIdCounter++}';
  String _nextClientId() => 'client_${_clientIdCounter++}';

  bool _measurementsEqual(Map<String, double>? a, Map<String, double>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  // ── Lectures ──────────────────────────────────────────────────────────────

  /// Toutes les commandes d'un atelier
  List<Order> ordersOfAtelier(String atelierId) {
    _initDemoData();
    return _orders.where((o) => o.atelierId == atelierId).toList();
  }

  /// Toutes les commandes d'un client
  List<Order> ordersOfClient(String clientId) {
    _initDemoData();
    return _orders.where((o) => o.clientId == clientId).toList();
  }

  /// Un client par son ID
  Client? clientById(String clientId) {
    _initDemoData();
    return _clients.where((c) => c.id == clientId).firstOrNull;
  }

  /// Une commande par son ID — utilisé par l'écran de suivi public (sans
  /// compte) pour retrouver une commande à partir du numéro communiqué au
  /// client.
  Order? orderById(String orderId) {
    _initDemoData();
    return _orders.where((o) => o.id == orderId).firstOrNull;
  }

  /// Tous les clients d'un atelier
  List<Client> clientsOfAtelier(String atelierId) {
    _initDemoData();
    return _clients.where((c) => c.atelierId == atelierId).toList();
  }

  /// Recherche un client par nom et téléphone (pour éviter les doublons)
  Client? findClient(String fullName, String phone, String atelierId) {
    return _clients.where((c) =>
        c.fullName.toLowerCase() == fullName.toLowerCase() &&
        c.phone == phone &&
        c.atelierId == atelierId
    ).firstOrNull;
  }

  /// Recherche un client par nom OU téléphone (plus flexible pour l'UI)
  /// Retourne tous les clients qui correspondent au nom OU au téléphone
  List<Client> searchClients(String query, String atelierId) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return [];

    return _clients.where((c) =>
        c.atelierId == atelierId &&
        (c.fullName.toLowerCase().contains(normalizedQuery) ||
         c.phone.contains(normalizedQuery))
    ).toList();
  }

  /// Vérifie si un client existe déjà par nom OU téléphone
  bool clientExists(String fullName, String phone, String atelierId) {
    return _clients.any((c) =>
        c.atelierId == atelierId &&
        (c.fullName.toLowerCase() == fullName.toLowerCase() ||
         c.phone == phone)
    );
  }

  /// Trouve un client par téléphone exact
  Client? findClientByPhone(String phone, String atelierId) {
    return _clients.where((c) =>
        c.phone == phone &&
        c.atelierId == atelierId
    ).firstOrNull;
  }

  /// Trouve un client par nom exact (insensible à la casse)
  Client? findClientByName(String fullName, String atelierId) {
    return _clients.where((c) =>
        c.fullName.toLowerCase() == fullName.toLowerCase() &&
        c.atelierId == atelierId
    ).firstOrNull;
  }

  // ── Écritures (démo, persistent en mémoire le temps de la session) ──────

  /// Crée une nouvelle commande avec création automatique du client si nécessaire
  /// - Si le client existe déjà (même nom OU téléphone), on le réutilise
  /// - Sinon, on crée un nouveau client automatiquement
  /// - La commande est liée au client via clientId
  /// - Retourne un tuple (order, isNewClient, existingClient) pour informer l'UI
  Future<({Order order, bool isNewClient, Client? existingClient})> createOrder({
    required String clientName,
    required String clientPhone,
    required String atelierId,
    required String atelierName,
    String? clientEmail,
    String? tailorId,
    Map<String, double>? measurements,
    List<String>? modelPhotos,
    List<String>? fabricPhotos,
    String? description,
    int? price,
    int? deposit,
    DateTime? dueDate,
    String? createdByName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final now = DateTime.now();
    final orderId = _nextOrderId();

    // 1. Chercher si le client existe déjà (par nom OU téléphone)
    var client = findClient(clientName, clientPhone, atelierId);
    
    // Si pas trouvé par nom+téléphone exact, chercher par téléphone seul
    client ??= findClientByPhone(clientPhone, atelierId);
    
    // Si pas trouvé par téléphone, chercher par nom seul
    client ??= findClientByName(clientName, atelierId);

    final isNewClient = client == null;
    Client? existingClient = client;

    // 2. Si le client n'existe pas, le créer automatiquement
    if (client == null) {
      final clientId = _nextClientId();
      client = Client(
        id: clientId,
        fullName: clientName.trim(),
        phone: clientPhone.trim(),
        email: clientEmail?.trim(),
        atelierId: atelierId,
        atelierName: atelierName,
        orderCount: 0,
        totalSpent: 0,
        orderIds: [],
        createdAt: now,
      );
      _clients.add(client);
    }

    // 3. Créer la commande liée au client
    final order = Order(
      id: orderId,
      clientName: clientName.trim(),
      clientPhone: clientPhone.trim(),
      clientEmail: clientEmail?.trim(),
      clientId: client.id,
      tailorId: tailorId,
      atelierId: atelierId,
      atelierName: atelierName,
      status: OrderStatus.pending,
      measurements: measurements,
      modelPhotos: modelPhotos,
      fabricPhotos: fabricPhotos,
      description: description,
      price: price,
      deposit: deposit,
      dueDate: dueDate,
      createdAt: now,
      statusHistory: [
        OrderStatusChange(
          status: OrderStatus.pending,
          changedAt: now,
          changedByName: createdByName ?? 'Styliste',
        ),
      ],
    );
    _orders.add(order);

    // 4. Mettre à jour le client (ajouter l'ID de commande, incrémenter les
    // stats, et mémoriser les mesures prises pour pouvoir les réutiliser
    // automatiquement à la prochaine commande de ce client, avec un
    // historique horodaté si les mesures ont réellement changé).
    final clientIndex = _clients.indexWhere((c) => c.id == client?.id);
    if (clientIndex != -1) {
      final hasNewMeasurements = measurements != null && measurements.isNotEmpty;
      final mergedMeasurements = hasNewMeasurements
          ? {...?client.savedMeasurements, ...measurements}
          : client.savedMeasurements;
      final measurementsChanged =
          hasNewMeasurements && !_measurementsEqual(client.savedMeasurements, mergedMeasurements);

      final updatedClient = client.copyWith(
        orderIds: [...client.orderIds, orderId],
        orderCount: client.orderCount + 1,
        totalSpent: client.totalSpent + (price ?? 0),
        savedMeasurements: mergedMeasurements,
        measurementHistory: measurementsChanged
            ? [
                ...client.measurementHistory,
                MeasurementSnapshot(measurements: mergedMeasurements!, recordedAt: now),
              ]
            : client.measurementHistory,
      );
      _clients[clientIndex] = updatedClient;
    }

    return (order: order, isNewClient: isNewClient, existingClient: existingClient);
  }

  /// Met à jour (fusionne) les mesures enregistrées d'un client, que ce soit
  /// depuis sa fiche profil ou automatiquement lors d'une commande.
  Future<void> updateClientMeasurements(String clientId, Map<String, double> measurements) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index == -1) return;

    final client = _clients[index];
    final merged = {...?client.savedMeasurements, ...measurements};
    final changed = !_measurementsEqual(client.savedMeasurements, merged);

    _clients[index] = client.copyWith(
      savedMeasurements: merged,
      measurementHistory: changed
          ? [
              ...client.measurementHistory,
              MeasurementSnapshot(measurements: merged, recordedAt: DateTime.now()),
            ]
          : client.measurementHistory,
    );
  }

  /// Ajoute un client manuellement (utilisé par l'UI pour la démo)
  Future<Client> addClient({
    required String atelierId,
    required String atelierName,
    required String fullName,
    required String phone,
    String? email,
    String? notes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final clientId = _nextClientId();
    final client = Client(
      id: clientId,
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email?.trim(),
      notes: notes,
      atelierId: atelierId,
      atelierName: atelierName,
      orderCount: 0,
      totalSpent: 0,
      orderIds: [],
      createdAt: DateTime.now(),
    );
    _clients.add(client);
    return client;
  }

  /// Met à jour le statut d'une commande, en traçant qui a fait le
  /// changement et quand (voir Order.statusHistory) — utile pour mesurer les
  /// délais réels de production et arbitrer les litiges.
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    required String changedByName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final order = _orders[index];
    _orders[index] = order.copyWith(
      status: newStatus,
      statusHistory: [
        ...order.statusHistory,
        OrderStatusChange(status: newStatus, changedAt: DateTime.now(), changedByName: changedByName),
      ],
    );
  }

  /// Assigne (ou réassigne) le couturier en charge d'une commande —
  /// utilisable à tout moment depuis le détail de la commande, pas
  /// seulement à la création. Passer `tailorId: null` retire l'assignation
  /// actuelle (commande "non assignée").
  Future<void> assignTailor(String orderId, String? tailorId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final order = _orders[index];
    _orders[index] = order.copyWith(tailorId: tailorId, clearTailor: tailorId == null);
  }

  /// Met à jour les détails d'une commande
  Future<void> updateOrder({
    required String orderId,
    Map<String, double>? measurements,
    List<String>? modelPhotos,
    List<String>? fabricPhotos,
    String? description,
    int? price,
    int? deposit,
    DateTime? dueDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final order = _orders[index];
    _orders[index] = order.copyWith(
      measurements: measurements ?? order.measurements,
      modelPhotos: modelPhotos ?? order.modelPhotos,
      fabricPhotos: fabricPhotos ?? order.fabricPhotos,
      description: description ?? order.description,
      price: price ?? order.price,
      deposit: deposit ?? order.deposit,
      dueDate: dueDate ?? order.dueDate,
    );

    // Si le prix change, mettre à jour le totalSpent du client
    if (price != null && order.clientId != null) {
      final clientIndex = _clients.indexWhere((c) => c.id == order.clientId);
      if (clientIndex != -1) {
        final client = _clients[clientIndex];
        final oldPrice = order.price ?? 0;
        final priceDiff = price - oldPrice;
        _clients[clientIndex] = client.copyWith(
          totalSpent: client.totalSpent + priceDiff,
        );
      }
    }

    // Si les mesures changent, les mémoriser aussi sur la fiche client.
    if (measurements != null && measurements.isNotEmpty && order.clientId != null) {
      await updateClientMeasurements(order.clientId!, measurements);
    }
  }

  /// Supprime une commande
  Future<void> deleteOrder(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final order = _orders.where((o) => o.id == orderId).firstOrNull;
    if (order == null) return;

    _orders.removeWhere((o) => o.id == orderId);

    // Mettre à jour le client (retirer l'ID de commande et décrémenter les stats)
    if (order.clientId != null) {
      final clientIndex = _clients.indexWhere((c) => c.id == order.clientId);
      if (clientIndex != -1) {
        final client = _clients[clientIndex];
        _clients[clientIndex] = client.copyWith(
          orderIds: client.orderIds.where((id) => id != orderId).toList(),
          orderCount: client.orderCount - 1,
          totalSpent: client.totalSpent - (order.price ?? 0),
        );
      }
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  /// KPIs pour un atelier
  ({int totalOrders, int pendingOrders, int inProgressOrders, int completedOrders})
      atelierStats(String atelierId) {
    final orders = ordersOfAtelier(atelierId);
    return (
      totalOrders: orders.length,
      pendingOrders: orders.where((o) => o.status == OrderStatus.pending).length,
      inProgressOrders: orders.where((o) => o.status == OrderStatus.inProgress).length,
      completedOrders: orders.where((o) => o.status == OrderStatus.completed).length,
    );
  }

  /// Revenu total d'un atelier (somme des prix des commandes livrées)
  int atelierRevenue(String atelierId) {
    _initDemoData();
    return ordersOfAtelier(atelierId)
        .where((o) => o.status == OrderStatus.completed)
        .fold(0, (sum, o) => sum + (o.price ?? 0));
  }
}
