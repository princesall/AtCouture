import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/admin_demo_data.dart';
import '../../models/support_message.dart';
import '../../services/support_message_service.dart';
import 'admin_dashboard.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});
  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  SupportMessage? _selected;

  List<SupportMessage> get _messages => SupportMessageService.instance.allMessages;
  int get _unreadCount => SupportMessageService.instance.unreadCount;

  void _openMessage(SupportMessage message) {
    SupportMessageService.instance.markRead(message.id);
    setState(() => _selected = message);
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _MessageDetailScreen(
        message: _selected!,
        onBack: () => setState(() => _selected = null),
      );
    }

    return Column(children: [
      // ── Header ──────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          Text('Messages', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(999)),
              child: Text('$_unreadCount', style: AppTextStyles.labelXs.copyWith(color: Colors.white)),
            ),
          ],
        ]),
      ),
      // ── Liste ──────────────────────────────────────────────────────────
      Expanded(
        child: _messages.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.forum_outlined, color: AppColors.onSurfaceVariant, size: 48),
                  const SizedBox(height: 12),
                  Text('Aucun message', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                itemCount: _messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _MessageCard(
                  message: _messages[i],
                  index: i,
                  onTap: () => _openMessage(_messages[i]),
                ),
              ),
      ),
    ]);
  }
}

// ── Carte message ────────────────────────────────────────────────────────────
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.index, required this.onTap});
  final SupportMessage message;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isRead ? AppColors.surfaceContainerLowest : AppColors.primaryFixed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: message.isRead ? AppColors.outlineVariant.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.25), width: message.isRead ? 1 : 1.5),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StylistAvatar(name: message.senderName, isOnline: false, size: 46),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(message.senderName, style: AppTextStyles.titleSm.copyWith(fontWeight: message.isRead ? FontWeight.w600 : FontWeight.w800))),
              if (!message.isRead) Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              if (message.isReplied) ...[
                const SizedBox(width: 6),
                const Icon(Icons.reply_rounded, color: AppColors.statusDone, size: 16),
              ],
            ]),
            const SizedBox(height: 2),
            Text(message.senderRole, style: AppTextStyles.labelXs.copyWith(color: AppColors.secondary)),
            const SizedBox(height: 6),
            Text(message.content, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(_formatTime(message.sentAt), style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
          ])),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: 60 * index), duration: 400.ms).slideY(begin: 0.04, end: 0),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inMinutes} min';
  }
}

// ── Résumé du compte de l'expéditeur ─────────────────────────────────────────
// C'est le principe "comme les grosses boîtes" : quand un compte signale un
// problème, l'admin voit directement son contexte (abonnement, activité)
// sans avoir à aller chercher ailleurs dans l'app.
class _SenderAccountSummary extends StatelessWidget {
  const _SenderAccountSummary({required this.senderId});
  final String senderId;

  @override
  Widget build(BuildContext context) {
    final user = AdminDemoData.findAnyUserById(senderId);
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.person_off_outlined, color: AppColors.onSurfaceVariant, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Compte introuvable (peut-être supprimé)', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant))),
        ]),
      );
    }

    final orders = AdminDemoData.getStylistOrderCount(user);
    final clients = AdminDemoData.getStylistClientCount(user);
    final revenue = AdminDemoData.getStylistRevenue(user);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.badge_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text('COMPTE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 10),
        _SummaryRow(label: 'Nom', value: user.fullName),
        _SummaryRow(label: 'Email', value: user.email),
        _SummaryRow(label: 'Téléphone', value: user.phone),
        _SummaryRow(label: 'Atelier', value: user.atelierName ?? '—'),
        _SummaryRow(label: 'Abonnement', value: '${user.plan.priceLabel}${user.isActive ? '' : ' — SUSPENDU'}'),
        const Divider(height: 20),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Commandes', value: '$orders')),
          Expanded(child: _MiniStat(label: 'Clients', value: '$clients')),
          Expanded(child: _MiniStat(label: 'Revenus', value: Formatters.formatCurrency(revenue))),
        ]),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant))),
      Expanded(child: Text(value, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary)),
    Text(label, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
  ]);
}

// ── Détail message + réponse ─────────────────────────────────────────────────
class _MessageDetailScreen extends StatefulWidget {
  const _MessageDetailScreen({required this.message, required this.onBack});
  final SupportMessage message;
  final VoidCallback onBack;
  @override
  State<_MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<_MessageDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _isSending = false;
  late SupportMessage _message;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
  }

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_isSending || _replyCtrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    await SupportMessageService.instance.reply(
      messageId: _message.id,
      replyContent: _replyCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _message = _message.copyWith(reply: _replyCtrl.text.trim(), repliedAt: DateTime.now());
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _message;
    return Column(children: [
      // ── Header retour ──────────────────────────────────────────────────
      Container(
        padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top > 0 ? 8 : 8, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.95),
          border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
        ),
        child: Row(children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 4),
          StylistAvatar(name: m.senderName, isOnline: false, size: 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.senderName, style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurface)),
            Text(m.senderRole, style: AppTextStyles.labelXs.copyWith(color: AppColors.secondary)),
          ])),
        ]),
      ),

      // ── Contenu ────────────────────────────────────────────────────────
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SenderAccountSummary(senderId: m.senderId),
          const SizedBox(height: 20),

          // Message original
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StylistAvatar(name: m.senderName, isOnline: false, size: 32),
            const SizedBox(width: 10),
            Expanded(child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.content, style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text(_formatFull(m.sentAt), style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
              ]),
            )),
          ]).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),

          const SizedBox(height: 16),

          // Réponse déjà envoyée (persistée — visible par l'expéditeur aussi)
          if (m.isReplied) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.end, children: [
              Expanded(child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(left: 48),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(4), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.reply!, style: AppTextStyles.bodyLg.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('Vous (Admin)', style: AppTextStyles.labelXs.copyWith(color: Colors.white.withValues(alpha: 0.6))),
                    const Spacer(),
                    const Icon(Icons.done_all_rounded, color: AppColors.tertiaryFixedDim, size: 14),
                  ]),
                ]),
              )),
            ]).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, end: 0),
          ],
        ]),
      )),

      // ── Zone de réponse ────────────────────────────────────────────────
      if (!m.isReplied)
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: _replyCtrl,
              maxLines: 3,
              minLines: 1,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: 'Écrire une réponse...',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.outlineVariant, width: 0.8)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isSending ? null : _send,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        )
      else
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.statusDone, size: 18),
            const SizedBox(width: 8),
            Text('Réponse envoyée', style: AppTextStyles.bodySm.copyWith(color: AppColors.statusDone, fontWeight: FontWeight.w600)),
          ]),
        ),
    ]);
  }

  String _formatFull(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} à ${dt.hour}h${dt.minute.toString().padLeft(2, '0')}';
  }
}
