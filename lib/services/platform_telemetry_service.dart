import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/platform_health.dart';
import 'firebase_service.dart';

/// Journal d'erreurs léger, consultable depuis la console admin.
///
/// Les erreurs non fatales sont écrites dans `systemErrors` uniquement si un
/// utilisateur est connecté (les règles Firestore l'exigent). Les erreurs
/// survenant avant la connexion restent en mémoire pour le diagnostic local.
/// Le volume est volontairement bridé : pas plus de 30 écritures par session,
/// déduplication par message pendant la session.
class PlatformTelemetryService {
  PlatformTelemetryService._();
  static final PlatformTelemetryService instance = PlatformTelemetryService._();

  static const _maxLocalErrors = 50;
  static const _maxWritesPerSession = 30;

  final List<PlatformErrorRecord> _localErrors = [];
  final Set<String> _seenKeys = {};
  int _writes = 0;

  List<PlatformErrorRecord> get localErrors => List.unmodifiable(_localErrors);

  void installGlobalHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      recordError(
        details.exception,
        details.stack,
        context: details.context?.toDescription(),
      );
      previousFlutterHandler?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, context: 'Erreur non capturée');
      return false;
    };
  }

  void recordError(
    Object error,
    StackTrace? stack, {
    String? context,
  }) {
    final message = error.toString();
    final key = '${message.hashCode}:${context ?? ''}';
    if (!_seenKeys.add(key)) return;

    final record = PlatformErrorRecord(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      message: _truncate(message, 500),
      createdAt: DateTime.now(),
      stack: stack == null ? null : _truncate(stack.toString(), 2000),
      context: context == null ? null : _truncate(context, 300),
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      appVersion: AppConstants.appVersion,
    );

    _localErrors.add(record);
    if (_localErrors.length > _maxLocalErrors) {
      _localErrors.removeRange(0, _localErrors.length - _maxLocalErrors);
    }

    unawaited(_persist(record));
  }

  Future<void> _persist(PlatformErrorRecord record) async {
    if (!FirebaseService.isAvailable) return;
    if (_writes >= _maxWritesPerSession) return;

    final uid = _currentUid();
    if (uid == null) return;
    _writes++;

    try {
      await FirebaseFirestore.instance.collection('systemErrors').add({
        'userId': uid,
        'message': record.message,
        'stack': record.stack,
        'context': record.context,
        'platform': record.platform,
        'appVersion': record.appVersion,
        'createdAt': record.createdAt.toIso8601String(),
      });
    } catch (_) {
      // Ne jamais transformer une erreur de télémétrie en erreur applicative.
    }
  }

  String? _currentUid() {
    try {
      return fb_auth.FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String _truncate(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…';
}
