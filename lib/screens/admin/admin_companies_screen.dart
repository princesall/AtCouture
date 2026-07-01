import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/admin_demo_data.dart';
import '../../services/company_service.dart';
import 'admin_dashboard.dart' show StylistAvatar;

/// Vue Admin : chaque compte Entreprise (plan Entreprise) avec sa structure
/// complète d'ateliers. L'Admin peut consulter (lecture) toute la hiérarchie
/// mais ne crée/modifie PAS les ateliers — c'est le rôle exclusif du
/// Chef d'Entreprise. L'Admin gère uniquement la plateforme et les abonnements.
class AdminCompaniesScreen extends StatelessWidget {
  const AdminCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companies = AdminDemoData.companies;

    if (companies.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.apartment_outlined, color: AppColors.onSurfaceVariant, size: 48),
        const SizedBox(height: 12),
        Text('Aucune entreprise multi-ateliers', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text('Entreprises', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Comptes plan Entreprise — vue lecture seule de la structure', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        ...companies.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _CompanyCard(company: e.value, index: e.key),
        )),
      ],
    );
  }
}

class _CompanyCard extends StatefulWidget {
  const _CompanyCard({required this.company, required this.index});
  final dynamic company; final int index;
  @override
  State<_CompanyCard> createState() => _CompanyCardState();
}
class _CompanyCardState extends State<_CompanyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    final ateliers = CompanyService.instance.ateliersOfCompany(c.ownerId as String);
    final stats = CompanyService.instance.companyStats(c.ownerId as String);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name as String, style: AppTextStyles.titleSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Propriétaire : ${c.ownerName}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(999)),
                  child: Text('PLAN ENTREPRISE', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary)),
                ),
              ])),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant),
            ]),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildExpanded(ateliers, stats),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * widget.index), duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildExpanded(List<dynamic> ateliers, dynamic stats) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)))),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          _StatChip(label: 'Ateliers', value: '${stats.totalAteliers}', icon: Icons.storefront_rounded),
          const SizedBox(width: 8),
          _StatChip(label: 'Couturiers', value: '${stats.totalTailors}', icon: Icons.content_cut_rounded),
          const SizedBox(width: 8),
          _StatChip(label: 'Commandes', value: '${stats.totalOrders}', icon: Icons.receipt_long_rounded),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.payments_rounded, color: AppColors.onTertiary, size: 16),
            const SizedBox(width: 6),
            Text('${Formatters.formatCurrency(stats.totalRevenue as int)} FCFA générés au total', style: AppTextStyles.bodySm.copyWith(color: AppColors.onTertiary, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerLeft, child: Text('STRUCTURE DES ATELIERS', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant))),
        const SizedBox(height: 10),
        ...ateliers.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
            child: Row(children: [
              StylistAvatar(name: a.headStylistName as String, isOnline: false, size: 32),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name as String, style: AppTextStyles.titleSm.copyWith(fontSize: 13)),
                Text('Chef : ${a.headStylistName}', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
              ])),
              Text('${(a.tailorIds as List).length} couturiers', style: AppTextStyles.labelXs.copyWith(color: AppColors.primary)),
            ]),
          ),
        )),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon});
  final String label; final String value; final IconData icon;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(height: 3),
      Text(value, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 13)),
      Text(label, style: AppTextStyles.labelXs.copyWith(fontSize: 8, color: AppColors.onSurfaceVariant)),
    ]),
  ));
}
