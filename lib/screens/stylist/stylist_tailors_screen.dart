import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../shared/staff_account_actions.dart';
import '../shared/staff_account_form_sheet.dart';
import '../shared/subscription_dialog.dart';
import '../shared/tailor_orders_screen.dart';

class StylistTailorsScreen extends StatefulWidget {
  const StylistTailorsScreen({super.key});

  @override
  State<StylistTailorsScreen> createState() => _StylistTailorsScreenState();
}

class _StylistTailorsScreenState extends State<StylistTailorsScreen> {
  Future<void> _showAddTailorDialog() async {
    final user = context.read<AuthProvider>().user!;
    final permissions = user.permissions;

    // Vérifier si l'utilisateur peut ajouter des couturiers
    if (!permissions.canAddTailor(_getCurrentTailorCount())) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limite atteinte'),
          content: Text(permissions.canAddTailorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                SubscriptionDialog.show(context);
              },
              child: const Text('Voir les abonnements'),
            ),
          ],
        ),
      );
      return;
    }

    // Voir OrderService (principe d'idempotence) : sans clé stable, un
    // double-tap ou un réseau lent qui fait rejouer la requête créait un
    // compte couturier en double avec un mot de passe temporaire différent.
    final idempotencyKey = const Uuid().v4();
    ({AppUser user, String temporaryPassword})? created;

    final saved = await StaffAccountFormSheet.show(
      context,
      StaffAccountFormSheet(
        title: 'Nouveau couturier',
        subtitle: 'Un mot de passe temporaire est généré : il devra le changer '
            'à sa première connexion.',
        submitLabel: 'Ajouter le couturier',
        onSubmit: ({
          required String fullName,
          required String phone,
          required String email,
        }) async {
          created = await CompanyService.instance.createTailor(
            atelierId: user.atelierId!,
            atelierName: user.atelierName!,
            fullName: fullName,
            email: email,
            phone: phone,
            idempotencyKey: idempotencyKey,
          );
        },
      ),
    );

    if (!mounted || !saved) return;
    setState(() {});

    // Les identifiants ne s'affichent qu'une seule fois : on laisse la
    // possibilité de les copier ou de les envoyer directement par WhatsApp.
    final result = created;
    if (result == null) return;
    await StaffCredentialsSheet.show(
      context,
      fullName: result.user.fullName,
      email: result.user.email,
      temporaryPassword: result.temporaryPassword,
      phone: result.user.phone,
    );
  }

  int _getCurrentTailorCount() {
    final user = context.read<AuthProvider>().user!;
    return CompanyService.instance.tailorsOfAtelier(user.atelierId!).length;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final permissions = user.permissions;
    final c = context.colors;
    final tailors = CompanyService.instance.tailorsOfAtelier(user.atelierId!);
    final currentCount = tailors.length;
    final maxTailors = permissions.maxTailorsPerAtelier;
    final canAdd = permissions.canAddTailor(currentCount);

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Couturiers',
                      style: AppTextStyles.headlineLgMobile,
                    ),
                    const Spacer(),
                    Text(
                      '$currentCount/$maxTailors',
                      style: AppTextStyles.bodySm.copyWith(
                        color: canAdd ? c.primary : c.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.plus),
                      onPressed: _showAddTailorDialog,
                      tooltip: 'Ajouter un couturier',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!canAdd)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: c.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.info,
                          size: 16,
                          color: c.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            permissions.canAddTailorMessage,
                            style: AppTextStyles.bodySm.copyWith(
                              color: c.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Liste des couturiers
          Expanded(
            child: tailors.isEmpty
                ? Center(
                    child: EmptyState(
                      title: 'Aucun couturier',
                      subtitle: 'Commencez par ajouter votre premier couturier',
                      icon: PhosphorIconsRegular.scissors,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: tailors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final tailor = tailors[index];
                      return _TailorCard(
                        tailor: tailor,
                        onViewOrders: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TailorOrdersScreen(tailor: tailor)),
                        ),
                        onToggleActive: () => toggleTailorActive(context, tailor, () => setState(() {})),
                        onEdit: canAdd
                            ? () => showEditTailorDialog(context, tailor, () => setState(() {}))
                            : null,
                        onRemove: canAdd
                            ? () => confirmAndRemoveTailor(context, tailor, () => setState(() {}))
                            : null,
                      ).animate().fadeIn(delay: (index * 50).ms).slideX();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TailorCard extends StatelessWidget {
  const _TailorCard({
    required this.tailor,
    required this.onViewOrders,
    required this.onToggleActive,
    required this.onEdit,
    required this.onRemove,
  });

  final AppUser tailor;
  final VoidCallback onViewOrders;
  final VoidCallback onToggleActive;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onViewOrders,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: c.softShadow,
        ),
        child: Row(
          children: [
            Opacity(
              opacity: tailor.isActive ? 1 : 0.4,
              child: UserAvatar(initials: tailor.initials, size: 48),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tailor.fullName,
                          style: AppTextStyles.titleMd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!tailor.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Suspendu',
                            style: AppTextStyles.labelXs.copyWith(color: c.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tailor.phone,
                    style: AppTextStyles.bodySm.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(tailor.isActive ? PhosphorIconsRegular.pauseCircle : PhosphorIconsRegular.playCircle),
              color: tailor.isActive ? c.onSurfaceVariant : c.success,
              tooltip: tailor.isActive ? 'Suspendre' : 'Réactiver',
              onPressed: onToggleActive,
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(PhosphorIconsRegular.pencilSimple),
                color: c.primary,
                tooltip: 'Modifier',
                onPressed: onEdit,
              ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(PhosphorIconsRegular.trash),
                color: c.error,
                tooltip: 'Supprimer',
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
