import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../data/admin_demo_data.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/platform_health.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'company_service.dart';
import 'feature_usage_service.dart';
import 'firebase_service.dart';
import 'order_service.dart';
import 'platform_config_service.dart';
import 'platform_telemetry_service.dart';

/// Agrège les indicateurs de santé, de qualité et d'adoption de la plateforme.
///
/// En mode Firebase, la console lit directement les collections `users`,
/// `orders`, `featureEvents` et `systemErrors` (l'admin y est autorisé par les
/// règles). En mode démo, les mêmes rapports sont reconstruits depuis les
/// stores en mémoire.
class PlatformHealthService {
  PlatformHealthService._();
  static final PlatformHealthService instance = PlatformHealthService._();

  static const _usageWindowDays = 30;
  static const _dormantOrderDays = 14;

  PlatformUserStats? _cachedUsers;
  DateTime? _usersCachedAt;
  PlatformSnapshot? _cachedSnapshot;
  DateTime? _snapshotCachedAt;

  Future<PlatformUserStats> loadUserStats({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _cachedUsers != null &&
        _usersCachedAt != null &&
        now.difference(_usersCachedAt!) < const Duration(seconds: 60)) {
      return _cachedUsers!;
    }

    PlatformUserStats stats;
    if (FirebaseService.isAvailable) {
      try {
        stats = await _loadUserStatsFromAggregates();
      } catch (error) {
        debugPrint('⚠ comptage utilisateurs via agrégats impossible : $error');
        final users = await _fetchAllUsers();
        stats = _computeUserStats(users);
      }
    } else {
      stats = _computeUserStats(_demoUsers());
    }

    _cachedUsers = stats;
    _usersCachedAt = now;
    return stats;
  }

  Future<PlatformSnapshot> loadSnapshot({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _cachedSnapshot != null &&
        _snapshotCachedAt != null &&
        now.difference(_snapshotCachedAt!) < const Duration(seconds: 30)) {
      return _cachedSnapshot!;
    }

    final warnings = <String>[];
    final config = PlatformConfigService.instance;

    final users = FirebaseService.isAvailable
        ? await _safeFetchUsers(warnings)
        : _demoUsers();
    final orders = FirebaseService.isAvailable
        ? await _safeFetchOrders(warnings)
        : OrderService.instance.allOrders;
    final errors = FirebaseService.isAvailable
        ? await _safeFetchErrors(warnings)
        : PlatformTelemetryService.instance.localErrors;
    final events = FirebaseService.isAvailable
        ? await _safeFetchFeatureEvents(warnings)
        : FeatureUsageService.instance.localEvents;

    final stats = _computeUserStats(users);
    _cachedUsers = stats;
    _usersCachedAt = now;

    final snapshot = PlatformSnapshot(
      users: stats,
      quality: _buildQuality(users, orders, now),
      errors: errors,
      usage: _buildUsage(events, now),
      storage: await _resolveStorage(warnings),
      jobs: config.jobs,
      appVersion: config.version,
      generatedAt: now,
      warnings: warnings,
    );

    _cachedSnapshot = snapshot;
    _snapshotCachedAt = now;
    return snapshot;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Utilisateurs
  // ───────────────────────────────────────────────────────────────────────────

  Future<PlatformUserStats> _loadUserStatsFromAggregates() async {
    final users = FirebaseFirestore.instance.collection('users');

    final total = (await users.count().get()).count ?? 0;

    final byRole = <UserRole, int>{};
    for (final role in UserRole.values) {
      final snapshot =
          await users.where('role', isEqualTo: role.name).count().get();
      byRole[role] = snapshot.count ?? 0;
    }

    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    final active =
        (await users.where('lastLoginAt', isGreaterThanOrEqualTo: cutoff).count().get())
                .count ??
            0;
    final newUsers =
        (await users.where('createdAt', isGreaterThanOrEqualTo: cutoff).count().get())
                .count ??
            0;

    return PlatformUserStats(
      total: total,
      byRole: byRole,
      active30d: active,
      new30d: newUsers,
    );
  }

  Future<List<AppUser>> _fetchAllUsers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .toList();
  }

  List<AppUser> _demoUsers() {
    final byId = <String, AppUser>{};
    for (final entry in AdminDemoData.stylists) {
      byId[entry.user.id] = entry.user;
    }
    for (final account in CompanyService.instance.allStaffAccounts) {
      byId[account.id] = account;
    }
    for (final account in AuthService.demoUsers) {
      byId[account.id] = account;
    }
    return byId.values.toList();
  }

  PlatformUserStats _computeUserStats(List<AppUser> users) {
    final byRole = <UserRole, int>{for (final role in UserRole.values) role: 0};
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    var active = 0;
    var newUsers = 0;

    for (final user in users) {
      byRole[user.role] = (byRole[user.role] ?? 0) + 1;

      final lastActivity = user.lastLoginAt ?? user.createdAt;
      if (lastActivity != null && lastActivity.isAfter(cutoff)) active++;

      final createdAt = user.createdAt;
      if (createdAt != null && createdAt.isAfter(cutoff)) newUsers++;
    }

    return PlatformUserStats(
      total: users.length,
      byRole: byRole,
      active30d: active,
      new30d: newUsers,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Qualité des données
  // ───────────────────────────────────────────────────────────────────────────

  DataQualityReport _buildQuality(
    List<AppUser> users,
    List<Order> orders,
    DateTime now,
  ) {
    final issues = <QualityIssue>[];
    final emailGroups = <String, List<AppUser>>{};

    for (final user in users) {
      final email = user.email.trim().toLowerCase();
      if (email.isNotEmpty) {
        emailGroups.putIfAbsent(email, () => []).add(user);
      }

      if (user.role != UserRole.admin &&
          (user.atelierId == null || user.atelierId!.trim().isEmpty) &&
          (user.atelierName == null || user.atelierName!.trim().isEmpty)) {
        issues.add(
          QualityIssue(
            type: QualityIssueType.missingAtelier,
            title: user.fullName,
            subtitle:
                '${user.role.label} · ${user.phone.trim().isEmpty ? 'sans téléphone' : user.phone}',
            userId: user.id,
          ),
        );
      }

      if (user.phone.trim().isEmpty) {
        issues.add(
          QualityIssue(
            type: QualityIssueType.missingPhone,
            title: user.fullName,
            subtitle:
                '${user.role.label} · ${user.atelierName ?? 'sans atelier'}',
            userId: user.id,
          ),
        );
      }

      if (user.role != UserRole.admin) {
        final lastActivity = user.lastLoginAt ?? user.createdAt;
        if (lastActivity != null) {
          final days = now.difference(lastActivity).inDays;
          if (days >= 30) {
            final type = days >= 90
                ? QualityIssueType.inactive90
                : (days >= 60
                    ? QualityIssueType.inactive60
                    : QualityIssueType.inactive30);
            issues.add(
              QualityIssue(
                type: type,
                title: user.fullName,
                subtitle:
                    '${user.role.label} · ${user.atelierName ?? 'sans atelier'} · dernière activité il y a $days j',
                userId: user.id,
                days: days,
              ),
            );
          }
        }
      }
    }

    for (final group in emailGroups.values) {
      if (group.length < 2) continue;
      issues.add(
        QualityIssue(
          type: QualityIssueType.duplicateEmail,
          title: group.first.email,
          subtitle:
              '${group.length} comptes : ${group.map((u) => u.fullName).join(', ')}',
          userId: group.first.id,
        ),
      );
    }

    for (final order in orders) {
      if (order.status == OrderStatus.completed) continue;

      final lastActivity = order.statusHistory.isNotEmpty
          ? order.statusHistory.last.changedAt
          : order.createdAt;
      if (lastActivity == null) continue;

      final days = now.difference(lastActivity).inDays;
      if (days < _dormantOrderDays) continue;

      issues.add(
        QualityIssue(
          type: QualityIssueType.dormantOrder,
          title: '#${order.id} · ${order.clientName}',
          subtitle:
              '${order.atelierName} · ${order.status.label} · $days j sans activité',
          orderId: order.id,
          days: days,
        ),
      );
    }

    return DataQualityReport(
      issues: issues,
      usersScanned: users.length,
      ordersScanned: orders.length,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Adoption
  // ───────────────────────────────────────────────────────────────────────────

  FeatureUsageReport _buildUsage(List<FeatureUsageEvent> events, DateTime now) {
    final cutoff = now.subtract(const Duration(days: _usageWindowDays));
    final recent = events.where((event) => event.createdAt.isAfter(cutoff));

    final byFeature = <String, List<FeatureUsageEvent>>{};
    final allUsers = <String>{};
    for (final event in recent) {
      byFeature.putIfAbsent(event.feature, () => []).add(event);
      if (event.userId != null) allUsers.add(event.userId!);
    }

    final keys = <String>{...FeatureCatalog.all.keys, ...byFeature.keys};
    final stats = <FeatureUsageStat>[];

    for (final key in keys) {
      final featureEvents = byFeature[key] ?? const <FeatureUsageEvent>[];
      final users = <String>{};
      var last7 = 0;
      var previous7 = 0;
      DateTime? lastUsedAt;

      for (final event in featureEvents) {
        if (event.userId != null) users.add(event.userId!);
        final age = now.difference(event.createdAt);
        if (age.inDays <= 7) {
          last7++;
        } else if (age.inDays <= 14) {
          previous7++;
        }
        if (lastUsedAt == null || event.createdAt.isAfter(lastUsedAt)) {
          lastUsedAt = event.createdAt;
        }
      }

      if (featureEvents.isEmpty && !FeatureCatalog.all.containsKey(key)) {
        continue;
      }

      stats.add(
        FeatureUsageStat(
          feature: key,
          events: featureEvents.length,
          uniqueUsers: users.length,
          last7: last7,
          previous7: previous7,
          lastUsedAt: lastUsedAt,
        ),
      );
    }

    stats.sort((a, b) {
      final byEvents = b.events.compareTo(a.events);
      if (byEvents != 0) return byEvents;
      return b.uniqueUsers.compareTo(a.uniqueUsers);
    });

    return FeatureUsageReport(
      stats: stats,
      totalEvents: recent.length,
      uniqueUsers: allUsers.length,
      windowDays: _usageWindowDays,
      generatedAt: now,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stockage
  // ───────────────────────────────────────────────────────────────────────────

  /// Mesure l'espace Storage réellement utilisé par les mémos vocaux.
  ///
  /// Aujourd'hui, `storage.rules` n'autorise QUE `order_issues/...` (audio) :
  /// il n'existe donc pas d'autre type de fichier à additionner. On parcourt
  /// l'historique des commandes, on collecte les URLs uniques et on demande
  /// la taille de chaque fichier via les métadonnées Storage.
  Future<StorageUsage> _resolveStorage(List<String> warnings) async {
    final config = PlatformConfigService.instance;

    StorageUsage measured;
    if (FirebaseService.isAvailable) {
      measured = await _measureStorage(warnings);
    } else {
      measured = const StorageUsage(
        note: 'La mesure du stockage nécessite Firebase. En mode démo, '
            "aucun fichier n'est réellement stocké.",
      );
    }

    if (measured.available) return measured;

    // Repli sur la valeur écrite par un éventuel job d'audit.
    if (config.storageBytes != null) {
      return StorageUsage(
        bytes: config.storageBytes,
        updatedAt: config.storageUpdatedAt,
        note: measured.note,
      );
    }
    return measured;
  }

  Future<StorageUsage> _measureStorage(List<String> warnings) async {
    final now = DateTime.now();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .limit(1000)
          .get();

      final urls = <String>{};
      for (final doc in snapshot.docs) {
        final history = doc.data()['statusHistory'];
        if (history is! List) continue;
        for (final entry in history) {
          if (entry is! Map) continue;
          final url = entry['voiceNoteUrl'];
          if (url is String && url.trim().isNotEmpty) urls.add(url);
        }
      }

      if (urls.isEmpty) {
        return StorageUsage(
          bytes: 0,
          updatedAt: now,
          note: 'Aucun mémo vocal stocké pour le moment. Les seuls fichiers '
              'autorisés dans Storage sont les mémos vocaux des commandes.',
        );
      }

      final limited = urls.take(300).toList();
      var total = 0;
      var measured = 0;
      var failures = 0;

      for (var offset = 0; offset < limited.length; offset += 20) {
        final chunk = limited.skip(offset).take(20);
        final sizes = await Future.wait(chunk.map((url) async {
          try {
            final metadata = await FirebaseStorage.instance
                .refFromURL(url)
                .getMetadata()
                .timeout(const Duration(seconds: 8));
            return metadata.size ?? 0;
          } catch (_) {
            return null;
          }
        }));

        for (final size in sizes) {
          if (size == null) {
            failures++;
          } else {
            total += size;
            measured++;
          }
        }
      }

      if (measured == 0) {
        warnings.add(
          'Stockage non mesurable : les métadonnées des mémos vocaux sont '
          'inaccessibles. Vérifiez que les règles Storage autorisent '
          '`isAdmin()` en lecture.',
        );
        return const StorageUsage(
          note: "Les tailles de fichiers n'ont pas pu être lues. Vérifiez les "
              "règles Storage (lecture admin) ou le job d'audit.",
        );
      }

      final suffix = urls.length > limited.length
          ? ' Limité aux 300 premiers fichiers.'
          : '';
      final failedSuffix = failures > 0
          ? ' $failures fichier(s) inaccessible(s).'
          : '';
      return StorageUsage(
        bytes: total,
        updatedAt: now,
        note: '$measured mémo(s) vocal(aux) mesuré(s).$suffix$failedSuffix',
      );
    } catch (error) {
      warnings.add('Stockage illisible : $error');
      return const StorageUsage(
        note: 'Impossible de parcourir les commandes pour mesurer le stockage.',
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Chargements Firestore tolérants aux erreurs
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<AppUser>> _safeFetchUsers(List<String> warnings) async {
    try {
      return await _fetchAllUsers();
    } catch (error) {
      warnings.add('Comptes illisibles : $error');
      return const [];
    }
  }

  Future<List<Order>> _safeFetchOrders(List<String> warnings) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['pending', 'inProgress', 'problem'])
          .get();
      return snapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      warnings.add('Commandes illisibles : $error');
      return const [];
    }
  }

  Future<List<PlatformErrorRecord>> _safeFetchErrors(
    List<String> warnings,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('systemErrors')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PlatformErrorRecord(
          id: doc.id,
          message: data['message'] as String? ?? 'Erreur inconnue',
          createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
          stack: data['stack'] as String?,
          context: data['context'] as String?,
          platform: data['platform'] as String?,
          appVersion: data['appVersion'] as String?,
          userId: data['userId'] as String?,
        );
      }).toList();
    } catch (error) {
      warnings.add('Journal d\'erreurs illisible : $error');
      return const [];
    }
  }

  Future<List<FeatureUsageEvent>> _safeFetchFeatureEvents(
    List<String> warnings,
  ) async {
    try {
      final cutoff = DateTime.now()
          .subtract(const Duration(days: _usageWindowDays))
          .toIso8601String();
      final snapshot = await FirebaseFirestore.instance
          .collection('featureEvents')
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .orderBy('createdAt', descending: true)
          .limit(5000)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FeatureUsageEvent(
          feature: data['feature'] as String? ?? 'inconnue',
          userId: data['userId'] as String?,
          createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (error) {
      warnings.add('Télémétrie d\'usage illisible : $error');
      return const [];
    }
  }
}
