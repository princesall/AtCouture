import 'package:equatable/equatable.dart';
import 'order_payment.dart';
import 'order_status.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.atelierId,
    required this.atelierName,
    required this.status,
    this.clientId,
    this.clientEmail,
    this.tailorId,
    this.measurements,
    this.modelPhotos,
    this.fabricPhotos,
    this.description,
    this.price,
    this.deposit,
    this.payments = const [],
    this.dueDate,
    this.createdAt,
    this.statusHistory = const [],
  });

  final String id;
  final String clientName;
  final String clientPhone;
  final String? clientEmail;
  final String? clientId; // Référence au client créé automatiquement
  final String? tailorId; // Référence au couturier assigné
  final String atelierId;
  final String atelierName;
  final OrderStatus status;
  
  // Mesures du client
  final Map<String, double>? measurements;
  
  // Photos (URLs ou chemins locaux)
  final List<String>? modelPhotos;
  final List<String>? fabricPhotos;
  
  // Détails de la commande
  final String? description;
  final int? price;

  /// Ancien champ « acompte unique ». Conservé pour la lecture des documents
  /// existants et réécrit en miroir du total versé (voir [toMap]) afin que les
  /// lecteurs historiques (PDF, badges) ne voient jamais un solde faux.
  /// La source de vérité est désormais [payments].
  final int? deposit;

  /// Tous les versements reçus, dans l'ordre de saisie. Voir [totalPaid] et
  /// [balanceDue] pour les montants qui en découlent.
  final List<OrderPayment> payments;

  final DateTime? dueDate;
  final DateTime? createdAt;

  // Historique des changements de statut (quand + par qui) — voir
  // OrderStatusChange. Le premier élément correspond à la création de la
  // commande (statut "pending").
  final List<OrderStatusChange> statusHistory;

  /// Total effectivement encaissé sur cette commande.
  int get totalPaid => payments.fold(0, (sum, p) => sum + p.amount);

  /// Reste à encaisser. Jamais négatif, même si le prix a été abaissé après
  /// coup sous le total déjà versé (le trop-perçu apparaît alors comme un
  /// solde de 0, pas comme une dette inversée).
  int get balanceDue {
    final total = price;
    if (total == null) return 0;
    final rest = total - totalPaid;
    return rest > 0 ? rest : 0;
  }

  /// Vrai si la commande a un prix connu et qu'il reste de l'argent à rentrer.
  bool get hasOutstandingBalance => balanceDue > 0;

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.inProgress:
        return 'En cours';
      case OrderStatus.completed:
        return 'Terminé';
      case OrderStatus.problem:
        return 'Problème';
    }
  }

  Order copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? clientId,
    String? tailorId,
    String? atelierId,
    String? atelierName,
    OrderStatus? status,
    Map<String, double>? measurements,
    List<String>? modelPhotos,
    List<String>? fabricPhotos,
    String? description,
    int? price,
    int? deposit,
    List<OrderPayment>? payments,
    DateTime? dueDate,
    DateTime? createdAt,
    List<OrderStatusChange>? statusHistory,
    bool clearTailor = false,
  }) {
    return Order(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientId: clientId ?? this.clientId,
      tailorId: clearTailor ? null : (tailorId ?? this.tailorId),
      atelierId: atelierId ?? this.atelierId,
      atelierName: atelierName ?? this.atelierName,
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      modelPhotos: modelPhotos ?? this.modelPhotos,
      fabricPhotos: fabricPhotos ?? this.fabricPhotos,
      description: description ?? this.description,
      price: price ?? this.price,
      deposit: deposit ?? this.deposit,
      payments: payments ?? this.payments,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      clientName: map['clientName'] as String? ?? '',
      clientPhone: map['clientPhone'] as String? ?? '',
      clientEmail: map['clientEmail'] as String?,
      clientId: map['clientId'] as String?,
      tailorId: map['tailorId'] as String?,
      atelierId: map['atelierId'] as String? ?? '',
      atelierName: map['atelierName'] as String? ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      measurements: (map['measurements'] as Map?)?.map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
      modelPhotos: (map['modelPhotos'] as List?)?.map((e) => e as String).toList(),
      fabricPhotos: (map['fabricPhotos'] as List?)?.map((e) => e as String).toList(),
      description: map['description'] as String?,
      price: map['price'] as int?,
      deposit: map['deposit'] as int?,
      payments: _paymentsFromMap(map),
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
      statusHistory: (map['statusHistory'] as List?)
              ?.map((e) => OrderStatusChange.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  /// Lit les versements d'un document Firestore.
  ///
  /// Les commandes créées avant l'arrivée de `payments` n'ont qu'un champ
  /// `deposit` : on le convertit en un premier versement daté (celui de la
  /// création de la commande) pour ne perdre aucune information comptable.
  static List<OrderPayment> _paymentsFromMap(Map<String, dynamic> map) {
    final raw = map['payments'] as List?;
    if (raw != null && raw.isNotEmpty) {
      return raw
          .map((e) => OrderPayment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => a.paidAt.compareTo(b.paidAt));
    }

    final legacyDeposit = (map['deposit'] as num?)?.toInt() ?? 0;
    if (legacyDeposit <= 0) return const [];

    return [
      OrderPayment(
        id: 'legacy-deposit',
        amount: legacyDeposit,
        paidAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        method: PaymentMethod.cash,
        note: 'Acompte initial',
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'clientId': clientId,
      'tailorId': tailorId,
      'atelierId': atelierId,
      'atelierName': atelierName,
      'status': status.name,
      'measurements': measurements,
      'modelPhotos': modelPhotos,
      'fabricPhotos': fabricPhotos,
      'description': description,
      'price': price,
      // `deposit` reste écrit en miroir du total versé : les lecteurs
      // historiques (PDF d'une version précédente, badges « Acompte ») ne
      // doivent jamais afficher un solde antérieur à la réalité.
      'deposit': payments.isEmpty ? deposit : totalPaid,
      'payments': payments.map((e) => e.toMap()).toList(),
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, clientName, atelierId, status];
}
