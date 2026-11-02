import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../preview_data.dart';
import '../widgets/preview_kit.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selected = 0;
  int _filter = 0;
  bool _compactOpen = false;
  String _query = '';

  List<PreviewThread> get _filtered {
    final query = _query.trim().toLowerCase();
    return previewThreads.where((thread) {
      final matchesQuery = query.isEmpty ||
          thread.name.toLowerCase().contains(query) ||
          thread.atelier.toLowerCase().contains(query) ||
          thread.lastMessage.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        1 => thread.unread > 0,
        2 => thread.flagged,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int get _unreadTotal =>
      previewThreads.fold<int>(0, (sum, thread) => sum + thread.unread);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1400 ? 44.0 : (width >= 900 ? 32.0 : 18.0);
    final compact = width < 940;
    final threads = _filtered;
    final selected = threads.isEmpty ? null : threads[_selected.clamp(0, threads.length - 1)];

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PreviewPageHeader(
                title: 'Messages',
                subtitle:
                    '${previewThreads.length} conversations · $_unreadTotal non lus · support de premier niveau',
                actions: const [
                  PreviewButton(
                    label: 'Nouvelle annonce',
                    icon: Icons.campaign_rounded,
                  ),
                  PreviewButton(
                    label: 'Tout marquer comme lu',
                    icon: Icons.done_all_rounded,
                    primary: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: compact
                    ? (_compactOpen && selected != null
                        ? _ConversationPanel(
                            thread: selected,
                            compact: true,
                            onBack: () => setState(() => _compactOpen = false),
                          )
                        : _InboxPanel(
                            threads: threads,
                            selected: _selected,
                            filter: _filter,
                            unreadTotal: _unreadTotal,
                            onFilter: (index) => setState(() { _filter = index; _selected = 0; }),
                            onQuery: (value) => setState(() { _query = value; _selected = 0; }),
                            onSelect: (index) => setState(() {
                              _selected = index;
                              _compactOpen = true;
                            }),
                          ))
                    : Row(
                        children: [
                          SizedBox(
                            width: 372,
                            child: _InboxPanel(
                              threads: threads,
                              selected: _selected,
                              filter: _filter,
                              unreadTotal: _unreadTotal,
                              onFilter: (index) => setState(() { _filter = index; _selected = 0; }),
                              onQuery: (value) => setState(() { _query = value; _selected = 0; }),
                              onSelect: (index) => setState(() => _selected = index),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: selected == null
                                ? const _EmptyConversation()
                                : _ConversationPanel(
                                    thread: selected,
                                    compact: false,
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
// Colonne de gauche — boîte de réception
// ─────────────────────────────────────────────────────────────────────────────

class _InboxPanel extends StatelessWidget {
  const _InboxPanel({
    required this.threads,
    required this.selected,
    required this.filter,
    required this.unreadTotal,
    required this.onFilter,
    required this.onQuery,
    required this.onSelect,
  });

  final List<PreviewThread> threads;
  final int selected;
  final int filter;
  final int unreadTotal;
  final ValueChanged<int> onFilter;
  final ValueChanged<String> onQuery;
  final ValueChanged<int> onSelect;

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
                if (unreadTotal > 0)
                  PreviewBadge(
                    label: '$unreadTotal non lus',
                    foreground: c.onPrimary,
                    background: c.primary,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PreviewSearchField(
              hint: 'Rechercher une conversation…',
              onChanged: onQuery,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: PreviewFilterChips(
              labels: const ['TOUS', 'NON LUS', 'SIGNALÉS'],
              selected: filter,
              onSelect: onFilter,
            ),
          ),
          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          Expanded(
            child: threads.isEmpty
                ? Center(
                    child: Text(
                      'Aucune conversation',
                      style: AppTextStyles.bodySm.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: threads.length,
                    itemBuilder: (context, index) => _ThreadTile(
                      thread: threads[index],
                      selected: index == selected,
                      onTap: () => onSelect(index),
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
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final PreviewThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unread = thread.unread > 0;

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
              PreviewAvatar(initials: thread.initials, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.name,
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
                          thread.time,
                          style: AppTextStyles.labelXs.copyWith(
                            color: c.onSurfaceVariant,
                            fontSize: 9,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.atelier,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (thread.flagged)
                          Icon(
                            Icons.flag_rounded,
                            size: 12,
                            color: c.statusInProgress,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11.5,
                              color: unread
                                  ? c.onSurface
                                  : c.onSurfaceVariant.withValues(alpha: 0.9),
                              fontWeight:
                                  unread ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${thread.unread}',
                              style: AppTextStyles.labelXs.copyWith(
                                color: c.onPrimary,
                                fontSize: 8.5,
                              ),
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
// Colonne de droite — conversation
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({
    required this.thread,
    required this.compact,
    this.onBack,
  });

  final PreviewThread thread;
  final bool compact;
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
            padding: EdgeInsets.fromLTRB(onBack == null ? 20 : 10, 12, 12, 12),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    color: c.onSurfaceVariant,
                    tooltip: 'Retour',
                  ),
                PreviewAvatar(initials: thread.initials, size: 40),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              thread.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSm.copyWith(
                                fontSize: 14.5,
                                color: c.onSurface,
                              ),
                            ),
                          ),
                          if (thread.flagged) ...[
                            const SizedBox(width: 8),
                            PreviewBadge(
                              label: 'SIGNALÉ',
                              foreground: c.statusInProgress,
                              background: c.statusInProgressBg,
                              icon: Icons.flag_rounded,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${thread.atelier} · ${thread.role}',
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
                if (!compact) ...[
                  const PreviewButton(
                    label: 'Voir le compte',
                    icon: Icons.open_in_new_rounded,
                    small: true,
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.more_horiz_rounded, size: 19, color: c.onSurfaceVariant),
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
                      'Aujourd\'hui',
                      style: AppTextStyles.labelXs.copyWith(
                        color: c.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (final message in thread.messages) ...[
                  _MessageBubble(message: message),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          _Composer(thread: thread),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final PreviewMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fromAdmin = message.fromAdmin;

    return Column(
      crossAxisAlignment:
          fromAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!fromAdmin) ...[
          Text(
            message.author,
            style: AppTextStyles.labelXs.copyWith(
              color: c.onSurfaceVariant,
              fontSize: 9,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          constraints: const BoxConstraints(maxWidth: 470),
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
                : Border.all(
                    color: c.outlineVariant.withValues(alpha: 0.8),
                  ),
          ),
          child: Text(
            message.text,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: fromAdmin ? c.onPrimary : c.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message.time,
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

class _Composer extends StatelessWidget {
  const _Composer({required this.thread});

  final PreviewThread thread;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Material(
            color: c.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.attach_file_rounded,
                  size: 18,
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12.5,
                    color: c.onSurface,
                  ),
                  cursorColor: c.onSurface,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Répondre à ${thread.name}…',
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
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.send_rounded, size: 18, color: c.onPrimary),
              ),
            ),
          ),
        ],
      ),
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
