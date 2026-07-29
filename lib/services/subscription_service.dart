import '../models/subscription_plan.dart';
import '../models/system_message.dart';
import 'company_service.dart';

/// Statut de transition d'un compte, calculé par rapport à son plan
/// précédent connu. Affiché dans l'admin pour suivre qui vient de monter
/// ou descendre de gamme.
enum PlanTransitionStatus { upgraded, downgraded, unchanged, newAccount }

/// Service central du cycle de vie des abonnements. En mode démo, persiste
/// en mémoire. Quand Firebase sera branché, ces méthodes deviendront des
/// transactions Firestore qui :
///   1. Mettent à jour users/{uid}.plan + planExpiresAt
///   2. Créent un document dans systemMessages/{id} pour notifier l'utilisateur
///   3. Mettent à jour subscriptionRequests/{id}.status
/// Le tout dans une seule transaction atomique pour garantir la cohérence.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  /// Messages système en mémoire, indexés par userId
  final Map<String, List<SystemMessage>> _systemMessages = {};

  /// Historique du dernier plan connu par utilisateur, pour calculer
  /// upgrade/downgrade dans l'admin.
  final Map<String, SubscriptionPlan> _lastKnownPlan = {};

  int _messageIdCounter = 1000;
  String _nextMessageId() => 'sysmsg_${_messageIdCounter++}';

  // ── Lecture ──────────────────────────────────────────────────────────────

  List<SystemMessage> systemMessagesFor(String userId) =>
      List.unmodifiable((_systemMessages[userId] ?? [])..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  int unreadSystemMessagesCount(String userId) =>
      (_systemMessages[userId] ?? []).where((m) => !m.isRead).length;

  Future<void> markSystemMessageRead(String userId, String messageId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final list = _systemMessages[userId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx != -1) list[idx] = list[idx].copyWith(isRead: true);
  }

  /// Calcule si ce changement de plan est une montée, une descente, ou neutre.
  PlanTransitionStatus transitionStatusFor(String userId, SubscriptionPlan newPlan) {
    final last = _lastKnownPlan[userId];
    if (last == null) return PlanTransitionStatus.newAccount;
    if (newPlan.price > last.price) return PlanTransitionStatus.upgraded;
    if (newPlan.price < last.price) return PlanTransitionStatus.downgraded;
    return PlanTransitionStatus.unchanged;
  }

  // ── Actions admin : approbation / refus ────────────────────────────────

  /// Approuve une demande de changement de plan :
  ///  1. Active réellement le nouveau plan sur le compte (via callback fourni
  ///     par l'appelant, qui sait où vit le AppUser en mémoire/démo)
  ///  2. Enregistre la transition (upgrade/downgrade) pour affichage admin
  ///  3. Envoie un message SYSTÈME automatique au compte concerné
  ///  4. Si le plan accordé est Entreprise, crée le document Company associé
  ///     pour que le compte apparaisse dans la liste "Entreprises" de l'admin
  Future<void> approveSubscriptionRequest({
    required String userId,
    required String userFullName,
    required String userAtelierId,
    required String userAtelierName,
    required SubscriptionPlan requestedPlan,
    required DateTime newExpiryDate,
    required Future<void> Function(SubscriptionPlan plan, DateTime expiresAt) applyPlanToAccount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    await applyPlanToAccount(requestedPlan, newExpiryDate);
    _lastKnownPlan[userId] = requestedPlan;

    _addSystemMessage(SystemMessage.subscriptionApproved(
      id: _nextMessageId(),
      userId: userId,
      planName: requestedPlan.name,
    ));

    // Transition vers Entreprise : créer automatiquement la structure
    // Company pour que ce compte apparaisse dans l'onglet Entreprises admin.
    // On réutilise le MÊME atelierId qu'avant l'upgrade pour que les clients/
    // commandes déjà créés restent visibles (voir createCompanyForNewOwner).
    if (requestedPlan == SubscriptionPlan.enterprise &&
        CompanyService.instance.companyForOwner(userId) == null) {
      await CompanyService.instance.createCompanyForNewOwner(
        ownerId: userId,
        ownerName: userFullName,
        personalAtelierId: userAtelierId,
        personalAtelierName: userAtelierName,
      );
    }

    // Transition Entreprise → autre plan : le compte sort de la vue
    // "Entreprises" mais ses ateliers existants sont conservés intacts en
    // base (juste verrouillés tant que le plan n'est pas Entreprise à nouveau).
  }

  /// Refuse une demande : aucune modification du plan, mais envoie un
  /// message SYSTÈME explicite au compte concerné.
  Future<void> rejectSubscriptionRequest({
    required String userId,
    required SubscriptionPlan requestedPlan,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _addSystemMessage(SystemMessage.subscriptionRejected(
      id: _nextMessageId(),
      userId: userId,
      planName: requestedPlan.name,
    ));
  }

  /// Renouvellement manuel par l'admin (prolonge la date d'expiration).
  Future<void> renewSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required DateTime newExpiryDate,
    required void Function(SubscriptionPlan plan, DateTime expiresAt) applyPlanToAccount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    applyPlanToAccount(plan, newExpiryDate);
    _lastKnownPlan[userId] = plan;
    _addSystemMessage(SystemMessage.subscriptionRenewed(
      id: _nextMessageId(),
      userId: userId,
      planName: plan.name,
    ));
  }

  void _addSystemMessage(SystemMessage message) {
    _systemMessages.putIfAbsent(message.userId, () => []).add(message);
  }

  /// Enregistre une notification d'expiration (appelé automatiquement quand
  /// l'app détecte qu'un plan vient d'expirer pour ce compte — voir
  /// AuthProvider qui vérifie planExpiresAt à chaque connexion).
  Future<void> notifyExpiration({required String userId, required SubscriptionPlan expiredPlan}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    _addSystemMessage(SystemMessage.subscriptionExpired(
      id: _nextMessageId(),
      userId: userId,
      planName: expiredPlan.name,
    ));
  }
}
