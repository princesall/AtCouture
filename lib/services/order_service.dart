import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'firebase_service.dart';

/// Service de gestion des commandes avec création automatique de clients.
/// Quand une commande est créée, le client est automatiquement créé s'il
/// n'existe pas et la commande est liée au client via clientId.
///
/// Chaque méthode se branche sur FirebaseService.isAvailable : en mode
/// Firebase, `_orders`/`_clients` deviennent un CACHE tenu à jour par des
/// écoutes Firestore par atelier (voir _ensureAtelierSynced) — les mêmes
/// getters synchrones qu'aujourd'hui continuent de fonctionner sans
/// changement de signature. En mode démo (Firebase non connecté), ces
/// mêmes listes restent la source de vérité en mémoire, comme avant.
class OrderService extends ChangeNotifier {
  OrderService._();
  static final OrderService instance = OrderService._();

  // ── Données en mémoire (source de vérité démo, cache en mode Firestore) ──
  final List<Order> _orders = [];
  final List<Client> _clients = [];

  // ── Idempotence ───────────────────────────────────────────────────────────
  // Le bouton "Créer" est désactivé pendant la soumission côté UI, mais ça ne
  // protège qu'un seul écran contre le double-tap — pas une relecture réseau
  // ni un appel concurrent depuis un autre point d'entrée. On mémorise donc
  // le résultat par clé d'idempotence fournie par l'appelant (un UUID généré
  // une seule fois par formulaire) : rejouer le même appel avec la même clé
  // renvoie le résultat déjà produit au lieu de créer un doublon. En mode
  // Firestore, cette même clé sert D'ID DE DOCUMENT (voir _createOrderFirebase/
  // addClient) : rejouer une écriture en attente côté hors-ligne devient un
  // no-op au lieu d'un doublon, et l'ID n'est pas devinable (contrairement à
  // l'ancien compteur séquentiel), ce qui sera nécessaire le jour où l'écran
  // de suivi public lira une commande par son ID.
  final Map<String, ({Order order, bool isNewClient, Client? existingClient})> _orderIdempotencyCache = {};
  final Map<String, Client> _addClientIdempotencyCache = {};

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

  // ── Synchronisation Firestore (mode réel uniquement) ─────────────────────
  // Un atelier n'est écouté qu'une fois, déclenché par la première lecture
  // demandée pour lui (ordersOfAtelier/clientsOfAtelier/createOrder/...) —
  // pas d'écoute globale sur toute la collection, qui serait coûteuse et de
  // toute façon refusée par firestore.rules (list scopé par atelierId).
  final Set<String> _syncedAteliers = {};
  final Set<String> _syncedTailorScopes = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = [];

  /// Écoute dédiée pour un Couturier : contrairement à _ensureAtelierSynced
  /// (qui ne filtre QUE par atelierId), cette requête filtre AUSSI par
  /// tailorId côté serveur. C'est indispensable : firestore.rules n'autorise
  /// un simple couturier à lire que les commandes où tailorId == uid() —
  /// une requête liste qui ne contraint QUE atelierId est rejetée en bloc par
  /// Firestore (il ne peut pas garantir que CHAQUE document retourné
  /// satisferait la règle), pas filtrée document par document après coup.
  /// Sans ce filtre serveur, tout couturier voyait un tableau de bord/
  /// mesures/photos perpétuellement vides, sans aucune erreur visible.
  void _ensureTailorOrdersSynced(String atelierId, String tailorId) {
    if (!FirebaseService.isAvailable) return;
    final scopeKey = '$atelierId|$tailorId';
    if (!_syncedTailorScopes.add(scopeKey)) return;

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('orders')
          .where('atelierId', isEqualTo: atelierId)
          .where('tailorId', isEqualTo: tailorId)
          .snapshots()
          .listen((snap) {
        _orders.removeWhere((o) => o.atelierId == atelierId && o.tailorId == tailorId);
        _orders.addAll(snap.docs.map((d) => Order.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
  }

  void _ensureAtelierSynced(String atelierId) {
    if (!FirebaseService.isAvailable) return;
    if (!_syncedAteliers.add(atelierId)) return;

    final firestore = FirebaseFirestore.instance;
    _subscriptions.add(
      firestore.collection('orders').where('atelierId', isEqualTo: atelierId).snapshots().listen((snap) {
        _orders.removeWhere((o) => o.atelierId == atelierId);
        _orders.addAll(snap.docs.map((d) => Order.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
    _subscriptions.add(
      firestore.collection('clients').where('atelierId', isEqualTo: atelierId).snapshots().listen((snap) {
        _clients.removeWhere((c) => c.atelierId == atelierId);
        _clients.addAll(snap.docs.map((d) => Client.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
  }

  // ── Lectures ──────────────────────────────────────────────────────────────

  /// Toutes les commandes d'un atelier
  List<Order> ordersOfAtelier(String atelierId) {
    _ensureAtelierSynced(atelierId);
    return _orders.where((o) => o.atelierId == atelierId).toList();
  }

  /// Toutes les commandes assignées à un couturier précis d'un atelier
  /// donné — synchronise via une requête filtrée par tailorId (voir
  /// _ensureTailorOrdersSynced), pas _ensureAtelierSynced : un couturier n'a
  /// pas le droit de lister toutes les commandes de l'atelier, seulement les
  /// siennes. Utilisable même si aucun autre écran n'a encore rien chargé.
  List<Order> ordersOfTailor({required String atelierId, required String tailorId}) {
    _ensureTailorOrdersSynced(atelierId, tailorId);
    return _orders.where((o) => o.atelierId == atelierId && o.tailorId == tailorId).toList();
  }

  /// Toutes les commandes d'un client — suppose que l'atelier de ce client a
  /// déjà été synchronisé via un appel précédent à ordersOfAtelier/
  /// clientsOfAtelier (toujours le cas dans le parcours actuel : on affiche
  /// la liste d'un atelier avant d'ouvrir le détail d'un de ses clients).
  List<Order> ordersOfClient(String clientId) {
    return _orders.where((o) => o.clientId == clientId).toList();
  }

  /// Un client par son ID — même remarque que ordersOfClient ci-dessus.
  Client? clientById(String clientId) {
    return _clients.where((c) => c.id == clientId).firstOrNull;
  }

  /// Une commande par son ID — utilisé par l'écran de suivi public (sans
  /// compte) pour retrouver une commande à partir du numéro communiqué au
  /// client. NOTE : ne fonctionne qu'en mode démo pour l'instant — en mode
  /// Firestore, firestore.rules exige un compte authentifié pour lire une
  /// commande, donc l'écran /suivi restera vide tant qu'une authentification
  /// anonyme + une règle de lecture publique scopée par ID (pas par liste)
  /// n'auront pas été ajoutées volontairement, en suivi séparé.
  Order? orderById(String orderId) {
    return _orders.where((o) => o.id == orderId).firstOrNull;
  }

  /// Tous les clients d'un atelier
  List<Client> clientsOfAtelier(String atelierId) {
    _ensureAtelierSynced(atelierId);
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

  // ── Écritures ─────────────────────────────────────────────────────────────

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
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && _orderIdempotencyCache.containsKey(idempotencyKey)) {
      return _orderIdempotencyCache[idempotencyKey]!;
    }

    if (FirebaseService.isAvailable) {
      _ensureAtelierSynced(atelierId);
      final result = await _createOrderFirebase(
        clientName: clientName,
        clientPhone: clientPhone,
        atelierId: atelierId,
        atelierName: atelierName,
        clientEmail: clientEmail,
        tailorId: tailorId,
        measurements: measurements,
        modelPhotos: modelPhotos,
        fabricPhotos: fabricPhotos,
        description: description,
        price: price,
        deposit: deposit,
        dueDate: dueDate,
        createdByName: createdByName,
        orderDocId: idempotencyKey ?? FirebaseFirestore.instance.collection('orders').doc().id,
      );
      if (idempotencyKey != null) {
        _orderIdempotencyCache[idempotencyKey] = result;
      }
      return result;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final now = DateTime.now();
    final orderId = _nextOrderId();

    // 1. Chercher si le client existe déjà (par nom OU téléphone)
    var client = findClient(clientName, clientPhone, atelierId);
    client ??= findClientByPhone(clientPhone, atelierId);
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

    final result = (order: order, isNewClient: isNewClient, existingClient: existingClient);
    if (idempotencyKey != null) {
      _orderIdempotencyCache[idempotencyKey] = result;
    }
    return result;
  }

  /// Équivalent Firestore de createOrder ci-dessus. La recherche de client
  /// existant se fait par une requête serveur directe (pas via le cache
  /// local _clients, qui peut ne pas encore être synchronisé au moment de
  /// cet appel) pour éviter de créer un doublon.
  Future<({Order order, bool isNewClient, Client? existingClient})> _createOrderFirebase({
    required String clientName,
    required String clientPhone,
    required String atelierId,
    required String atelierName,
    required String orderDocId,
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
    final firestore = FirebaseFirestore.instance;
    final clientsRef = firestore.collection('clients');
    final trimmedName = clientName.trim();
    final trimmedPhone = clientPhone.trim();

    Future<QueryDocumentSnapshot<Map<String, dynamic>>?> search(String field, String value) async {
      final snap = await clientsRef
          .where('atelierId', isEqualTo: atelierId)
          .where(field, isEqualTo: value)
          .limit(1)
          .get();
      return snap.docs.firstOrNull;
    }

    var clientDoc = await search('phone', trimmedPhone);
    clientDoc ??= await search('fullName', trimmedName);

    final now = DateTime.now();
    final isNewClient = clientDoc == null;
    final existingClient = clientDoc != null ? Client.fromMap(clientDoc.data(), clientDoc.id) : null;

    final clientRef = clientDoc?.reference ?? clientsRef.doc();
    final client = existingClient ??
        Client(
          id: clientRef.id,
          fullName: trimmedName,
          phone: trimmedPhone,
          email: clientEmail?.trim(),
          atelierId: atelierId,
          atelierName: atelierName,
          createdAt: now,
        );

    final order = Order(
      id: orderDocId,
      clientName: trimmedName,
      clientPhone: trimmedPhone,
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
        OrderStatusChange(status: OrderStatus.pending, changedAt: now, changedByName: createdByName ?? 'Styliste'),
      ],
    );

    final hasNewMeasurements = measurements != null && measurements.isNotEmpty;
    final mergedMeasurements =
        hasNewMeasurements ? {...?client.savedMeasurements, ...measurements} : client.savedMeasurements;
    final measurementsChanged =
        hasNewMeasurements && !_measurementsEqual(client.savedMeasurements, mergedMeasurements);

    final updatedClient = client.copyWith(
      orderIds: [...client.orderIds, orderDocId],
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

    final batch = firestore.batch();
    batch.set(firestore.collection('orders').doc(orderDocId), order.toMap());
    batch.set(clientRef, updatedClient.toMap());
    await batch.commit();

    return (order: order, isNewClient: isNewClient, existingClient: existingClient);
  }

  /// Met à jour (fusionne) les mesures enregistrées d'un client, que ce soit
  /// depuis sa fiche profil ou automatiquement lors d'une commande.
  Future<void> updateClientMeasurements(String clientId, Map<String, double> measurements) async {
    if (FirebaseService.isAvailable) {
      final ref = FirebaseFirestore.instance.collection('clients').doc(clientId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final client = Client.fromMap(snap.data()!, clientId);
      final merged = {...?client.savedMeasurements, ...measurements};
      final changed = !_measurementsEqual(client.savedMeasurements, merged);
      final updates = <String, dynamic>{'savedMeasurements': merged};
      if (changed) {
        updates['measurementHistory'] = FieldValue.arrayUnion([
          MeasurementSnapshot(measurements: merged, recordedAt: DateTime.now()).toMap(),
        ]);
      }
      await ref.update(updates);
      return;
    }

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

  /// Ajoute un client manuellement (utilisé par l'UI)
  Future<Client> addClient({
    required String atelierId,
    required String atelierName,
    required String fullName,
    required String phone,
    String? email,
    String? notes,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && _addClientIdempotencyCache.containsKey(idempotencyKey)) {
      return _addClientIdempotencyCache[idempotencyKey]!;
    }

    if (FirebaseService.isAvailable) {
      _ensureAtelierSynced(atelierId);
      final firestore = FirebaseFirestore.instance;
      final docRef = idempotencyKey != null
          ? firestore.collection('clients').doc(idempotencyKey)
          : firestore.collection('clients').doc();
      final client = Client(
        id: docRef.id,
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email?.trim(),
        notes: notes,
        atelierId: atelierId,
        atelierName: atelierName,
        createdAt: DateTime.now(),
      );
      await docRef.set(client.toMap());
      if (idempotencyKey != null) {
        _addClientIdempotencyCache[idempotencyKey] = client;
      }
      return client;
    }

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
    if (idempotencyKey != null) {
      _addClientIdempotencyCache[idempotencyKey] = client;
    }
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
    if (FirebaseService.isAvailable) {
      final change = OrderStatusChange(status: newStatus, changedAt: DateTime.now(), changedByName: changedByName);
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'statusHistory': FieldValue.arrayUnion([change.toMap()]),
      });
      return;
    }

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
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'tailorId': tailorId});
      return;
    }

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
    if (FirebaseService.isAvailable) {
      final ref = FirebaseFirestore.instance.collection('orders').doc(orderId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final order = Order.fromMap(snap.data()!, orderId);

      final updates = <String, dynamic>{
        'measurements': ?measurements,
        'modelPhotos': ?modelPhotos,
        'fabricPhotos': ?fabricPhotos,
        'description': ?description,
        'price': ?price,
        'deposit': ?deposit,
        'dueDate': ?dueDate?.toIso8601String(),
      };
      if (updates.isNotEmpty) await ref.update(updates);

      if (price != null && order.clientId != null) {
        final oldPrice = order.price ?? 0;
        await FirebaseFirestore.instance.collection('clients').doc(order.clientId).update({
          'totalSpent': FieldValue.increment(price - oldPrice),
        });
      }
      if (measurements != null && measurements.isNotEmpty && order.clientId != null) {
        await updateClientMeasurements(order.clientId!, measurements);
      }
      return;
    }

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
    if (FirebaseService.isAvailable) {
      final ref = FirebaseFirestore.instance.collection('orders').doc(orderId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final order = Order.fromMap(snap.data()!, orderId);
      await ref.delete();
      if (order.clientId != null) {
        await FirebaseFirestore.instance.collection('clients').doc(order.clientId).update({
          'orderIds': FieldValue.arrayRemove([orderId]),
          'orderCount': FieldValue.increment(-1),
          'totalSpent': FieldValue.increment(-(order.price ?? 0)),
        });
      }
      return;
    }

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
    return ordersOfAtelier(atelierId)
        .where((o) => o.status == OrderStatus.completed)
        .fold(0, (sum, o) => sum + (o.price ?? 0));
  }
}
