import 'package:equatable/equatable.dart';

/// Un Atelier (maison de couture) est géré par UN Chef Styliste (headStylistId).
/// - Plan Gratuit/Starter/Pro : l'atelier appartient directement au styliste (companyId == null).
/// - Plan Entreprise : plusieurs ateliers sont regroupés sous une même Entreprise (companyId == ownerId).
class Atelier extends Equatable {
  const Atelier({
    required this.id,
    required this.name,
    required this.headStylistId,
    required this.headStylistName,
    this.companyId,
    this.address,
    this.tailorIds = const [],
    this.clientCount = 0,
    this.activeOrderCount = 0,
    this.totalRevenue = 0,
    this.createdAt,
  });

  final String id;
  final String name;

  /// UID du Chef Styliste responsable de CET atelier précis (prend les mesures,
  /// envoie aux couturiers de sa maison).
  final String headStylistId;
  final String headStylistName;

  /// Si non-null, cet atelier appartient à une Entreprise (plan Entreprise).
  /// `companyId` == l'UID du Chef d'Entreprise propriétaire (companyOwner).
  final String? companyId;

  final String? address;
  final List<String> tailorIds;
  final int clientCount;
  final int activeOrderCount;
  final int totalRevenue;
  final DateTime? createdAt;

  bool get belongsToCompany => companyId != null;

  Atelier copyWith({
    String? id,
    String? name,
    String? headStylistId,
    String? headStylistName,
    String? companyId,
    String? address,
    List<String>? tailorIds,
    int? clientCount,
    int? activeOrderCount,
    int? totalRevenue,
    DateTime? createdAt,
  }) {
    return Atelier(
      id: id ?? this.id,
      name: name ?? this.name,
      headStylistId: headStylistId ?? this.headStylistId,
      headStylistName: headStylistName ?? this.headStylistName,
      companyId: companyId ?? this.companyId,
      address: address ?? this.address,
      tailorIds: tailorIds ?? this.tailorIds,
      clientCount: clientCount ?? this.clientCount,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Atelier.fromMap(Map<String, dynamic> map, String id) {
    return Atelier(
      id: id,
      name: map['name'] as String? ?? '',
      headStylistId: map['headStylistId'] as String? ?? '',
      headStylistName: map['headStylistName'] as String? ?? '',
      companyId: map['companyId'] as String?,
      address: map['address'] as String?,
      tailorIds: List<String>.from(map['tailorIds'] as List? ?? []),
      clientCount: map['clientCount'] as int? ?? 0,
      activeOrderCount: map['activeOrderCount'] as int? ?? 0,
      totalRevenue: map['totalRevenue'] as int? ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'headStylistId': headStylistId,
      'headStylistName': headStylistName,
      'companyId': companyId,
      'address': address,
      'tailorIds': tailorIds,
      'clientCount': clientCount,
      'activeOrderCount': activeOrderCount,
      'totalRevenue': totalRevenue,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, headStylistId, companyId];
}

/// Une Entreprise regroupe plusieurs Ateliers sous un seul propriétaire
/// (plan Entreprise uniquement). C'est le document "racine" de la hiérarchie.
class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    this.atelierIds = const [],
    this.createdAt,
  });

  final String id;
  final String name;

  /// UID du Chef d'Entreprise (role == companyOwner)
  final String ownerId;
  final String ownerName;
  final List<String> atelierIds;
  final DateTime? createdAt;

  Company copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? ownerName,
    List<String>? atelierIds,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      atelierIds: atelierIds ?? this.atelierIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Company.fromMap(Map<String, dynamic> map, String id) {
    return Company(
      id: id,
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      atelierIds: List<String>.from(map['atelierIds'] as List? ?? []),
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'atelierIds': atelierIds,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, ownerId];
}
