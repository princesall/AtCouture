/// Message de support envoyé par un compte (styliste, chef d'atelier,
/// chef d'entreprise ou couturier) à l'admin de la plateforme, avec la
/// réponse éventuelle de l'admin. senderId permet de retrouver le compte
/// complet de l'expéditeur (voir AdminDemoData.findAnyUserById) pour que
/// l'admin ait le contexte du compte directement à côté du message.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.reply,
    this.repliedAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final String? reply;
  final DateTime? repliedAt;

  bool get isReplied => reply != null;

  SupportMessage copyWith({
    bool? isRead,
    String? reply,
    DateTime? repliedAt,
  }) {
    return SupportMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: content,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      reply: reply ?? this.reply,
      repliedAt: repliedAt ?? this.repliedAt,
    );
  }
}
