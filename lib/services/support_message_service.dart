import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/support_message.dart';
import 'firebase_service.dart';

/// Messagerie de support bidirectionnelle : un compte (styliste, chef
/// d'atelier/entreprise, couturier) signale un problème, l'admin voit le
/// message dans son espace et y répond, la réponse est visible par
/// l'expéditeur depuis son propre écran "Assistance". En mode démo (Firebase
/// non connecté), tout vit en mémoire ici ; en mode Firebase, `_messages`
/// devient un CACHE tenu à jour par deux écoutes distinctes : une globale
/// pour l'admin (allMessages), une scopée par senderId pour un compte donné
/// (messagesFrom) — nécessaire car firestore.rules n'autorise un compte non-
/// admin qu'à lire SES PROPRES messages, une requête liste non filtrée par
/// senderId serait rejetée en bloc pour lui.
///
/// Étend ChangeNotifier pour que les écrans (AdminMessagesScreen,
/// ContactSupportScreen) se rafraîchissent automatiquement quand un message/
/// une réponse arrive de Firestore pendant qu'ils sont déjà ouverts, pas
/// seulement après une action locale.
class SupportMessageService extends ChangeNotifier {
  SupportMessageService._();
  static final SupportMessageService instance = SupportMessageService._();

  final List<SupportMessage> _messages = [];
  int _idCounter = 1;

  // Idempotence — voir OrderService pour le principe : une clé générée une
  // fois par écran d'envoi évite qu'un double-tap ou une relecture réseau
  // ne crée deux signalements identiques. En mode Firebase, cette même clé
  // sert d'ID de document (voir send), comme pour les commandes/clients.
  final Map<String, SupportMessage> _sendIdempotencyCache = {};

  bool _allSynced = false;
  final Set<String> _syncedSenders = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = [];

  void _ensureAllSynced() {
    if (!FirebaseService.isAvailable) return;
    if (_allSynced) return;
    _allSynced = true;

    _subscriptions.add(
      FirebaseFirestore.instance.collection('supportMessages').snapshots().listen((snap) {
        _messages
          ..clear()
          ..addAll(snap.docs.map((d) => SupportMessage.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
  }

  void _ensureSenderSynced(String senderId) {
    if (!FirebaseService.isAvailable) return;
    if (!_syncedSenders.add(senderId)) return;

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('supportMessages')
          .where('senderId', isEqualTo: senderId)
          .snapshots()
          .listen((snap) {
        _messages.removeWhere((m) => m.senderId == senderId);
        _messages.addAll(snap.docs.map((d) => SupportMessage.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
  }

  /// Tous les messages, du plus récent au plus ancien — vue admin.
  List<SupportMessage> get allMessages {
    _ensureAllSynced();
    return List.unmodifiable(_messages.reversed);
  }

  /// Le fil d'un expéditeur donné, du plus récent au plus ancien — vue
  /// "mes messages" côté styliste/entreprise/couturier.
  List<SupportMessage> messagesFrom(String senderId) {
    _ensureSenderSynced(senderId);
    return _messages.where((m) => m.senderId == senderId).toList().reversed.toList();
  }

  int get unreadCount => _messages.where((m) => !m.isRead).length;

  Future<SupportMessage> send({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && _sendIdempotencyCache.containsKey(idempotencyKey)) {
      return _sendIdempotencyCache[idempotencyKey]!;
    }

    final message = SupportMessage(
      id: idempotencyKey ?? _nextId(),
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: content.trim(),
      sentAt: DateTime.now(),
    );

    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance
          .collection('supportMessages')
          .doc(message.id)
          .set(message.toMap());
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _messages.add(message);
    }

    if (idempotencyKey != null) {
      _sendIdempotencyCache[idempotencyKey] = message;
    }
    return message;
  }

  String _nextId() => 'support_msg_${_idCounter++}';

  Future<void> markRead(String messageId) async {
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('supportMessages').doc(messageId).update({'isRead': true});
      return;
    }

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1 || _messages[index].isRead) return;
    _messages[index] = _messages[index].copyWith(isRead: true);
  }

  Future<void> reply({
    required String messageId,
    required String replyContent,
  }) async {
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('supportMessages').doc(messageId).update({
        'isRead': true,
        'reply': replyContent.trim(),
        'repliedAt': DateTime.now().toIso8601String(),
      });
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    _messages[index] = _messages[index].copyWith(
      isRead: true,
      reply: replyContent.trim(),
      repliedAt: DateTime.now(),
    );
  }
}
