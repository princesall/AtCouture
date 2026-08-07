import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/admin_demo_data.dart';
import 'admin_dashboard.dart' show StylistAvatar;

/// Carte "demande d'abonnement en attente" avec actions APPROUVER/REFUSER —
/// partagée entre admin_dashboard.dart (aperçu) et admin_subscriptions_screen.dart
/// (onglet "EN ATTENTE"), qui avaient chacun leur propre copie de ce widget :
/// deux implémentations indépendantes du même flux, aucune n'ayant de
/// protection anti-double-tap (voir commit "Prevent duplicate orders/accounts
/// from double-tap" — cette carte y avait échappé). Un seul widget = un seul
/// endroit à corriger, jamais de divergence entre les deux écrans.
class SubscriptionRequestCard extends StatefulWidget {
  const SubscriptionRequestCard({super.key, required this.entry, this.onDataChanged});
  final StylistEntry entry;
  final VoidCallback? onDataChanged;
  @override
  State<SubscriptionRequestCard> createState() => _SubscriptionRequestCardState();
}

class _SubscriptionRequestCardState extends State<SubscriptionRequestCard> {
  bool _approved = false;
  bool _rejected = false;
  bool _isSubmitting = false;

  Future<void> _reject() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await AdminDemoData.rejectRequest(widget.entry.user.id);
    if (!mounted) return;
    setState(() {
      _rejected = true;
      _isSubmitting = false;
    });
  }

  Future<void> _approve() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await AdminDemoData.approveRequest(widget.entry.user.id);
    if (!mounted) return;
    // Rafraîchit les KPIs de l'écran parent (totalTailors, revenus…)
    widget.onDataChanged?.call();
    setState(() {
      _approved = true;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final req = widget.entry.subscriptionRequest!;
    if (_approved || _rejected) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _approved ? c.statusDoneBg : c.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _approved ? c.statusDone.withValues(alpha: 0.3) : c.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(_approved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: _approved ? c.statusDone : c.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(
            _approved ? '${widget.entry.user.fullName} — Plan ${req.requestedPlan.name} approuvé' : '${widget.entry.user.fullName} — Demande refusée',
            style: AppTextStyles.bodySm.copyWith(color: _approved ? c.statusDone : c.onSurfaceVariant, fontWeight: FontWeight.w600),
          )),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surfaceContainerLowest, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)), boxShadow: c.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          StylistAvatar(name: widget.entry.user.fullName, isOnline: widget.entry.isOnline),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.entry.user.fullName, style: AppTextStyles.titleSm),
            Text(widget.entry.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: c.statusInProgressBg, borderRadius: BorderRadius.circular(999)),
            child: Text('EN ATTENTE', style: AppTextStyles.labelXs.copyWith(color: c.statusInProgress)),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.workspace_premium_rounded, color: c.tertiary, size: 20),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Passage au plan ${req.requestedPlan.name}', style: AppTextStyles.titleSm.copyWith(color: c.primary, fontSize: 14)),
              Text(req.requestedPlan.priceLabel, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
            ]),
            const Spacer(),
            Text(Formatters.date.format(req.requestedAt), style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _isSubmitting ? null : _reject,
            style: OutlinedButton.styleFrom(foregroundColor: c.error, side: BorderSide(color: c.error.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
            child: _isSubmitting
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.error))
                : Text('REFUSER', style: AppTextStyles.labelCaps.copyWith(color: c.error)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _isSubmitting ? null : _approve,
            style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
            child: _isSubmitting
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
                : Text('APPROUVER', style: AppTextStyles.labelCaps.copyWith(color: c.onPrimary)),
          )),
        ]),
      ]),
    );
  }
}
