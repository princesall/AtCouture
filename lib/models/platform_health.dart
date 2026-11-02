import 'package:flutter/material.dart';

import 'user_role.dart';

/// Catalogue des fonctionnalités suivies par la télémétrie d'usage.
/// Les clés sont stables : ne jamais les renommer sans migration, elles
/// servent de clé d'agrégation dans `featureEvents`.
abstract final class FeatureKeys {
  static const authRegister = 'auth.register';
  static const ordersCreate = 'orders.create';
  static const ordersStatus = 'orders.status';
  static const ordersPayments = 'orders.payments';
  static const clientsCreate = 'clients.create';
  static const measurementsSave = 'measurements.save';
  static const staffCreate = 'staff.create';
  static const subscriptionRequest = 'subscription.request';
  static const supportMessage = 'support.message';
  static const pdfExport = 'pdf.export';
}

class FeatureInfo {
  const FeatureInfo({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

abstract final class FeatureCatalog {
  static const Map<String, FeatureInfo> all = {
    FeatureKeys.ordersCreate: FeatureInfo(
      label: 'Création de commande',
      description: 'Nouvelle commande enregistrée dans un atelier',
      icon: Icons.add_shopping_cart_rounded,
    ),
    FeatureKeys.ordersStatus: FeatureInfo(
      label: 'Changement de statut',
      description: 'Commande passée en cours, terminée ou en problème',
      icon: Icons.swap_horiz_rounded,
    ),
    FeatureKeys.ordersPayments: FeatureInfo(
      label: 'Encaissement',
      description: 'Acompte ou versement enregistré sur une commande',
      icon: Icons.payments_rounded,
    ),
    FeatureKeys.clientsCreate: FeatureInfo(
      label: 'Fiche client',
      description: 'Création d\'un nouveau client',
      icon: Icons.person_add_alt_rounded,
    ),
    FeatureKeys.measurementsSave: FeatureInfo(
      label: 'Mensurations',
      description: 'Mesures enregistrées ou mises à jour',
      icon: Icons.straighten_rounded,
    ),
    FeatureKeys.staffCreate: FeatureInfo(
      label: 'Comptes staff',
      description: 'Création d\'un chef d\'atelier ou d\'un couturier',
      icon: Icons.group_add_rounded,
    ),
    FeatureKeys.subscriptionRequest: FeatureInfo(
      label: 'Demande d\'abonnement',
      description: 'Demande de passage à un plan payant',
      icon: Icons.workspace_premium_rounded,
    ),
    FeatureKeys.supportMessage: FeatureInfo(
      label: 'Support',
      description: 'Message envoyé à l\'équipe StyleConnect',
      icon: Icons.forum_rounded,
    ),
    FeatureKeys.pdfExport: FeatureInfo(
      label: 'Export PDF',
      description: 'Devis ou fiche de commande exporté en PDF',
      icon: Icons.picture_as_pdf_rounded,
    ),
    FeatureKeys.authRegister: FeatureInfo(
      label: 'Inscription',
      description: 'Création d\'un compte Chef Styliste',
      icon: Icons.person_add_rounded,
    ),
  };

  static FeatureInfo infoFor(String key) =>
      all[key] ??
      const FeatureInfo(
        label: 'Fonctionnalité inconnue',
        description: 'Clé non répertoriée dans le catalogue',
        icon: Icons.extension_rounded,
      );
}

/// Statistiques globales des comptes de la plateforme.
class PlatformUserStats {
  const PlatformUserStats({
    required this.total,
    required this.byRole,
    required this.active30d,
    required this.new30d,
  });

  final int total;
  final Map<UserRole, int> byRole;
  final int active30d;
  final int new30d;

  int count(UserRole role) => byRole[role] ?? 0;

  static const empty = PlatformUserStats(
    total: 0,
    byRole: {},
    active30d: 0,
    new30d: 0,
  );

  PlatformUserStats copyWith({
    int? total,
    Map<UserRole, int>? byRole,
    int? active30d,
    int? new30d,
  }) =>
      PlatformUserStats(
        total: total ?? this.total,
        byRole: byRole ?? this.byRole,
        active30d: active30d ?? this.active30d,
        new30d: new30d ?? this.new30d,
      );
}

enum QualityIssueType {
  missingAtelier,
  missingPhone,
  duplicateEmail,
  inactive30,
  inactive60,
  inactive90,
  dormantOrder,
}

extension QualityIssueTypeX on QualityIssueType {
  String get label => switch (this) {
        QualityIssueType.missingAtelier => 'Compte sans atelier',
        QualityIssueType.missingPhone => 'Téléphone manquant',
        QualityIssueType.duplicateEmail => 'Email en doublon',
        QualityIssueType.inactive30 => 'Inactif 30–59 jours',
        QualityIssueType.inactive60 => 'Inactif 60–89 jours',
        QualityIssueType.inactive90 => 'Inactif 90+ jours',
        QualityIssueType.dormantOrder => 'Commande sans activité',
      };

  String get description => switch (this) {
        QualityIssueType.missingAtelier =>
          'Un styliste, un chef d\'atelier ou un couturier doit être rattaché à un atelier.',
        QualityIssueType.missingPhone =>
          'Sans téléphone, impossible de relancer le compte par WhatsApp ou SMS.',
        QualityIssueType.duplicateEmail =>
          'Deux comptes partagent le même email : risque de connexion au mauvais compte.',
        QualityIssueType.inactive30 =>
          'Aucune connexion depuis 30 à 59 jours.',
        QualityIssueType.inactive60 =>
          'Aucune connexion depuis 60 à 89 jours : candidat à une relance.',
        QualityIssueType.inactive90 =>
          'Aucune connexion depuis 90 jours ou plus : risque de churn élevé.',
        QualityIssueType.dormantOrder =>
          'Commande non terminée dont le dernier changement de statut date de plus de 14 jours.',
      };

  IconData get icon => switch (this) {
        QualityIssueType.missingAtelier => Icons.store_mall_directory_outlined,
        QualityIssueType.missingPhone => Icons.phone_disabled_rounded,
        QualityIssueType.duplicateEmail => Icons.content_copy_rounded,
        QualityIssueType.inactive30 => Icons.schedule_rounded,
        QualityIssueType.inactive60 => Icons.hourglass_bottom_rounded,
        QualityIssueType.inactive90 => Icons.person_off_outlined,
        QualityIssueType.dormantOrder => Icons.receipt_long_outlined,
      };

  int get severity => switch (this) {
        QualityIssueType.duplicateEmail => 3,
        QualityIssueType.missingAtelier => 2,
        QualityIssueType.dormantOrder => 2,
        QualityIssueType.inactive90 => 2,
        _ => 1,
      };
}

class QualityIssue {
  const QualityIssue({
    required this.type,
    required this.title,
    required this.subtitle,
    this.userId,
    this.orderId,
    this.days,
  });

  final QualityIssueType type;
  final String title;
  final String subtitle;
  final String? userId;
  final String? orderId;
  final int? days;
}

class DataQualityReport {
  const DataQualityReport({
    required this.issues,
    required this.usersScanned,
    required this.ordersScanned,
  });

  final List<QualityIssue> issues;
  final int usersScanned;
  final int ordersScanned;

  int get total => issues.length;

  int count(QualityIssueType type) =>
      issues.where((issue) => issue.type == type).length;

  List<QualityIssue> ofType(QualityIssueType type) =>
      issues.where((issue) => issue.type == type).toList();

  List<QualityIssue> get sortedBySeverity {
    final copy = [...issues];
    copy.sort((a, b) {
      final bySeverity = b.type.severity.compareTo(a.type.severity);
      if (bySeverity != 0) return bySeverity;
      return (b.days ?? 0).compareTo(a.days ?? 0);
    });
    return copy;
  }

  static const empty = DataQualityReport(
    issues: [],
    usersScanned: 0,
    ordersScanned: 0,
  );
}

class PlatformErrorRecord {
  const PlatformErrorRecord({
    required this.id,
    required this.message,
    required this.createdAt,
    this.stack,
    this.context,
    this.platform,
    this.appVersion,
    this.userId,
  });

  final String id;
  final String message;
  final DateTime createdAt;
  final String? stack;
  final String? context;
  final String? platform;
  final String? appVersion;
  final String? userId;
}

class FeatureUsageStat {
  const FeatureUsageStat({
    required this.feature,
    required this.events,
    required this.uniqueUsers,
    required this.last7,
    required this.previous7,
    this.lastUsedAt,
  });

  final String feature;
  final int events;
  final int uniqueUsers;
  final int last7;
  final int previous7;
  final DateTime? lastUsedAt;

  FeatureInfo get info => FeatureCatalog.infoFor(feature);

  /// Variation du nombre d'événements entre les 7 derniers jours et les 7
  /// précédents. Null si la base de comparaison est nulle.
  double? get trend {
    if (previous7 == 0) return last7 == 0 ? null : 1;
    return (last7 - previous7) / previous7;
  }
}

class FeatureUsageReport {
  const FeatureUsageReport({
    required this.stats,
    required this.totalEvents,
    required this.uniqueUsers,
    required this.windowDays,
    required this.generatedAt,
  });

  final List<FeatureUsageStat> stats;
  final int totalEvents;
  final int uniqueUsers;
  final int windowDays;
  final DateTime generatedAt;

  FeatureUsageStat? get topFeature =>
      stats.isEmpty ? null : stats.first;

  static FeatureUsageReport empty(int windowDays) => FeatureUsageReport(
        stats: const [],
        totalEvents: 0,
        uniqueUsers: 0,
        windowDays: windowDays,
        generatedAt: DateTime.now(),
      );
}

class StorageUsage {
  const StorageUsage({this.bytes, this.updatedAt, this.note});

  final int? bytes;
  final DateTime? updatedAt;
  final String? note;

  bool get available => bytes != null;
}

enum PlatformJobState { ok, warning, error, notConfigured }

extension PlatformJobStateX on PlatformJobState {
  String get label => switch (this) {
        PlatformJobState.ok => 'OK',
        PlatformJobState.warning => 'À surveiller',
        PlatformJobState.error => 'En erreur',
        PlatformJobState.notConfigured => 'Non configuré',
      };
}

class PlatformJobStatus {
  const PlatformJobStatus({
    required this.id,
    required this.label,
    required this.description,
    required this.state,
    this.lastRunAt,
    this.message,
  });

  final String id;
  final String label;
  final String description;
  final PlatformJobState state;
  final DateTime? lastRunAt;
  final String? message;
}

class PlatformSnapshot {
  const PlatformSnapshot({
    required this.users,
    required this.quality,
    required this.errors,
    required this.usage,
    required this.storage,
    required this.jobs,
    required this.appVersion,
    required this.generatedAt,
    this.warnings = const [],
  });

  final PlatformUserStats users;
  final DataQualityReport quality;
  final List<PlatformErrorRecord> errors;
  final FeatureUsageReport usage;
  final StorageUsage storage;
  final List<PlatformJobStatus> jobs;
  final String appVersion;
  final DateTime generatedAt;
  final List<String> warnings;
}
