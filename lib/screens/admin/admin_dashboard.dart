import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../data/admin_demo_data.dart';
import '../../models/subscription_plan.dart';
import '../../models/support_message.dart';
import '../../services/support_message_service.dart';
import 'subscription_request_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, this.onNavTap, this.onDataChanged});
  final ValueChanged<int>? onNavTap;
  final VoidCallback? onDataChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _buildHeader(c),
        const SizedBox(height: 24),
        _buildKpiGrid(c),
        const SizedBox(height: 16),
        _buildSubscriptionRevenueCard(c),
        const SizedBox(height: 32),
        _buildAlertBanner(c),
        const SizedBox(height: 32),
        _buildSectionTitle('Demandes d\'abonnement', c, badge: AdminDemoData.pendingRequests),
        const SizedBox(height: 16),
        _buildSubscriptionRequests(context),
        const SizedBox(height: 32),
        _buildSectionTitle('Messages récents', c, badge: SupportMessageService.instance.unreadCount),
        const SizedBox(height: 16),
        _buildRecentMessages(context),
        const SizedBox(height: 32),
        _buildSectionTitle('Top Stylistes', c),
        const SizedBox(height: 16),
        _buildTopStylists(context),
      ],
    );
  }

  Widget _buildHeader(AppColorPalette c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tableau de bord',
          style: AppTextStyles.displayLg.copyWith(fontSize: 28, color: c.primary),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        Text('Vue globale de la plateforme StyleConnect',
          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildKpiGrid(AppColorPalette c) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: SizedBox(height: 130, child: StatCard(label: 'STYLISTES', value: AdminDemoData.totalStylists.toString(), icon: Icons.storefront_rounded, valueColor: c.secondary))),
          const SizedBox(width: 16),
          Expanded(child: SizedBox(height: 130, child: StatCard(label: 'COUTURIERS', value: AdminDemoData.totalTailors.toString(), icon: Icons.content_cut_rounded, valueColor: c.primary))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SizedBox(height: 130, child: StatCard(label: 'COMMANDES', value: AdminDemoData.activeOrders.toString(), icon: Icons.receipt_long_rounded, valueColor: c.surfaceTint))),
          const SizedBox(width: 16),
          Expanded(child: SizedBox(height: 130, child: _RevenueCard(revenue: AdminDemoData.monthlyRevenue))),
        ]),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms);
  }

  Widget _buildSubscriptionRevenueCard(AppColorPalette c) {
    final breakdown = AdminDemoData.paidSubscribersByPlan;
    final subscribers = AdminDemoData.paidSubscribersCount;
    final paidPlans = [SubscriptionPlan.starter, SubscriptionPlan.pro, SubscriptionPlan.enterprise];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: c.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: c.heroGradient, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.account_balance_wallet_rounded, color: c.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REVENUS ABONNEMENTS', style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(
              '$subscribers abonné${subscribers > 1 ? 's' : ''} payant${subscribers > 1 ? 's' : ''} actif${subscribers > 1 ? 's' : ''}',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.formatCurrency(AdminDemoData.subscriptionRevenue), style: AppTextStyles.statNumber.copyWith(color: c.primary, fontSize: 20)),
            Text('${AppConstants.currency} / mois', style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant)),
          ]),
        ]),
        const SizedBox(height: 14),
        Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 14),
        Row(
          children: paidPlans.map((plan) {
            final count = breakdown[plan] ?? 0;
            return Expanded(child: Column(children: [
              Text(count.toString(), style: AppTextStyles.titleMd.copyWith(color: count > 0 ? c.primary : c.onSurfaceVariant.withValues(alpha: 0.4))),
              const SizedBox(height: 2),
              Text(plan.name, style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant)),
            ]));
          }).toList(),
        ),
      ]),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildAlertBanner(AppColorPalette c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: c.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.warning_amber_rounded, color: c.tertiaryFixedDim, size: 26),
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

  Widget _buildSectionTitle(String title, AppColorPalette c, {int? badge}) {
    return Row(children: [
      Text(title, style: AppTextStyles.titleMd.copyWith(color: c.primary)),
      if (badge != null && badge > 0) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: c.error, borderRadius: BorderRadius.circular(999)),
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
        child: SubscriptionRequestCard(entry: s, onDataChanged: onDataChanged),
      )).toList(),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecentMessages(BuildContext context) {
    final recent = SupportMessageService.instance.allMessages.take(3).toList();
    return Column(
      children: recent.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _MessagePreviewCard(message: m, onTap: () => onNavTap?.call(3)),
      )).toList(),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTopStylists(BuildContext context) {
    final c = context.colors;
    final top = AdminDemoData.stylists.where((s) => s.user.isActive).take(3).toList();
    return Container(
      decoration: BoxDecoration(color: c.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), boxShadow: c.premiumShadow),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: top.asMap().entries.map((e) {
          final i = e.key; final s = e.value;
          final realRevenue = AdminDemoData.getStylistRevenue(s.user);
          return Column(children: [
            if (i > 0) Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.3), indent: 16, endIndent: 16),
            ListTile(
              onTap: () => onNavTap?.call(1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: StylistAvatar(name: s.user.fullName, isOnline: s.isOnline),
              title: Text(s.user.fullName, style: AppTextStyles.titleSm),
              subtitle: Text(s.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Formatters.formatCurrency(realRevenue), style: AppTextStyles.titleSm.copyWith(color: c.primary, fontSize: 13)),
                Text(AppConstants.currency, style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant)),
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
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(gradient: c.goldGradient, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.tertiary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('REVENUS ATELIERS', style: AppTextStyles.labelXs.copyWith(color: c.onTertiary.withValues(alpha: 0.7))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Formatters.formatCurrency(revenue), style: AppTextStyles.statNumber.copyWith(color: c.onTertiary, fontSize: 22)),
          Text('${AppConstants.currency} / mois', style: AppTextStyles.labelXs.copyWith(color: c.onTertiary.withValues(alpha: 0.7))),
        ]),
      ]),
    );
  }
}

// Carte "demande d'abonnement" -> voir subscription_request_card.dart
// (partagée avec admin_subscriptions_screen.dart, voir SubscriptionRequestCard).

// ── Carte message preview ────────────────────────────────────────────────────
class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({required this.message, this.onTap});
  final SupportMessage message;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isRead ? c.surfaceContainerLowest : c.primaryFixed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: message.isRead ? c.outlineVariant.withValues(alpha: 0.3) : c.primary.withValues(alpha: 0.2)),
          boxShadow: c.softShadow,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StylistAvatar(name: message.senderName, isOnline: false, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(message.senderName, style: AppTextStyles.titleSm.copyWith(fontWeight: message.isRead ? FontWeight.w600 : FontWeight.w700))),
              if (!message.isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(_formatTime(message.sentAt), style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant)),
            ]),
            const SizedBox(height: 2),
            Text(message.senderRole, style: AppTextStyles.labelXs.copyWith(color: c.secondary)),
            const SizedBox(height: 6),
            Text(message.content, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
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
    final c = context.colors;
    return Stack(children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(color: c.primaryFixed.withValues(alpha: 0.4), shape: BoxShape.circle, border: Border.all(color: c.primaryContainer.withValues(alpha: 0.3), width: 1.5)),
        child: Center(child: Text(_initials, style: AppTextStyles.titleSm.copyWith(color: c.primary, fontSize: size * 0.33))),
      ),
      if (isOnline) Positioned(right: 0, bottom: 0, child: Container(
        width: size * 0.28, height: size * 0.28,
        decoration: BoxDecoration(color: c.statusDone, shape: BoxShape.circle, border: Border.all(color: c.surfaceContainerLowest, width: 1.5)),
      )),
    ]);
  }
}
