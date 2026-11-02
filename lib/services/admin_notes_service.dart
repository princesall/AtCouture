import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../models/admin_account.dart';
import 'admin_audit_service.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

/// Notes internes d'un compte, stockées dans
/// `users/{uid}/adminNotes/{noteId}` et invisibles pour le compte concerné.
class AdminNotesService {
  AdminNotesService._();
  static final AdminNotesService instance = AdminNotesService._();

  static const _maxLength = 2000;

  final Map<String, List<AdminNote>> _localNotes = {};

  Future<List<AdminNote>> notesFor(String userId) async {
    if (!FirebaseService.isAvailable) {
      return List.unmodifiable(_localNotes[userId] ?? const []);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('adminNotes')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      return snapshot.docs
          .map((doc) => AdminNote.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      debugPrint('⚠ notes internes illisibles : $error');
      return const [];
    }
  }

  Future<AdminNote> add(String userId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('La note ne peut pas être vide.');
    }
    if (trimmed.length > _maxLength) {
      throw ArgumentError('La note ne peut pas dépasser $_maxLength caractères.');
    }

    final actor = await _actor();
    final note = AdminNote(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      text: trimmed,
      authorId: actor.id,
      authorName: actor.name,
      createdAt: DateTime.now(),
    );

    _localNotes.putIfAbsent(userId, () => []).insert(0, note);

    if (FirebaseService.isAvailable) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('adminNotes')
          .doc();
      final saved = AdminNote(
        id: ref.id,
        text: note.text,
        authorId: note.authorId,
        authorName: note.authorName,
        createdAt: note.createdAt,
      );
      await ref.set(saved.toMap());
      _localNotes[userId]![0] = saved;
      AdminAuditService.instance.recordAsync(
        action: 'note.add',
        targetType: 'user',
        targetId: userId,
        details: 'Note interne ajoutée par ${actor.name}',
      );
      return saved;
    }

    AdminAuditService.instance.recordAsync(
      action: 'note.add',
      targetType: 'user',
      targetId: userId,
      details: 'Note interne ajoutée par ${actor.name}',
    );
    return note;
  }

  Future<void> delete(String userId, String noteId) async {
    final notes = _localNotes[userId];
    if (notes != null) {
      notes.removeWhere((note) => note.id == noteId);
    }

    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('adminNotes')
          .doc(noteId)
          .delete();
    }

    final actor = await _actor();
    AdminAuditService.instance.recordAsync(
      action: 'note.delete',
      targetType: 'user',
      targetId: userId,
      details: 'Note interne supprimée par ${actor.name}',
    );
  }

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
