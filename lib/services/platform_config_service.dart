import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants/app_constants.dart';
import '../models/platform_health.dart';
import 'firebase_service.dart';

/// Configuration d'exploitation de la plateforme, stockée dans
/// `systemConfig/app` et lisible publiquement (l'écran de maintenance doit
/// pouvoir s'afficher avant toute connexion).
///
/// Contient :
///  - le mode maintenance et son message ;
///  - les feature flags ;
///  - les notes de version ;
///  - les métriques système (stockage, jobs) écrites par un futur backend.
class PlatformConfigService extends ChangeNotifier {
  PlatformConfigService._();
  static final PlatformConfigService instance = PlatformConfigService._();

  // Ne lister ici que des flags RÉELLEMENT branchés dans l'application.
  // Un flag qui ne coupe rien est plus dangereux qu'un flag absent.
  static const defaultFlags = <String, bool>{
    'pdfExport': true,
    'supportMessaging': true,
  };

  static const _jobDefinitions = <({String id, String label, String description})>[
    (
      id: 'metrics_snapshot',
      label: 'Snapshot des métriques',
      description: 'Calcule chaque jour MRR, actifs, churn et conversions.',
    ),
    (
      id: 'expiration_reminders',
      label: 'Relances d\'expiration',
      description: 'Prévient les comptes à J-7 avant expiration.',
    ),
    (
      id: 'feature_events_cleanup',
      label: 'Purge télémétrie',
      description: 'Supprime les événements d\'usage de plus de 90 jours.',
    ),
    (
      id: 'storage_audit',
      label: 'Audit du stockage',
      description: 'Mesure l\'espace Storage utilisé par les ateliers.',
    ),
  ];

  bool _maintenanceMode = false;
  String _maintenanceMessage =
      'StyleConnect est en maintenance. Merci de réessayer dans quelques minutes.';
  Map<String, bool> _featureFlags = Map.of(defaultFlags);
  String _releaseNotes = '';
  DateTime? _releaseNotesUpdatedAt;
  int? _storageBytes;
  DateTime? _storageUpdatedAt;
  Map<String, PlatformJobStatus> _jobs = _initialJobs();
  String _version = AppConstants.appVersion;
  bool _loaded = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  bool get maintenanceMode => _maintenanceMode;
  String get maintenanceMessage => _maintenanceMessage;
  Map<String, bool> get featureFlags => Map.unmodifiable(_featureFlags);
  String get releaseNotes => _releaseNotes;
  DateTime? get releaseNotesUpdatedAt => _releaseNotesUpdatedAt;
  int? get storageBytes => _storageBytes;
  DateTime? get storageUpdatedAt => _storageUpdatedAt;
  List<PlatformJobStatus> get jobs => _jobs.values.toList();
  String get version => _version;
  bool get loaded => _loaded;

  bool isEnabled(String key, {bool defaultValue = true}) =>
      _featureFlags[key] ?? defaultValue;

  static Map<String, PlatformJobStatus> _initialJobs() {
    return {
      for (final definition in _jobDefinitions)
        definition.id: PlatformJobStatus(
          id: definition.id,
          label: definition.label,
          description: definition.description,
          state: PlatformJobState.notConfigured,
        ),
    };
  }

  Future<void> load() async {
    await _loadPackageVersion();

    if (!FirebaseService.isAvailable) {
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('systemConfig')
          .doc('app')
          .get()
          .timeout(const Duration(seconds: 8));
      _apply(doc.data());
      _listen();
    } catch (error) {
      debugPrint('⚠ configuration plateforme indisponible : $error');
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    if (!FirebaseService.isAvailable) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('systemConfig')
          .doc('app')
          .get()
          .timeout(const Duration(seconds: 8));
      _apply(doc.data());
      notifyListeners();
    } catch (error) {
      debugPrint('⚠ rechargement configuration impossible : $error');
      rethrow;
    }
  }

  Future<void> _loadPackageVersion() async {
    try {
      final info = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 3),
      );
      final build = info.buildNumber.trim();
      _version = build.isEmpty ? info.version : '${info.version}+$build';
    } catch (_) {
      _version = AppConstants.appVersion;
    }
  }

  void _listen() {
    _subscription ??= FirebaseFirestore.instance
        .collection('systemConfig')
        .doc('app')
        .snapshots()
        .listen(
      (doc) {
        _apply(doc.data());
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('⚠ écoute configuration plateforme interrompue : $error');
      },
    );
  }

  void _apply(Map<String, dynamic>? data) {
    if (data == null) return;

    _maintenanceMode = data['maintenanceMode'] as bool? ?? false;
    _maintenanceMessage = (data['maintenanceMessage'] as String?)?.trim().isNotEmpty == true
        ? (data['maintenanceMessage'] as String).trim()
        : 'StyleConnect est en maintenance. Merci de réessayer dans quelques minutes.';

    final rawFlags = data['featureFlags'];
    if (rawFlags is Map) {
      _featureFlags = {
        ...defaultFlags,
        for (final entry in rawFlags.entries)
          if (entry.key is String && entry.value is bool)
            entry.key as String: entry.value as bool,
      };
    }

    _releaseNotes = data['releaseNotes'] as String? ?? '';
    _releaseNotesUpdatedAt = DateTime.tryParse(
      data['releaseNotesUpdatedAt'] as String? ?? '',
    );

    _storageBytes = (data['storageBytes'] as num?)?.toInt();
    _storageUpdatedAt = DateTime.tryParse(
      data['storageUpdatedAt'] as String? ?? '',
    );

    final rawJobs = data['jobs'];
    if (rawJobs is Map) {
      final parsed = Map<String, PlatformJobStatus>.of(_jobs);
      for (final definition in _jobDefinitions) {
        final raw = rawJobs[definition.id];
        final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
        parsed[definition.id] = PlatformJobStatus(
          id: definition.id,
          label: definition.label,
          description: definition.description,
          state: _parseJobState(map?['state'] as String?),
          lastRunAt: DateTime.tryParse(map?['lastRunAt'] as String? ?? ''),
          message: map?['message'] as String?,
        );
      }
      _jobs = parsed;
    }
  }

  PlatformJobState _parseJobState(String? raw) => switch (raw) {
        'ok' => PlatformJobState.ok,
        'warning' => PlatformJobState.warning,
        'error' => PlatformJobState.error,
        _ => PlatformJobState.notConfigured,
      };

  Future<void> setMaintenance(bool enabled, {String? message}) async {
    _maintenanceMode = enabled;
    if (message != null && message.trim().isNotEmpty) {
      _maintenanceMessage = message.trim();
    }
    notifyListeners();

    await _write({
      'maintenanceMode': enabled,
      'maintenanceMessage': _maintenanceMessage,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setFeatureFlag(String key, bool enabled) async {
    _featureFlags = {..._featureFlags, key: enabled};
    notifyListeners();

    // Écriture imbriquée : set(..., merge: true) fusionne la map et
    // préserve les autres flags.
    await _write({
      'featureFlags': {key: enabled},
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveReleaseNotes(String notes) async {
    final now = DateTime.now();
    _releaseNotes = notes.trim();
    _releaseNotesUpdatedAt = now;
    notifyListeners();

    await _write({
      'releaseNotes': _releaseNotes,
      'releaseNotesUpdatedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  Future<void> updateStorageMetric(int bytes) async {
    final now = DateTime.now();
    _storageBytes = bytes;
    _storageUpdatedAt = now;
    notifyListeners();

    await _write({
      'storageBytes': bytes,
      'storageUpdatedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  Future<void> _write(Map<String, dynamic> data) async {
    if (!FirebaseService.isAvailable) return;
    await FirebaseFirestore.instance
        .collection('systemConfig')
        .doc('app')
        .set(data, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
