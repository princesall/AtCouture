import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../data/admin_demo_data.dart';
import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';
import 'admin_companies_screen.dart';
import 'admin_dashboard.dart';

class AdminStylistsScreen extends StatefulWidget {
  const AdminStylistsScreen({super.key});
  @override
  State<AdminStylistsScreen> createState() => _AdminStylistsScreenState();
}

class _AdminStylistsScreenState extends State<AdminStylistsScreen> {
  int _filterIndex = 0;
  int _viewMode = 0; // 0 = Comptes individuels, 1 = Entreprises
  String _search = '';
  final _filters = ['TOUS', 'ACTIFS', 'INACTIFS', 'EXPIRÉS'];

  List<StylistEntry> get _filtered {
    var list = AdminDemoData.stylists;
    if (_search.isNotEmpty) {
      list = list.where((s) =>
        s.user.fullName.toLowerCase().contains(_search.toLowerCase()) ||
        (s.user.atelierName ?? '').toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }
    return switch (_filterIndex) {
      1 => list.where((s) => s.user.isActive).toList(),
      2 => list.where((s) => !s.user.isActive).toList(),
      3 => list.where((s) {
        final exp = s.user.planExpiresAt;
        return exp != null && exp.isBefore(DateTime.now().add(const Duration(days: 7)));
      }).toList(),
      _ => list,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Toggle Comptes individuels / Entreprises ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: _ViewToggleButton(label: 'COMPTES', icon: Icons.storefront_rounded, active: _viewMode == 0, onTap: () => setState(() => _viewMode = 0))),
              Expanded(child: _ViewToggleButton(label: 'ENTREPRISES', icon: Icons.apartment_rounded, active: _viewMode == 1, onTap: () => setState(() => _viewMode = 1))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _viewMode == 1 ? const AdminCompaniesScreen() : _buildIndividualAccounts()),
      ],
    );
  }

  Widget _buildIndividualAccounts() {
    return Column(
      children: [
        // ── Barre de recherche ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un styliste ou atelier...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = ''))
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Filtres ────────────────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = i == _filterIndex;
              return GestureDetector(
                onTap: () => setState(() => _filterIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: active ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))] : null,
                  ),
                  child: Text(_filters[i], style: AppTextStyles.labelCaps.copyWith(color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // ── Compteur ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(children: [
            Text('${_filtered.length} styliste${_filtered.length > 1 ? 's' : ''}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ]),
        ),
        // ── Liste ──────────────────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Text('Aucun résultat', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _StylistCard(
                    entry: _filtered[i],
                    index: i,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({required this.label, required this.icon, required this.active, required this.onTap});
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? AppColors.softShadow : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: active ? AppColors.primary : AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelCaps.copyWith(color: active ? AppColors.primary : AppColors.onSurfaceVariant, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge de transition — montre si ce compte vient de monter ou descendre
// de gamme par rapport à son plan précédent connu.
// ─────────────────────────────────────────────────────────────────────────────
class _TransitionBadge extends StatelessWidget {
  const _TransitionBadge({required this.userId, required this.plan});
  final String userId;
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final status = SubscriptionService.instance.transitionStatusFor(userId, plan);
    return switch (status) {
      PlanTransitionStatus.upgraded => _buildBadge(Icons.arrow_upward_rounded, AppColors.statusDone, 'MONTÉE'),
      PlanTransitionStatus.downgraded => _buildBadge(Icons.arrow_downward_rounded, AppColors.error, 'DESCENTE'),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildBadge(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 2),
        Text(label, style: AppTextStyles.labelXs.copyWith(color: color, fontSize: 8)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte styliste expandable
// ─────────────────────────────────────────────────────────────────────────────
class _StylistCard extends StatefulWidget {
  const _StylistCard({required this.entry, required this.index});
  final StylistEntry entry;
  final int index;
  @override
  State<_StylistCard> createState() => _StylistCardState();
}

class _StylistCardState extends State<_StylistCard> {
  bool _expanded = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _isActive = widget.entry.user.isActive;
  }

  Color get _planColor => switch (widget.entry.user.plan) {
    SubscriptionPlan.free       => AppColors.onSurfaceVariant,
    SubscriptionPlan.starter    => AppColors.statusInProgress,
    SubscriptionPlan.pro        => AppColors.primary,
    SubscriptionPlan.enterprise => AppColors.tertiary,
  };

  Color get _planBg => switch (widget.entry.user.plan) {
    SubscriptionPlan.free       => AppColors.surfaceContainerHigh,
    SubscriptionPlan.starter    => AppColors.statusInProgressBg,
    SubscriptionPlan.pro        => AppColors.primaryFixed.withValues(alpha: 0.4),
    SubscriptionPlan.enterprise => AppColors.tertiaryFixed.withValues(alpha: 0.4),
  };

  @override
  Widget build(BuildContext context) {
    final s = widget.entry;
    final isExpired = s.user.planExpiresAt != null && s.user.planExpiresAt!.isBefore(DateTime.now().add(const Duration(days: 7)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isExpired ? AppColors.error.withValues(alpha: 0.2) : AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Header carte ─────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              StylistAvatar(name: s.user.fullName, isOnline: s.isOnline),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(s.user.fullName, style: AppTextStyles.titleSm, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (!_isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
                      child: Text('INACTIF', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(s.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  // Badge plan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _planBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(s.user.plan.name.toUpperCase(), style: AppTextStyles.labelXs.copyWith(color: _planColor)),
                  ),
                  const SizedBox(width: 6),
                  _TransitionBadge(userId: s.user.id, plan: s.user.plan),
                  const SizedBox(width: 8),
                  // Ministat couturiers
                  Icon(Icons.content_cut_rounded, size: 12, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${s.tailorCount}', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(width: 10),
                  // Ministat commandes
                  Icon(Icons.receipt_long_rounded, size: 12, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${s.orderCount}', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ])),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant),
            ]),
          ),
        ),

        // ── Panneau expansible ────────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildExpandedPanel(s),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * widget.index), duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildExpandedPanel(StylistEntry s) {
    final isExpired = s.user.planExpiresAt != null && s.user.planExpiresAt!.isBefore(DateTime.now().add(const Duration(days: 7)));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // ── Stats revenus ──────────────────────────────────────────────
        Row(children: [
          _StatMini(label: 'REVENUS', value: '${Formatters.formatCurrency(s.totalRevenue)} FCFA', icon: Icons.payments_outlined, color: AppColors.tertiary),
          const SizedBox(width: 12),
          _StatMini(label: 'COMMANDES', value: s.orderCount.toString(), icon: Icons.receipt_long_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          _StatMini(label: 'COUTURIERS', value: s.tailorCount.toString(), icon: Icons.content_cut_outlined, color: AppColors.secondary),
        ]),
        const SizedBox(height: 14),

        // ── Expiration ────────────────────────────────────────────────
        if (s.user.planExpiresAt != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExpired ? AppColors.errorContainer.withValues(alpha: 0.3) : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isExpired ? AppColors.error.withValues(alpha: 0.2) : Colors.transparent),
            ),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: isExpired ? AppColors.error : AppColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                isExpired ? 'Expire bientôt : ${Formatters.date.format(s.user.planExpiresAt!)}' : 'Expire le ${Formatters.date.format(s.user.planExpiresAt!)}',
                style: AppTextStyles.bodySm.copyWith(color: isExpired ? AppColors.error : AppColors.onSurfaceVariant, fontWeight: isExpired ? FontWeight.w600 : FontWeight.w400),
              ),
            ]),
          ),

        const SizedBox(height: 14),

        // ── Contact + actions ─────────────────────────────────────────
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _showContactSheet(context, s),
            icon: const Icon(Icons.phone_outlined, size: 16),
            label: Text('CONTACTER', style: AppTextStyles.labelCaps),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _showPlanSheet(context, s),
            icon: const Icon(Icons.workspace_premium_rounded, size: 16),
            label: Text('ABONNEMENT', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              elevation: 0,
            ),
          )),
        ]),
        const SizedBox(height: 10),

        // ── Toggle actif/inactif ──────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              AdminDemoData.toggleActive(widget.entry.user.id);
              setState(() => _isActive = !_isActive);
            },
            icon: Icon(_isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
            label: Text(_isActive ? 'DÉSACTIVER LE COMPTE' : 'RÉACTIVER LE COMPTE', style: AppTextStyles.labelCaps.copyWith(color: _isActive ? AppColors.error : AppColors.statusDone)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isActive ? AppColors.error : AppColors.statusDone,
              side: BorderSide(color: (_isActive ? AppColors.error : AppColors.statusDone).withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ]),
    );
  }

  void _showContactSheet(BuildContext context, StylistEntry s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contacter ${s.user.fullName}', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 20),
          _ContactRow(icon: Icons.phone_outlined, label: s.user.phone),
          const SizedBox(height: 12),
          _ContactRow(icon: Icons.mail_outline_rounded, label: s.user.email),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _showPlanSheet(BuildContext context, StylistEntry s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _PlanChangeSheet(entry: s),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label, required this.value, required this.icon, required this.color});
  final String label; final String value; final IconData icon; final Color color;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.bodySm.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: AppTextStyles.labelXs.copyWith(color: color.withValues(alpha: 0.7), fontSize: 9)),
      ]),
    ));
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label});
  final IconData icon; final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyLg),
      ]),
    );
  }
}

class _PlanChangeSheet extends StatefulWidget {
  const _PlanChangeSheet({required this.entry});
  final StylistEntry entry;
  @override
  State<_PlanChangeSheet> createState() => _PlanChangeSheetState();
}
class _PlanChangeSheetState extends State<_PlanChangeSheet> {
  SubscriptionPlan? _selected;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.statusDone, size: 56),
          const SizedBox(height: 16),
          Text('Plan mis à jour !', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('${widget.entry.user.fullName} est maintenant sur le plan ${_selected!.name}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
            child: Text('FERMER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
          )),
        ]),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Modifier l\'abonnement', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Abonnement actuel : ${widget.entry.user.plan.name}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        ...SubscriptionPlan.values.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selected = plan),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selected == plan ? AppColors.primaryFixed.withValues(alpha: 0.3) : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selected == plan ? AppColors.primary.withValues(alpha: 0.4) : AppColors.outlineVariant.withValues(alpha: 0.3), width: _selected == plan ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(Icons.workspace_premium_rounded, color: _selected == plan ? AppColors.primary : AppColors.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(plan.name, style: AppTextStyles.titleSm.copyWith(color: _selected == plan ? AppColors.primary : AppColors.onSurface)),
                  Text(plan.priceLabel, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ])),
                if (_selected == plan) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _selected == null ? null : () {
            AdminDemoData.applyManualPlanChange(widget.entry.user.id, _selected!);
            setState(() => _done = true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, disabledBackgroundColor: AppColors.surfaceContainerHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: Text('APPLIQUER LE CHANGEMENT', style: AppTextStyles.labelCaps.copyWith(color: _selected == null ? AppColors.onSurfaceVariant : AppColors.onPrimary)),
        )),
      ]),
    );
  }
}
