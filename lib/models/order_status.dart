import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending('En attente', 0),
  inProgress('En cours', 1),
  completed('Terminé', 2),
  problem('Problème', 3);

  const OrderStatus(this.label, this.order);
  final String label;
  final int order;

  bool canTransitionTo(OrderStatus next) {
    if (this == problem) return next == inProgress || next == completed;
    if (this == pending) return next == inProgress || next == problem;
    if (this == inProgress) return next == completed || next == problem;
    return false;
  }
}

/// Une entrée de l'historique des statuts d'une commande — quand et par qui
/// le statut a changé. Sert à mesurer les délais réels de production et à
/// arbitrer les litiges (ex: qui a marqué la commande "Problème", et quand).
class OrderStatusChange extends Equatable {
  const OrderStatusChange({
    required this.status,
    required this.changedAt,
    required this.changedByName,
  });

  final OrderStatus status;
  final DateTime changedAt;
  final String changedByName;

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'changedAt': changedAt.toIso8601String(),
        'changedByName': changedByName,
      };

  factory OrderStatusChange.fromMap(Map<String, dynamic> map) => OrderStatusChange(
        status: OrderStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => OrderStatus.pending,
        ),
        changedAt: DateTime.parse(map['changedAt'] as String),
        changedByName: map['changedByName'] as String? ?? 'Inconnu',
      );

  @override
  List<Object?> get props => [status, changedAt, changedByName];
}
