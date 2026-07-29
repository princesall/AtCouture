import 'package:equatable/equatable.dart';
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
    this.dueDate,
    this.createdAt,
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
  final int? deposit;
  final DateTime? dueDate;
  final DateTime? createdAt;

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
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientId: clientId ?? this.clientId,
      tailorId: tailorId ?? this.tailorId,
      atelierId: atelierId ?? this.atelierId,
      atelierName: atelierName ?? this.atelierName,
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      modelPhotos: modelPhotos ?? this.modelPhotos,
      fabricPhotos: fabricPhotos ?? this.fabricPhotos,
      description: description ?? this.description,
      price: price ?? this.price,
      deposit: deposit ?? this.deposit,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
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
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
    );
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
      'deposit': deposit,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, clientName, atelierId, status];
}
