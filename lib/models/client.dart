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

  @override
  List<Object?> get props => [id, fullName, atelierId];
}
