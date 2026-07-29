import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.atelierId,
    required this.atelierName,
    this.email,
    this.notes,
    this.orderCount = 0,
    this.totalSpent = 0,
    this.orderIds = const [],
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String atelierId;
  final String atelierName;
  final String? email;
  final String? notes;
  final int orderCount;
  final int totalSpent;
  final List<String> orderIds; // Liste des IDs des commandes du client
  final DateTime? createdAt;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  Client copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? atelierId,
    String? atelierName,
    String? email,
    String? notes,
    int? orderCount,
    int? totalSpent,
    List<String>? orderIds,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      atelierId: atelierId ?? this.atelierId,
      atelierName: atelierName ?? this.atelierName,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
      orderIds: orderIds ?? this.orderIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Client.fromMap(Map<String, dynamic> map, String id) {
    return Client(
      id: id,
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      atelierId: map['atelierId'] as String? ?? '',
      atelierName: map['atelierName'] as String? ?? '',
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      orderCount: map['orderCount'] as int? ?? 0,
      totalSpent: map['totalSpent'] as int? ?? 0,
      orderIds: List<String>.from(map['orderIds'] as List? ?? []),
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'atelierId': atelierId,
      'atelierName': atelierName,
      'email': email,
      'notes': notes,
      'orderCount': orderCount,
      'totalSpent': totalSpent,
      'orderIds': orderIds,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, fullName, atelierId];
}
