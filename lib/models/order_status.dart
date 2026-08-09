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
    this.note,
    this.voiceNoteUrl,
  });

  final OrderStatus status;
  final DateTime changedAt;
  final String changedByName;
  // Description du signalement — surtout utile pour OrderStatus.problem, où
  // le statut seul n'explique rien (voir tailor_dashboard.dart:
  // ReportProblemDialog). Beaucoup de couturiers n'ont pas le temps ou
  // l'aisance d'écrire, d'où voiceNoteUrl en alternative : au moins l'un
  // des deux doit être renseigné quand on signale un problème, jamais
  // aucune obligation ici au niveau du modèle (reste valide pour les
  // entrées d'historique des autres statuts, qui n'en ont pas).
  final String? note;
  final String? voiceNoteUrl;

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'changedAt': changedAt.toIso8601String(),
        'changedByName': changedByName,
        if (note != null) 'note': note,
        if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
      };

  factory OrderStatusChange.fromMap(Map<String, dynamic> map) => OrderStatusChange(
        status: OrderStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => OrderStatus.pending,
        ),
        // tryParse plutôt que parse : une seule entrée d'historique avec une
        // date absente/corrompue ne doit jamais faire planter Order.fromMap
        // (et donc rendre TOUTE la liste de commandes de l'atelier inaccessible).
        changedAt: DateTime.tryParse(map['changedAt'] as String? ?? '') ?? DateTime.now(),
        changedByName: map['changedByName'] as String? ?? 'Inconnu',
        note: map['note'] as String?,
        voiceNoteUrl: map['voiceNoteUrl'] as String?,
      );

  @override
  List<Object?> get props => [status, changedAt, changedByName, note, voiceNoteUrl];
}
