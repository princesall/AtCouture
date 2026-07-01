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
