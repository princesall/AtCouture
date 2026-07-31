import '../models/support_message.dart';

/// Messagerie de support bidirectionnelle : un compte (styliste, chef
/// d'atelier/entreprise, couturier) signale un problème, l'admin voit le
/// message dans son espace et y répond, la réponse est visible par
/// l'expéditeur depuis son propre écran "Assistance". En mémoire pour
/// l'instant (mode démo) — même remarque que les autres services : quand
/// Firestore sera branché, une collection `support_messages` avec les mêmes
/// champs remplace ce store.
class SupportMessageService {
  SupportMessageService._();
  static final SupportMessageService instance = SupportMessageService._();

  final List<SupportMessage> _messages = [];
  int _idCounter = 1;

  // Idempotence — voir OrderService pour le principe : une clé générée une
  // fois par écran d'envoi évite qu'un double-tap ou une relecture réseau
  // ne crée deux signalements identiques.
  final Map<String, SupportMessage> _sendIdempotencyCache = {};

  /// Tous les messages, du plus récent au plus ancien — vue admin.
  List<SupportMessage> get allMessages => List.unmodifiable(_messages.reversed);

  /// Le fil d'un expéditeur donné, du plus récent au plus ancien — vue
  /// "mes messages" côté styliste/entreprise/couturier.
  List<SupportMessage> messagesFrom(String senderId) =>
      _messages.where((m) => m.senderId == senderId).toList().reversed.toList();

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

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final message = SupportMessage(
      id: 'support_msg_${_idCounter++}',
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: content.trim(),
      sentAt: DateTime.now(),
    );
    _messages.add(message);

    if (idempotencyKey != null) {
      _sendIdempotencyCache[idempotencyKey] = message;
    }
    return message;
  }

  Future<void> markRead(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1 || _messages[index].isRead) return;
    _messages[index] = _messages[index].copyWith(isRead: true);
  }

  Future<void> reply({
    required String messageId,
    required String replyContent,
  }) async {
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
