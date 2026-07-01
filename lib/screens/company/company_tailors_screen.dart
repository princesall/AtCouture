import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

/// Vue globale de TOUS les couturiers de TOUS les ateliers,
/// groupés par atelier, avec le nombre de commandes actives par couturier.
class CompanyTailorsScreen extends StatelessWidget {
  const CompanyTailorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final ateliers = CompanyService.instance.ateliersOfCompany(user.id);
    final allTailors = CompanyService.instance.allTailorsOfCompany(user.id);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tous les Couturiers', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
            Text('${allTailors.length} couturier${allTailors.length > 1 ? 's' : ''} — ${ateliers.length} ateliers', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
          // KPI total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.content_cut_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text('${allTailors.length} TOTAL', style: AppTextStyles.labelXs.copyWith(color: Colors.white)),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: ateliers.asMap().entries.map((e) {
            final atelier = e.value;
            final tailors = CompanyService.instance.tailorsOfAtelier(atelier.id as String);
            final isOwnerAtelier = (atelier.headStylistId as String) == user.id;
            return _AtelierGroup(
              atelierName: atelier.name as String,
              isOwnerAtelier: isOwnerAtelier,
              tailors: tailors,
              index: e.key,
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

class _AtelierGroup extends StatelessWidget {
  const _AtelierGroup({required this.atelierName, required this.isOwnerAtelier, required this.tailors, required this.index});
  final String atelierName; final bool isOwnerAtelier; final List<dynamic> tailors; final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // En-tête groupe atelier
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isOwnerAtelier ? AppColors.goldGradient : null,
            color: isOwnerAtelier ? null : AppColors.primaryFixed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(isOwnerAtelier ? Icons.star_rounded : Icons.storefront_rounded,
              color: isOwnerAtelier ? AppColors.onTertiary : AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(atelierName, style: AppTextStyles.titleSm.copyWith(
              color: isOwnerAtelier ? AppColors.onTertiary : AppColors.primary, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isOwnerAtelier ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${tailors.length} couturier${tailors.length > 1 ? 's' : ''}',
                style: AppTextStyles.labelXs.copyWith(color: isOwnerAtelier ? AppColors.onTertiary : AppColors.primary)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        if (tailors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text('Aucun couturier assigné', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
          )
        else
          ...tailors.asMap().entries.map((e) {
            final t = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(children: [
                  // Avatar
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: Center(child: Text(
                      (t.fullName as String).split(' ').take(2).map((p) => p[0]).join().toUpperCase(),
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.fullName as String, style: AppTextStyles.titleSm.copyWith(fontSize: 14)),
                    Text(t.phone as String, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
                  ])),
                  // Badge actif
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.statusDone, shape: BoxShape.circle),
                  ),
                ]),
              ).animate().fadeIn(delay: Duration(milliseconds: 40 * (index * 3 + e.key)), duration: 300.ms),
            );
          }),
      ]),
    );
  }
}
