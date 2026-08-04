import 'subscription_plan.dart';

/// Demande de changement de plan soumise par un styliste, en attente de
/// décision admin (voir admin_subscriptions_screen.dart "EN ATTENTE").
/// `id` est l'ID du document Firestore correspondant (subscriptionRequests/{id}) ;
/// reste null en mode démo, où la demande vit directement dans StylistEntry
/// sans document séparé (voir AdminDemoData).
class SubscriptionRequest {
  const SubscriptionRequest({
    this.id,
    required this.userId,
    required this.requestedPlan,
    required this.requestedAt,
    this.approved = false,
  });

  final String? id;
  final String userId;
  final SubscriptionPlan requestedPlan;
  final DateTime requestedAt;

  /// Toujours false tant que la demande existe : une fois décidée
  /// (approuvée/refusée), le document est marqué et cesse d'apparaître dans
  /// les requêtes "status == pending" — voir SubscriptionService.
  final bool approved;

  factory SubscriptionRequest.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionRequest(
      id: id,
      userId: map['userId'] as String? ?? '',
      requestedPlan: SubscriptionPlan.values.firstWhere(
        (p) => p.id == map['requestedPlan'],
        orElse: () => SubscriptionPlan.free,
      ),
      requestedAt: map['requestedAt'] != null
          ? DateTime.tryParse(map['requestedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'requestedPlan': requestedPlan.id,
      'status': 'pending',
      'requestedAt': requestedAt.toIso8601String(),
    };
  }
}
