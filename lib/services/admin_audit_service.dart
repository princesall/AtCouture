import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../models/admin_account.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

/// Journal des actions administratives.
///
/// Chaque action importante (approbation, renouvellement, suspension, paiement,
/// note, aperçu support) écrit une ligne dans `adminAuditLogs`. C'est ce qui
/// alimente la chronologie de la fiche 360 et la traçabilité.
class AdminAuditService {
  AdminAuditService._();
  static final AdminAuditService instance = AdminAuditService._();

  static const _collection = 'adminAuditLogs';
  static const _maxLocal = 300;

  final List<AdminAuditLog> _localLogs = [];

  Future<void> record({
    required String action,
    required String targetType,
    required String targetId,
    String? targetName,
    String? details,
  }) async {
    final actor = await _actor();
    final log = AdminAuditLog(
      id: 'audit_${DateTime.now().microsecondsSinceEpoch}',
      actorId: actor.id,
      actorName: actor.name,
      action: action,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      details: details,
      createdAt: DateTime.now(),
    );

    _localLogs.insert(0, log);
    if (_localLogs.length > _maxLocal) {
      _localLogs.removeRange(_maxLocal, _localLogs.length);
    }

    if (!FirebaseService.isAvailable) return;

    try {
      await FirebaseFirestore.instance.collection(_collection).add(log.toMap());
    } catch (error) {
      debugPrint('⚠ audit non enregistré ($action) : $error');
    }
  }

  /// Variante « fire and forget » pour ne jamais ralentir une action métier.
  void recordAsync({
    required String action,
    required String targetType,
    required String targetId,
    String? targetName,
    String? details,
  }) {
    unawaited(
      record(
        action: action,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        details: details,
      ),
    );
  }

  Future<List<AdminAuditLog>> forTarget(String targetId) async {
    if (!FirebaseService.isAvailable) {
      return localForTarget(targetId);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('targetId', isEqualTo: targetId)
          .limit(200)
          .get();
      final logs = snapshot.docs
          .map((doc) => AdminAuditLog.fromMap(doc.data(), doc.id))
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return logs;
    } catch (error) {
      debugPrint('⚠ journal d\'audit illisible : $error');
      return localForTarget(targetId);
    }
  }

  List<AdminAuditLog> localForTarget(String targetId) =>
      _localLogs.where((log) => log.targetId == targetId).toList();

  Future<({String id, String name})> _actor() async {
    try {
      final current = fb_auth.FirebaseAuth.instance.currentUser;
      if (current != null) {
        return (id: current.uid, name: current.email ?? 'Admin');
      }
    } catch (_) {}

    final demoAdmin =
        AuthService.demoUsers.where((user) => user.isAdmin).firstOrNull;
    return (
      id: demoAdmin?.id ?? 'admin_debug',
      name: demoAdmin?.fullName ?? 'Admin démo',
    );
  }
}
