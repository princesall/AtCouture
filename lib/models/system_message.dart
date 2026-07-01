/// Type de message système — détermine l'icône et le style d'affichage.
enum SystemMessageType {
  subscriptionApproved,
  subscriptionRejected,
  subscriptionExpired,
  subscriptionRenewed,
  accountCreated,
  accountDeactivated,
  accountReactivated,
}

/// Message SYSTÈME — généré automatiquement par l'application suite à une
/// action administrative (approbation/refus d'abonnement, expiration, etc.),
/// distinct des messages texte libres envoyés manuellement par l'admin.
/// Affiché avec un style particulier (icône, couleur) pour bien marquer
/// qu'il s'agit d'une notification automatique du système et non d'une
/// personne qui écrit.
class SystemMessage {
  const SystemMessage({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;

  /// UID du compte destinataire (le styliste/companyOwner concerné)
  final String userId;
  final SystemMessageType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  SystemMessage copyWith({bool? isRead}) => SystemMessage(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

  factory SystemMessage.subscriptionApproved({
    required String id,
    required String userId,
    required String planName,
  }) {
    return SystemMessage(
      id: id,
      userId: userId,
      type: SystemMessageType.subscriptionApproved,
      title: 'Abonnement approuvé ✅',
      body: 'Votre demande de passage au plan $planName a été approuvée par l\'administrateur. '
          'Toutes les fonctionnalités du plan $planName sont maintenant actives sur votre compte.',
      createdAt: DateTime.now(),
    );
  }

  factory SystemMessage.subscriptionRejected({
    required String id,
    required String userId,
    required String planName,
  }) {
    return SystemMessage(
      id: id,
      userId: userId,
      type: SystemMessageType.subscriptionRejected,
      title: 'Demande d\'abonnement refusée',
      body: 'Votre demande de passage au plan $planName n\'a pas été approuvée par l\'administrateur. '
          'Votre abonnement actuel reste inchangé. Vous pouvez contacter l\'administrateur pour plus '
          'd\'informations ou soumettre une nouvelle demande.',
      createdAt: DateTime.now(),
    );
  }

  factory SystemMessage.subscriptionExpired({
    required String id,
    required String userId,
    required String planName,
  }) {
    return SystemMessage(
      id: id,
      userId: userId,
      type: SystemMessageType.subscriptionExpired,
      title: 'Abonnement expiré ⚠️',
      body: 'Votre abonnement $planName a expiré. Vos fonctionnalités sont temporairement limitées au plan '
          'Gratuit. Toutes vos données (clients, commandes, couturiers) sont conservées intactes. '
          'Renouvelez votre abonnement pour retrouver immédiatement l\'ensemble de vos fonctionnalités.',
      createdAt: DateTime.now(),
    );
  }

  factory SystemMessage.subscriptionRenewed({
    required String id,
    required String userId,
    required String planName,
  }) {
    return SystemMessage(
      id: id,
      userId: userId,
      type: SystemMessageType.subscriptionRenewed,
      title: 'Abonnement renouvelé ✅',
      body: 'Votre abonnement $planName a été renouvelé avec succès. Toutes vos fonctionnalités et données '
          'sont de nouveau pleinement accessibles.',
      createdAt: DateTime.now(),
    );
  }

  factory SystemMessage.accountCreated({
    required String id,
    required String userId,
    required String creatorName,
    required String role,
  }) {
    return SystemMessage(
      id: id,
      userId: userId,
      type: SystemMessageType.accountCreated,
      title: 'Bienvenue sur StyleConnect 🎉',
      body: 'Votre compte $role a été créé par $creatorName. Vous pouvez dès maintenant vous connecter '
          'avec les identifiants qui vous ont été communiqués.',
      createdAt: DateTime.now(),
    );
  }
}
