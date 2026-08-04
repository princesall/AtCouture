import '../core/utils/formatters.dart';

enum SubscriptionPlan {
  free(
    name: 'Découverte',
    price: 0,
    maxTailors: 1,
    maxClients: 20,
    maxOrders: 20,
    maxPhotosPerOrder: 1,
    historyMonths: 1,
    // Exception demandée : même en Découverte, un styliste doit pouvoir
    // prendre et sauvegarder les mensurations de ses clients.
    hasSavedMeasurements: true,
    hasMessaging: false,
    hasStatistics: false,
    hasPushNotifications: false,
    hasCalendar: false,
    hasPdfExport: false,
    hasReminders: false,
    hasQuotes: false,
    hasApiExport: false,
    hasDedicatedManager: false,
    hasCustomization: false,
    hasMultipleBranches: false,
    hasPrioritySupport: false,
  ),
  starter(
    name: 'Starter',
    price: 5000,
    maxTailors: 5,
    maxClients: 100,
    maxOrders: -1,
    maxPhotosPerOrder: 3,
    historyMonths: 6,
    hasSavedMeasurements: true,
    hasMessaging: false,
    hasStatistics: true, // basiques
    hasPushNotifications: true,
    hasCalendar: false,
    hasPdfExport: false,
    hasReminders: false,
    hasQuotes: false,
    hasApiExport: false,
    hasDedicatedManager: false,
    hasCustomization: false,
    hasMultipleBranches: false,
    hasPrioritySupport: false,
  ),
  pro(
    name: 'Pro',
    price: 12000,
    maxTailors: 20,
    maxClients: -1,
    maxOrders: -1,
    maxPhotosPerOrder: 10,
    historyMonths: 24,
    hasSavedMeasurements: true,
    hasMessaging: true,
    hasStatistics: true, // avancées
    hasPushNotifications: true,
    hasCalendar: true,
    hasPdfExport: true,
    hasReminders: true,
    hasQuotes: true,
    hasApiExport: false,
    hasDedicatedManager: false,
    hasCustomization: false,
    hasMultipleBranches: false,
    hasPrioritySupport: true,
  ),
  enterprise(
    name: 'Entreprise',
    price: 25000,
    maxTailors: -1,
    maxClients: -1,
    maxOrders: -1,
    maxPhotosPerOrder: -1,
    historyMonths: -1,
    hasSavedMeasurements: true,
    hasMessaging: true,
    hasStatistics: true, // avancées + par atelier
    hasPushNotifications: true,
    hasCalendar: true,
    hasPdfExport: true,
    hasReminders: true,
    hasQuotes: true,
    hasApiExport: true,
    hasDedicatedManager: true,
    hasCustomization: true,
    hasMultipleBranches: true,
    hasPrioritySupport: true,
  );

  const SubscriptionPlan({
    required this.name,
    required this.price,
    required this.maxTailors,
    required this.maxClients,
    required this.maxOrders,
    required this.maxPhotosPerOrder,
    required this.historyMonths,
    required this.hasSavedMeasurements,
    required this.hasMessaging,
    required this.hasStatistics,
    required this.hasPushNotifications,
    required this.hasCalendar,
    required this.hasPdfExport,
    required this.hasReminders,
    required this.hasQuotes,
    required this.hasApiExport,
    required this.hasDedicatedManager,
    required this.hasCustomization,
    required this.hasMultipleBranches,
    required this.hasPrioritySupport,
  });

  final String name;

  /// Identifiant stable pour le stockage (Firestore, règles de sécurité) —
  /// contrairement à `name` (libellé affiché, en français, utilisé partout
  /// dans l'UI admin), ne doit jamais changer même si le libellé évolue.
  String get id => switch (this) {
        SubscriptionPlan.free => 'free',
        SubscriptionPlan.starter => 'starter',
        SubscriptionPlan.pro => 'pro',
        SubscriptionPlan.enterprise => 'enterprise',
      };

  final int price;
  final int maxTailors;
  final int maxClients;
  final int maxOrders;
  final int maxPhotosPerOrder;
  final int historyMonths;
  final bool hasSavedMeasurements;
  final bool hasMessaging;
  final bool hasStatistics;
  final bool hasPushNotifications;
  final bool hasCalendar;
  final bool hasPdfExport;
  final bool hasReminders;
  final bool hasQuotes;
  final bool hasApiExport;
  final bool hasDedicatedManager;
  final bool hasCustomization;
  final bool hasMultipleBranches;
  final bool hasPrioritySupport;

  bool get isUnlimitedTailors => maxTailors < 0;
  bool get isUnlimitedClients => maxClients < 0;
  bool get isUnlimitedOrders => maxOrders < 0;
  bool get isUnlimitedPhotos => maxPhotosPerOrder < 0;

  String get priceLabel {
    if (price == 0) return 'Gratuit';
    return '${Formatters.formatCurrency(price)}/mois';
  }

  String get tailorsLabel =>
      isUnlimitedTailors ? 'Illimité' : '$maxTailors couturier${maxTailors > 1 ? 's' : ''}';

  String get clientsLabel =>
      isUnlimitedClients ? 'Illimité' : '$maxClients clients max';

  String get ordersLabel =>
      isUnlimitedOrders ? 'Illimitées' : '$maxOrders commandes max';

  String get photosLabel =>
      isUnlimitedPhotos ? 'Illimitées' : '$maxPhotosPerOrder photo${maxPhotosPerOrder > 1 ? 's' : ''}';

  String get historyLabel =>
      historyMonths < 0 ? 'Illimité' : '$historyMonths mois';
}
