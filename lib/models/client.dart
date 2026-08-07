import 'package:equatable/equatable.dart';

/// Une prise de mesures horodatée — permet de suivre l'évolution physique
/// d'un client dans le temps (ex: après une grossesse, une perte de poids...)
/// plutôt que de n'avoir que la dernière valeur connue.
class MeasurementSnapshot extends Equatable {
  const MeasurementSnapshot({
    required this.measurements,
    required this.recordedAt,
  });

  final Map<String, double> measurements;
  final DateTime recordedAt;

  Map<String, dynamic> toMap() => {
        'measurements': measurements,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory MeasurementSnapshot.fromMap(Map<String, dynamic> map) => MeasurementSnapshot(
        measurements: (map['measurements'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
        // tryParse plutôt que parse : un historique de mesures avec une date
        // absente/corrompue ne doit jamais faire planter Client.fromMap.
        recordedAt: DateTime.tryParse(map['recordedAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [measurements, recordedAt];
}

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
    this.savedMeasurements,
    this.measurementHistory = const [],
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
  // Dernières mesures connues du client, réutilisées pour pré-remplir une
  // nouvelle commande sans avoir à re-mesurer un client déjà connu.
  final Map<String, double>? savedMeasurements;
  // Historique complet des prises de mesures, la plus récente en dernier.
  final List<MeasurementSnapshot> measurementHistory;
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
    Map<String, double>? savedMeasurements,
    List<MeasurementSnapshot>? measurementHistory,
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
      savedMeasurements: savedMeasurements ?? this.savedMeasurements,
      measurementHistory: measurementHistory ?? this.measurementHistory,
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
      savedMeasurements: (map['savedMeasurements'] as Map?)?.map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
      measurementHistory: (map['measurementHistory'] as List?)
              ?.map((e) => MeasurementSnapshot.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
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
      'savedMeasurements': savedMeasurements,
      'measurementHistory': measurementHistory.map((e) => e.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, fullName, atelierId];
}
