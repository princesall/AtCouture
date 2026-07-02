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
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, fullName, atelierId];
}
