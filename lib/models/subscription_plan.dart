import '../core/utils/formatters.dart';

enum SubscriptionPlan {
  free(
    name: 'Gratuit',
    price: 0,
    maxTailors: 1,
    maxClients: 20,
    historyMonths: 0,
    hasMessaging: false,
    hasStatistics: false,
    hasMultiplePhotos: false,
    hasPushNotifications: false,
    hasMultipleBranches: false,
    hasPrioritySupport: false,
  ),
  starter(
    name: 'Starter',
    price: 5000,
    maxTailors: 3,
    maxClients: 100,
    historyMonths: 3,
    hasMessaging: false,
    hasStatistics: false,
    hasMultiplePhotos: true,
    hasPushNotifications: true,
    hasMultipleBranches: false,
    hasPrioritySupport: false,
  ),
  pro(
    name: 'Pro',
    price: 12000,
    maxTailors: -1,
    maxClients: -1,
    historyMonths: -1,
    hasMessaging: true,
    hasStatistics: true,
    hasMultiplePhotos: true,
    hasPushNotifications: true,
    hasMultipleBranches: false,
    hasPrioritySupport: false,
  ),
  enterprise(
    name: 'Entreprise',
    price: 25000,
    maxTailors: -1,
    maxClients: -1,
    historyMonths: -1,
    hasMessaging: true,
    hasStatistics: true,
    hasMultiplePhotos: true,
    hasPushNotifications: true,
    hasMultipleBranches: true,
    hasPrioritySupport: true,
  );

  const SubscriptionPlan({
    required this.name,
    required this.price,
    required this.maxTailors,
    required this.maxClients,
    required this.historyMonths,
    required this.hasMessaging,
    required this.hasStatistics,
    required this.hasMultiplePhotos,
    required this.hasPushNotifications,
    required this.hasMultipleBranches,
    required this.hasPrioritySupport,
  });

  final String name;
  final int price;
  final int maxTailors;
  final int maxClients;
  final int historyMonths;
  final bool hasMessaging;
  final bool hasStatistics;
  final bool hasMultiplePhotos;
  final bool hasPushNotifications;
  final bool hasMultipleBranches;
  final bool hasPrioritySupport;

  bool get isUnlimitedTailors => maxTailors < 0;
  bool get isUnlimitedClients => maxClients < 0;

  String get priceLabel {
    if (price == 0) return 'Gratuit';
    return '${Formatters.formatCurrency(price)}/mois';
  }

  String get tailorsLabel =>
      isUnlimitedTailors ? 'Illimité' : '$maxTailors couturier${maxTailors > 1 ? 's' : ''}';

  String get clientsLabel =>
      isUnlimitedClients ? 'Illimité' : '$maxClients clients max';
}
