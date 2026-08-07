import '../../models/subscription_plan.dart';

/// Centralise TOUTES les règles d'accès dérivées du plan d'abonnement.
/// Utilisé côté UI (afficher/masquer un bouton) ET sert de référence pour
/// écrire les règles Firestore équivalentes (voir firestore.rules).
///
/// Règle d'or : si une permission change ici, le comportement de l'app entière
/// change automatiquement — aucune logique de plan ne doit être dupliquée ailleurs.
///
/// GESTION DE L'EXPIRATION : `PlanPermissions.of()` ne doit JAMAIS être
/// appelé directement avec `user.plan` brut. Utilisez TOUJOURS
/// `PlanPermissions.forUser(user)` qui calcule le plan EFFECTIF en tenant
/// compte de `planExpiresAt`. Si l'abonnement payant est expiré, le compte
/// retombe automatiquement sur les droits du plan Gratuit — sans jamais
/// supprimer la moindre donnée (clients, commandes, couturiers restent
/// intacts en base, seules les fonctionnalités sont reverrouillées). Dès que
/// l'admin renouvelle/prolonge `planExpiresAt`, l'utilisateur retrouve
/// immédiatement l'intégralité de ses droits et de ses données.
class PlanPermissions {
  const PlanPermissions._(this.plan, {required this.isExpired, this.originalPlan});

  /// Construit les permissions à partir d'un plan brut, SANS vérifier
  /// l'expiration. Réservé aux cas où l'expiration est déjà gérée en amont
  /// (ex: affichage admin où on veut voir le plan "nominal"). Pour tout
  /// calcul de droits réels côté utilisateur, préférez `forUser`.
  factory PlanPermissions.of(SubscriptionPlan plan) =>
      PlanPermissions._(plan, isExpired: false);

  /// Calcule les permissions RÉELLEMENT actives pour un utilisateur, en
  /// tenant compte de la date d'expiration de son abonnement.
  /// - Plan Gratuit : jamais d'expiration, toujours actif.
  /// - Plan payant sans date d'expiration définie : considéré actif (compte
  ///   géré manuellement par l'admin, pas encore de date fixée).
  /// - Plan payant avec date dépassée : rétrogradation automatique vers
  ///   Gratuit pour les FONCTIONNALITÉS uniquement.
  factory PlanPermissions.forUser({
    required SubscriptionPlan plan,
    required DateTime? planExpiresAt,
  }) {
    final expired = plan != SubscriptionPlan.free &&
        planExpiresAt != null &&
        planExpiresAt.isBefore(DateTime.now());

    return PlanPermissions._(
      expired ? SubscriptionPlan.free : plan,
      isExpired: expired,
      originalPlan: expired ? plan : null,
    );
  }

  /// Plan EFFECTIF (celui qui détermine réellement les droits actuels)
  final SubscriptionPlan plan;

  /// True si un plan payant a expiré et que l'utilisateur est actuellement
  /// rétrogradé vers Gratuit (mais conserve toutes ses données).
  final bool isExpired;

  /// Si expiré : le plan d'origine que l'utilisateur retrouvera au renouvellement
  final SubscriptionPlan? originalPlan;

  // ── Multi-ateliers (Entreprise uniquement) ──────────────────────────────
  bool get canManageMultipleAteliers => plan == SubscriptionPlan.enterprise;
  bool get canCreateAtelierHead => plan == SubscriptionPlan.enterprise;
  bool get canViewConsolidatedDashboard => plan == SubscriptionPlan.enterprise;

  /// Nombre maximum d'ateliers gérables (illimité pour Entreprise, 1 sinon)
  int get maxAteliers => plan == SubscriptionPlan.enterprise ? -1 : 1;
  bool get isUnlimitedAteliers => maxAteliers < 0;

  // ── Couturiers ───────────────────────────────────────────────────────────
  int get maxTailorsPerAtelier => plan.maxTailors;
  bool get isUnlimitedTailors => plan.isUnlimitedTailors;

  // ── Clients ──────────────────────────────────────────────────────────────
  int get maxClients => plan.maxClients;
  bool get isUnlimitedClients => plan.isUnlimitedClients;

  // ── Commandes ─────────────────────────────────────────────────────────────
  int get maxOrders => plan.maxOrders;
  bool get isUnlimitedOrders => plan.isUnlimitedOrders;

  // ── Photos ───────────────────────────────────────────────────────────────
  int get maxPhotosPerOrder => plan.maxPhotosPerOrder;
  bool get isUnlimitedPhotos => plan.isUnlimitedPhotos;

  // ── Fonctionnalités ──────────────────────────────────────────────────────
  bool get hasMessaging => plan.hasMessaging;
  bool get hasStatistics => plan.hasStatistics;
  bool get hasPushNotifications => plan.hasPushNotifications;
  bool get hasPrioritySupport => plan.hasPrioritySupport;
  bool get hasSavedMeasurements => plan.hasSavedMeasurements;
  bool get hasCalendar => plan.hasCalendar;
  bool get hasPdfExport => plan.hasPdfExport;
  bool get hasReminders => plan.hasReminders;
  bool get hasQuotes => plan.hasQuotes;
  bool get hasApiExport => plan.hasApiExport;
  bool get hasDedicatedManager => plan.hasDedicatedManager;
  bool get hasCustomization => plan.hasCustomization;
  int get historyMonths => plan.historyMonths;
  bool get hasUnlimitedHistory => plan.historyMonths < 0;

  // ── Libellés d'upsell (affichés sur boutons verrouillés) ────────────────
  String get atelierLockedMessage => isExpired
      ? 'Votre abonnement Entreprise a expiré. Renouvelez-le pour retrouver la gestion multi-ateliers.'
      : 'Disponible avec le plan Entreprise — gérez plusieurs ateliers depuis un seul compte';

  String get statisticsLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour retrouver les statistiques avancées.'
      : 'Statistiques avancées disponibles à partir du plan Pro';

  String get messagingLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour retrouver la messagerie interne.'
      : 'Messagerie interne disponible à partir du plan Pro';

  String get photosLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour retrouver la galerie photos illimitée.'
      : 'Photos disponibles à partir du plan Starter';

  String get tailorLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour ajouter plus de couturiers.'
      : 'Ajout de couturiers disponible à partir du plan Starter';

  String get ordersLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour créer plus de commandes.'
      : 'Commandes illimitées disponibles à partir du plan Starter';

  String get measurementsLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour sauvegarder les mensurations.'
      : 'Mensurations sauvegardées disponibles à partir du plan Starter';

  String get calendarLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour accéder au calendrier.'
      : 'Calendrier de livraisons disponible à partir du plan Pro';

  String get pdfExportLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour exporter en PDF.'
      : 'Export PDF disponible à partir du plan Pro';

  String get remindersLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour activer les rappels.'
      : 'Rappels automatiques disponibles à partir du plan Pro';

  String get quotesLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour créer des devis.'
      : 'Devis PDF disponibles à partir du plan Pro';

  String get apiExportLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour accéder à l\'API d\'export.'
      : 'API d\'export disponible avec le plan Entreprise';

  String get customizationLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour personnaliser l\'app.'
      : 'Personnalisation disponible avec le plan Entreprise';

  String get dedicatedManagerLockedMessage => isExpired
      ? 'Votre abonnement a expiré. Renouvelez-le pour retrouver votre gestionnaire dédié.'
      : 'Gestionnaire dédié disponible avec le plan Entreprise';

  String get canAddAtelierMessage {
    if (isUnlimitedAteliers) return '';
    return 'Limite de $maxAteliers atelier${maxAteliers > 1 ? 's' : ''} atteinte pour votre plan.';
  }

  String get canAddTailorMessage {
    if (isUnlimitedTailors) return '';
    return 'Limite de $maxTailorsPerAtelier couturier${maxTailorsPerAtelier > 1 ? 's' : ''} atteinte pour votre plan.';
  }

  String get canAddClientMessage {
    if (isUnlimitedClients) return '';
    return 'Limite de $maxClients clients atteinte pour votre plan.';
  }

  String get canAddOrderMessage {
    if (isUnlimitedOrders) return '';
    return 'Limite de $maxOrders commandes atteinte pour votre plan.';
  }

  String get canAddPhotoMessage {
    if (isUnlimitedPhotos) return '';
    return 'Limite de $maxPhotosPerOrder photo${maxPhotosPerOrder > 1 ? 's' : ''} par commande atteinte pour votre plan.';
  }

  /// Vérifie si on peut ajouter un Nème couturier dans un atelier donné
  bool canAddTailor(int currentCount) =>
      isUnlimitedTailors || currentCount < maxTailorsPerAtelier;

  /// Vérifie si on peut ajouter un Nème client
  bool canAddClient(int currentCount) =>
      isUnlimitedClients || currentCount < maxClients;

  /// Vérifie si on peut ajouter un Nème atelier (Entreprise = illimité, sinon 1 max)
  bool canAddAtelier(int currentCount) =>
      isUnlimitedAteliers || currentCount < maxAteliers;

  /// Vérifie si on peut ajouter une Nème commande
  bool canAddOrder(int currentCount) =>
      isUnlimitedOrders || currentCount < maxOrders;

  /// Vérifie si on peut ajouter une Nème photo à une commande
  bool canAddPhoto(int currentCount) =>
      isUnlimitedPhotos || currentCount < maxPhotosPerOrder;
}
