import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription_plan.dart';
import '../models/system_message.dart';
import 'company_service.dart';
import 'firebase_service.dart';

/// Statut de transition d'un compte, calculé par rapport à son plan
/// précédent connu. Affiché dans l'admin pour suivre qui vient de monter
/// ou descendre de gamme.
enum PlanTransitionStatus { upgraded, downgraded, unchanged, newAccount }

/// Service central du cycle de vie des abonnements. Se branche sur
/// FirebaseService.isAvailable comme les autres services : écrit dans
/// systemMessages/{id} (et met à jour subscriptionRequests/{id}.status) en
/// mode Firebase, ou reste en mémoire en mode démo.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  /// Messages système en mémoire, indexés par userId — source de vérité en
  /// mode démo, cache tenu à jour par écoute Firestore en mode réel.
  final Map<String, List<SystemMessage>> _systemMessages = {};

  /// Historique du dernier plan connu par utilisateur, pour calculer
  /// upgrade/downgrade dans l'admin.
  final Map<String, SubscriptionPlan> _lastKnownPlan = {};

  int _messageIdCounter = 1000;
  String _nextMessageId() => 'sysmsg_${_messageIdCounter++}';

  final Set<String> _syncedUsers = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = [];

  void _ensureUserMessagesSynced(String userId) {
    if (!FirebaseService.isAvailable) return;
    if (!_syncedUsers.add(userId)) return;

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('systemMessages')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snap) {
        _systemMessages[userId] = snap.docs.map((d) => SystemMessage.fromMap(d.data(), d.id)).toList();
      }),
    );
  }

  // ── Lecture ──────────────────────────────────────────────────────────────

  List<SystemMessage> systemMessagesFor(String userId) {
    _ensureUserMessagesSynced(userId);
    return List.unmodifiable((_systemMessages[userId] ?? [])..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  int unreadSystemMessagesCount(String userId) {
    _ensureUserMessagesSynced(userId);
    return (_systemMessages[userId] ?? []).where((m) => !m.isRead).length;
  }

  Future<void> markSystemMessageRead(String userId, String messageId) async {
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('systemMessages').doc(messageId).update({'isRead': true});
      return;
    }

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
  ///  4. Marque la demande (subscriptionRequests/{requestDocId}) comme
  ///     approuvée, en mode Firebase uniquement
  ///  5. Si le plan accordé est Entreprise, crée le document Company associé
  ///     pour que le compte apparaisse dans la liste "Entreprises" de l'admin
  Future<void> approveSubscriptionRequest({
    required String userId,
    required String userFullName,
    required String userAtelierId,
    required String userAtelierName,
    required SubscriptionPlan requestedPlan,
    required DateTime newExpiryDate,
    required Future<void> Function(SubscriptionPlan plan, DateTime expiresAt) applyPlanToAccount,
    String? requestDocId,
  }) async {
    if (!FirebaseService.isAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    await applyPlanToAccount(requestedPlan, newExpiryDate);
    _lastKnownPlan[userId] = requestedPlan;

    await _sendSystemMessage(SystemMessage.subscriptionApproved(
      id: _nextMessageId(),
      userId: userId,
      planName: requestedPlan.name,
    ));

    if (FirebaseService.isAvailable && requestDocId != null) {
      await FirebaseFirestore.instance.collection('subscriptionRequests').doc(requestDocId).update({
        'status': 'approved',
        'decidedAt': DateTime.now().toIso8601String(),
      });
    }

    // Transition vers Entreprise : créer automatiquement la structure
    // Company pour que ce compte apparaisse dans l'onglet Entreprises admin.
    // On réutilise le MÊME atelierId qu'avant l'upgrade pour que les clients/
    // commandes déjà créés restent visibles (voir createCompanyForNewOwner).
    // NOTE : pas de vérification "déjà une entreprise ?" ici — companyForOwner
    // ne lit que le cache local (_companies), jamais synchronisé à cet
    // endroit en mode Firebase, donc toujours faussement vide à cet instant.
    // La vraie protection anti-doublon vit DANS createCompanyForNewOwner, qui
    // relit Firestore en direct avant de créer quoi que ce soit.
    if (requestedPlan == SubscriptionPlan.enterprise) {
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
    String? requestDocId,
  }) async {
    if (!FirebaseService.isAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    await _sendSystemMessage(SystemMessage.subscriptionRejected(
      id: _nextMessageId(),
      userId: userId,
      planName: requestedPlan.name,
    ));

    if (FirebaseService.isAvailable && requestDocId != null) {
      await FirebaseFirestore.instance.collection('subscriptionRequests').doc(requestDocId).update({
        'status': 'rejected',
        'decidedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Renouvellement manuel par l'admin (prolonge la date d'expiration).
  Future<void> renewSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required DateTime newExpiryDate,
    required Future<void> Function(SubscriptionPlan plan, DateTime expiresAt) applyPlanToAccount,
  }) async {
    if (!FirebaseService.isAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    await applyPlanToAccount(plan, newExpiryDate);
    _lastKnownPlan[userId] = plan;
    await _sendSystemMessage(SystemMessage.subscriptionRenewed(
      id: _nextMessageId(),
      userId: userId,
      planName: plan.name,
    ));
  }

  Future<void> _sendSystemMessage(SystemMessage message) async {
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('systemMessages').doc().set(message.toMap());
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 150));
    _systemMessages.putIfAbsent(message.userId, () => []).add(message);
  }

  /// Enregistre une notification d'expiration (appelé automatiquement quand
  /// l'app détecte qu'un plan vient d'expirer pour ce compte — voir
  /// AuthProvider qui vérifie planExpiresAt à chaque connexion).
  Future<void> notifyExpiration({required String userId, required SubscriptionPlan expiredPlan}) async {
    await _sendSystemMessage(SystemMessage.subscriptionExpired(
      id: _nextMessageId(),
      userId: userId,
      planName: expiredPlan.name,
    ));
  }
}
