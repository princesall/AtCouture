import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../shared/staff_account_actions.dart';
import '../shared/tailor_orders_screen.dart';

/// Vue globale de TOUS les couturiers de TOUS les ateliers,
/// groupés par atelier, avec le nombre de commandes actives par couturier.
class CompanyTailorsScreen extends StatefulWidget {
  const CompanyTailorsScreen({super.key});

  @override
  State<CompanyTailorsScreen> createState() => _CompanyTailorsScreenState();
}

class _CompanyTailorsScreenState extends State<CompanyTailorsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final ateliers = CompanyService.instance.ateliersOfCompany(user.id);
    final allTailors = CompanyService.instance.allTailorsOfCompany(user.id);
    final c = context.colors;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tous les Couturiers', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
            Text('${allTailors.length} couturier${allTailors.length > 1 ? 's' : ''} — ${ateliers.length} ateliers', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          ])),
          // KPI total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(gradient: c.heroGradient, borderRadius: BorderRadius.circular(12)),
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
            final tailors = CompanyService.instance.tailorsOfAtelier(atelier.id);
            final isOwnerAtelier = atelier.headStylistId == user.id;
            return _AtelierGroup(
              atelierName: atelier.name,
              isOwnerAtelier: isOwnerAtelier,
              tailors: tailors,
              index: e.key,
              onChanged: () => setState(() {}),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

class _AtelierGroup extends StatelessWidget {
  const _AtelierGroup({
    required this.atelierName,
    required this.isOwnerAtelier,
    required this.tailors,
    required this.index,
    required this.onChanged,
  });

  final String atelierName;
  final bool isOwnerAtelier;
  final List<AppUser> tailors;
  final int index;
  final VoidCallback onChanged;

  void _onTailorAction(BuildContext context, String action, AppUser tailor) {
    switch (action) {
      case 'edit':
        showEditTailorDialog(context, tailor, onChanged);
      case 'toggleActive':
        toggleTailorActive(context, tailor, onChanged);
      case 'resetLink':
        sendAccountResetLink(context, tailor);
      case 'delete':
        confirmAndRemoveTailor(context, tailor, onChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // En-tête groupe atelier
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isOwnerAtelier ? c.goldGradient : null,
            color: isOwnerAtelier ? null : c.primaryFixed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(isOwnerAtelier ? Icons.star_rounded : Icons.storefront_rounded,
              color: isOwnerAtelier ? c.onTertiary : c.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(atelierName, style: AppTextStyles.titleSm.copyWith(
              color: isOwnerAtelier ? c.onTertiary : c.primary, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isOwnerAtelier ? Colors.white.withValues(alpha: 0.2) : c.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${tailors.length} couturier${tailors.length > 1 ? 's' : ''}',
                style: AppTextStyles.labelXs.copyWith(color: isOwnerAtelier ? c.onTertiary : c.primary)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        if (tailors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text('Aucun couturier assigné', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant.withValues(alpha: 0.6))),
          )
        else
          ...tailors.asMap().entries.map((e) {
            final t = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TailorOrdersScreen(tailor: t)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
                    boxShadow: c.softShadow,
                  ),
                  child: Row(children: [
                    // Avatar
                    Opacity(
                      opacity: t.isActive ? 1 : 0.4,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: c.secondaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: Center(child: Text(
                          t.fullName.split(' ').take(2).map((p) => p[0]).join().toUpperCase(),
                          style: AppTextStyles.labelCaps.copyWith(color: c.secondary),
                        )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.fullName, style: AppTextStyles.titleSm.copyWith(fontSize: 14)),
                      Text(t.phone, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant, fontSize: 12)),
                    ])),
                    // Badge actif/suspendu — reflète le vrai statut du compte
                    // (voir AppUser.isActive), pas une couleur figée.
                    if (!t.isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: c.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('Suspendu', style: AppTextStyles.labelXs.copyWith(color: c.error)),
                      ),
                      const SizedBox(width: 6),
                    ] else ...[
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: c.statusDone, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, size: 18, color: c.onSurfaceVariant),
                      onSelected: (action) => _onTailorAction(context, action, t),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(value: 'toggleActive', child: Text(t.isActive ? 'Suspendre' : 'Réactiver')),
                        const PopupMenuItem(value: 'resetLink', child: Text('Envoyer un lien de réinitialisation')),
                        const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    ),
                  ]),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 40 * (index * 3 + e.key)), duration: 300.ms),
            );
          }),
      ]),
    );
  }
}
