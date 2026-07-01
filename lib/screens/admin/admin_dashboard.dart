import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../data/admin_demo_data.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, this.onNavTap});
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildKpiGrid(),
        const SizedBox(height: 32),
        _buildAlertBanner(),
        const SizedBox(height: 32),
        _buildSectionTitle('Demandes d\'abonnement', badge: AdminDemoData.pendingRequests),
        const SizedBox(height: 16),
        _buildSubscriptionRequests(context),
        const SizedBox(height: 32),
        _buildSectionTitle('Messages récents', badge: AdminDemoData.unreadMessages),
        const SizedBox(height: 16),
        _buildRecentMessages(context),
        const SizedBox(height: 32),
        _buildSectionTitle('Top Stylistes'),
        const SizedBox(height: 16),
        _buildTopStylists(context),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tableau de bord',
          style: AppTextStyles.displayLg.copyWith(fontSize: 28, color: AppColors.primary),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        Text('Vue globale de la plateforme StyleConnect',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildKpiGrid() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: SizedBox(height: 130, child: StatCard(label: 'STYLISTES', value: AdminDemoData.totalStylists.toString(), icon: Icons.storefront_rounded, valueColor: AppColors.secondary))),
          const SizedBox(width: 16),
          Expanded(child: SizedBox(height: 130, child: StatCard(label: 'COUTURIERS', value: AdminDemoData.totalTailors.toString(), icon: Icons.content_cut_rounded, valueColor: AppColors.primary))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SizedBox(height: 130, child: StatCard(label: 'COMMANDES', value: AdminDemoData.activeOrders.toString(), icon: Icons.receipt_long_rounded, valueColor: AppColors.surfaceTint))),
          const SizedBox(width: 16),
          Expanded(child: SizedBox(height: 130, child: _RevenueCard(revenue: AdminDemoData.monthlyRevenue))),
        ]),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms);
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.warning_amber_rounded, color: AppColors.tertiaryFixedDim, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${AdminDemoData.expiringIn7Days} abonnements expirent', style: AppTextStyles.titleSm.copyWith(color: Colors.white)),
          Text('Dans les 7 prochains jours', style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.7))),
        ])),
        GestureDetector(
          onTap: () => onNavTap?.call(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Text('VOIR', style: AppTextStyles.labelCaps.copyWith(color: Colors.white)),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildSectionTitle(String title, {int? badge}) {
    return Row(children: [
      Text(title, style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
      if (badge != null && badge > 0) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(999)),
          child: Text(badge.toString(), style: AppTextStyles.labelXs.copyWith(color: Colors.white)),
        ),
      ],
    ]);
  }

  Widget _buildSubscriptionRequests(BuildContext context) {
    final requests = AdminDemoData.stylists.where((s) => s.subscriptionRequest != null && !s.subscriptionRequest!.approved).toList();
    return Column(
      children: requests.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _SubscriptionRequestCard(entry: s),
      )).toList(),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecentMessages(BuildContext context) {
    final recent = AdminDemoData.messages.take(3).toList();
    return Column(
      children: recent.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _MessagePreviewCard(message: m, onTap: () => onNavTap?.call(3)),
      )).toList(),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTopStylists(BuildContext context) {
    final top = AdminDemoData.stylists.where((s) => s.user.isActive).take(3).toList();
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.premiumShadow),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: top.asMap().entries.map((e) {
          final i = e.key; final s = e.value;
          return Column(children: [
            if (i > 0) Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3), indent: 16, endIndent: 16),
            ListTile(
              onTap: () => onNavTap?.call(1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: StylistAvatar(name: s.user.fullName, isOnline: s.isOnline),
              title: Text(s.user.fullName, style: AppTextStyles.titleSm),
              subtitle: Text(s.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Formatters.formatCurrency(s.totalRevenue), style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 13)),
                Text('FCFA', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
              ]),
            ),
          ]);
        }).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

// ── Revenue Card Or ──────────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.revenue});
  final int revenue;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('REVENUS', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary.withValues(alpha: 0.7))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Formatters.formatCurrency(revenue), style: AppTextStyles.statNumber.copyWith(color: AppColors.onTertiary, fontSize: 22)),
          Text('FCFA / mois', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary.withValues(alpha: 0.7))),
        ]),
      ]),
    );
  }
}

// ── Carte demande abonnement ─────────────────────────────────────────────────
class _SubscriptionRequestCard extends StatefulWidget {
  const _SubscriptionRequestCard({required this.entry});
  final StylistEntry entry;
  @override
  State<_SubscriptionRequestCard> createState() => _SubscriptionRequestCardState();
}
class _SubscriptionRequestCardState extends State<_SubscriptionRequestCard> {
  bool _approved = false;
  bool _rejected = false;
  @override
  Widget build(BuildContext context) {
    final req = widget.entry.subscriptionRequest!;
    if (_approved || _rejected) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _approved ? AppColors.statusDoneBg : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _approved ? AppColors.statusDone.withValues(alpha: 0.3) : AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(_approved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: _approved ? AppColors.statusDone : AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(
            _approved ? '${widget.entry.user.fullName} — Plan ${req.requestedPlan.name} approuvé' : '${widget.entry.user.fullName} — Demande refusée',
            style: AppTextStyles.bodySm.copyWith(color: _approved ? AppColors.statusDone : AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
          )),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)), boxShadow: AppColors.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          StylistAvatar(name: widget.entry.user.fullName, isOnline: widget.entry.isOnline),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.entry.user.fullName, style: AppTextStyles.titleSm),
            Text(widget.entry.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.statusInProgressBg, borderRadius: BorderRadius.circular(999)),
            child: Text('EN ATTENTE', style: AppTextStyles.labelXs.copyWith(color: AppColors.statusInProgress)),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.tertiary, size: 20),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Passage au plan ${req.requestedPlan.name}', style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 14)),
              Text(req.requestedPlan.priceLabel, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ]),
            const Spacer(),
            Text(Formatters.date.format(req.requestedAt), style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () {
              AdminDemoData.rejectRequest(widget.entry.user.id);
              setState(() => _rejected = true);
            },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
            child: Text('REFUSER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.error)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () {
              AdminDemoData.approveRequest(widget.entry.user.id);
              setState(() => _approved = true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
            child: Text('APPROUVER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
          )),
        ]),
      ]),
    );
  }
}

// ── Carte message preview ────────────────────────────────────────────────────
class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({required this.message, this.onTap});
  final AdminMessage message;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isRead ? AppColors.surfaceContainerLowest : AppColors.primaryFixed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: message.isRead ? AppColors.outlineVariant.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StylistAvatar(name: message.senderName, isOnline: false, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(message.senderName, style: AppTextStyles.titleSm.copyWith(fontWeight: message.isRead ? FontWeight.w600 : FontWeight.w700))),
              if (!message.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(_formatTime(message.sentAt), style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
            ]),
            const SizedBox(height: 2),
            Text(message.senderRole, style: AppTextStyles.labelXs.copyWith(color: AppColors.secondary)),
            const SizedBox(height: 6),
            Text(message.content, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inMinutes}min';
  }
}

// ── Avatar styliste avec point online ───────────────────────────────────────
class StylistAvatar extends StatelessWidget {
  const StylistAvatar({super.key, required this.name, required this.isOnline, this.size = 44});
  final String name;
  final bool isOnline;
  final double size;
  String get _initials {
    final parts = name.trim().split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}'.toUpperCase() : name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.4), shape: BoxShape.circle, border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3), width: 1.5)),
        child: Center(child: Text(_initials, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: size * 0.33))),
      ),
      if (isOnline) Positioned(right: 0, bottom: 0, child: Container(
        width: size * 0.28, height: size * 0.28,
        decoration: BoxDecoration(color: AppColors.statusDone, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceContainerLowest, width: 1.5)),
      )),
    ]);
  }
}
