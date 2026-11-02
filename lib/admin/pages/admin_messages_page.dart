import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/support_message.dart';
import '../../services/support_message_service.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Boîte de réception support en deux volets, branchée sur
/// `SupportMessageService` (temps réel via Firestore en production).
class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  final _replyController = TextEditingController();

  String? _selectedId;
  String _query = '';
  int _filter = 0;
  bool _compactOpen = false;
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  List<SupportMessage> get _filtered {
    final query = _query.trim().toLowerCase();
    return SupportMessageService.instance.allMessages.where((message) {
      final matchesQuery = query.isEmpty ||
          message.senderName.toLowerCase().contains(query) ||
          message.content.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        1 => !message.isRead,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  SupportMessage? _selectedFrom(List<SupportMessage> messages) {
    if (messages.isEmpty) return null;
    for (final message in messages) {
      if (message.id == _selectedId) return message;
    }
    return messages.first;
  }

  Future<void> _select(SupportMessage message) async {
    setState(() {
      _selectedId = message.id;
      _compactOpen = true;
    });
    _replyController.clear();
    if (!message.isRead) {
      await SupportMessageService.instance.markRead(message.id);
    }
  }

  Future<void> _sendReply(SupportMessage message) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await SupportMessageService.instance.reply(
        messageId: message.id,
        replyContent: text,
      );
      _replyController.clear();
      if (!mounted) return;
      showAdminSnack(context, 'Réponse envoyée à ${message.senderName}.');
    } catch (_) {
      if (!mounted) return;
      showAdminSnack(context, 'La réponse n\'a pas pu être envoyée.', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SupportMessageService.instance,
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final horizontal = width >= 1400 ? 44.0 : (width >= 900 ? 32.0 : 18.0);
        final compact = width < 940;
        final messages = _filtered;
        final selected = _selectedFrom(messages);
        final unread = SupportMessageService.instance.unreadCount;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminPageHeader(
                    title: 'Messages',
                    subtitle:
                        '${SupportMessageService.instance.allMessages.length} conversation${SupportMessageService.instance.allMessages.length > 1 ? 's' : ''} · $unread non lu${unread > 1 ? 's' : ''}',
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: compact
                        ? (_compactOpen && selected != null
                            ? _ConversationPanel(
                                message: selected,
                                compact: true,
                                sending: _sending,
                                replyController: _replyController,
                                onBack: () => setState(() => _compactOpen = false),
                                onSend: () => _sendReply(selected),
                              )
                            : _InboxPanel(
                                messages: messages,
                                selectedId: selected?.id,
                                filter: _filter,
                                unread: unread,
                                onFilter: (index) => setState(() {
                                  _filter = index;
                                  _selectedId = null;
                                }),
                                onQuery: (value) => setState(() {
                                  _query = value;
                                  _selectedId = null;
                                }),
                                onSelect: _select,
                              ))
                        : Row(
                            children: [
                              SizedBox(
                                width: 372,
                                child: _InboxPanel(
                                  messages: messages,
                                  selectedId: selected?.id,
                                  filter: _filter,
                                  unread: unread,
                                  onFilter: (index) => setState(() {
                                    _filter = index;
                                    _selectedId = null;
                                  }),
                                  onQuery: (value) => setState(() {
                                    _query = value;
                                    _selectedId = null;
                                  }),
                                  onSelect: _select,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: selected == null
                                    ? const _EmptyConversation()
                                    : _ConversationPanel(
                                        message: selected,
                                        compact: false,
                                        sending: _sending,
                                        replyController: _replyController,
                                        onSend: () => _sendReply(selected),
                                      ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _panelDecoration(BuildContext context) {
  final c = context.colors;
  return BoxDecoration(
    color: c.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: c.outlineVariant.withValues(alpha: 0.75)),
    boxShadow: c.softShadow,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Liste
// ─────────────────────────────────────────────────────────────────────────────

class _InboxPanel extends StatelessWidget {
  const _InboxPanel({
    required this.messages,
    required this.selectedId,
    required this.filter,
    required this.unread,
    required this.onFilter,
    required this.onQuery,
    required this.onSelect,
  });

  final List<SupportMessage> messages;
  final String? selectedId;
  final int filter;
  final int unread;
  final ValueChanged<int> onFilter;
  final ValueChanged<String> onQuery;
  final ValueChanged<SupportMessage> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: _panelDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Boîte de réception',
                    style: AppTextStyles.titleMd.copyWith(
                      fontSize: 16,
                      color: c.onSurface,
                    ),
                  ),
                ),
                if (unread > 0)
                  AdminBadge(
                    label: '$unread non lu${unread > 1 ? 's' : ''}',
                    foreground: c.onPrimary,
                    background: c.primary,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdminSearchField(
              hint: 'Rechercher un expéditeur, un message…',
              onChanged: onQuery,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AdminFilterChips(
              labels: const ['TOUS', 'NON LUS'],
              selected: filter,
              onSelect: onFilter,
            ),
          ),
          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          Expanded(
            child: messages.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Aucun message',
                    message: 'Les signalements des comptes arriveront ici.',
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _ThreadTile(
                      message: messages[index],
                      selected: messages[index].id == selectedId,
                      onTap: () => onSelect(messages[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.message,
    required this.selected,
    required this.onTap,
  });

  final SupportMessage message;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unread = !message.isRead;

    return Material(
      color: selected ? c.surfaceContainerLow : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? c.goldInk : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(
                color: c.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminAvatar.fromName(message.senderName, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.senderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSm.copyWith(
                              fontSize: 13,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w500,
                              color: c.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.time.format(message.sentAt),
                          style: AppTextStyles.labelXs.copyWith(
                            color: c.onSurfaceVariant,
                            fontSize: 9,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.senderRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11.5,
                              fontWeight:
                                  unread ? FontWeight.w500 : FontWeight.w400,
                              color: unread
                                  ? c.onSurface
                                  : c.onSurfaceVariant.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        if (message.isReplied) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.reply_rounded,
                            size: 13,
                            color: c.statusDone,
                          ),
                        ],
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({
    required this.message,
    required this.compact,
    required this.sending,
    required this.replyController,
    required this.onSend,
    this.onBack,
  });

  final SupportMessage message;
  final bool compact;
  final bool sending;
  final TextEditingController replyController;
  final VoidCallback onSend;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: _panelDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(onBack == null ? 20 : 8, 12, 16, 12),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    color: c.onSurfaceVariant,
                    tooltip: 'Retour',
                  ),
                AdminAvatar.fromName(message.senderName, size: 40),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSm.copyWith(
                          fontSize: 14.5,
                          color: c.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${message.senderRole} · ${Formatters.dateTime.format(message.sentAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 11.5,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  AdminBadge(
                    label: message.isReplied ? 'RÉPONDU' : 'EN ATTENTE',
                    foreground:
                        message.isReplied ? c.statusDone : c.statusInProgress,
                    background: message.isReplied
                        ? c.statusDoneBg
                        : c.statusInProgressBg,
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      Formatters.date.format(message.sentAt),
                      style: AppTextStyles.labelXs.copyWith(
                        color: c.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _Bubble(
                  text: message.content,
                  author: message.senderName,
                  time: Formatters.time.format(message.sentAt),
                  fromAdmin: false,
                ),
                if (message.reply != null) ...[
                  const SizedBox(height: 12),
                  _Bubble(
                    text: message.reply!,
                    author: 'Support StyleConnect',
                    time: message.repliedAt != null
                        ? Formatters.time.format(message.repliedAt!)
                        : '',
                    fromAdmin: true,
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: c.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.outlineVariant),
                    ),
                    child: Center(
                      child: TextField(
                        controller: replyController,
                        enabled: !sending,
                        onSubmitted: (_) => onSend(),
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 12.5,
                          color: c.onSurface,
                        ),
                        cursorColor: c.onSurface,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: message.isReplied
                              ? 'Répondre à nouveau à ${message.senderName}…'
                              : 'Répondre à ${message.senderName}…',
                          hintStyle: AppTextStyles.bodySm.copyWith(
                            fontSize: 12.5,
                            color: c.onSurfaceVariant.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: sending ? null : onSend,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: sending
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.onPrimary,
                              ),
                            )
                          : Icon(Icons.send_rounded, size: 18, color: c.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.author,
    required this.time,
    required this.fromAdmin,
  });

  final String text;
  final String author;
  final String time;
  final bool fromAdmin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment:
          fromAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!fromAdmin) ...[
          Text(
            author,
            style: AppTextStyles.labelXs.copyWith(
              color: c.onSurfaceVariant,
              fontSize: 9,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fromAdmin ? c.primary : c.surfaceContainerLow,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(fromAdmin ? 14 : 4),
              bottomRight: Radius.circular(fromAdmin ? 4 : 14),
            ),
            border: fromAdmin
                ? null
                : Border.all(color: c.outlineVariant.withValues(alpha: 0.8)),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: fromAdmin ? c.onPrimary : c.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: AppTextStyles.labelXs.copyWith(
            color: c.onSurfaceVariant,
            fontSize: 8.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: _panelDecoration(context),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 30,
              color: c.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Sélectionnez une conversation',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
