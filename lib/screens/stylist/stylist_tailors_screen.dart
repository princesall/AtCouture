import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/firebase_error_messages.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../shared/staff_account_actions.dart';
import '../shared/subscription_dialog.dart';
import '../shared/tailor_orders_screen.dart';

class StylistTailorsScreen extends StatefulWidget {
  const StylistTailorsScreen({super.key});

  @override
  State<StylistTailorsScreen> createState() => _StylistTailorsScreenState();
}

class _StylistTailorsScreenState extends State<StylistTailorsScreen> {
  void _showAddTailorDialog() {
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

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // Voir OrderService (principe d'idempotence) : sans clé stable, un
    // double-tap ou un réseau lent qui fait rejouer la requête créait un
    // compte couturier en double avec un mot de passe temporaire différent.
    final idempotencyKey = const Uuid().v4();

    showDialog(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (isSubmitting || !formKey.currentState!.validate()) return;
              setDialogState(() => isSubmitting = true);

              try {
                final result = await CompanyService.instance.createTailor(
                  atelierId: user.atelierId!,
                  atelierName: user.atelierName!,
                  fullName: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  idempotencyKey: idempotencyKey,
                );
                final newTailor = result.user;

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                setState(() {});

                // Afficher les identifiants de connexion du couturier créé.
                // Seuls email + mot de passe servent à se connecter — l'UID
                // interne (newTailor.id) n'a aucune utilité pour le couturier
                // et n'est donc pas affiché ici.
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Couturier ajouté'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nom: ${newTailor.fullName}'),
                        const SizedBox(height: 8),
                        Text('Email: ${newTailor.email}'),
                        const SizedBox(height: 8),
                        Text('Mot de passe temporaire: ${result.temporaryPassword}'),
                        const SizedBox(height: 8),
                        Text(
                          'Le couturier devra définir son propre mot de passe à sa première connexion.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() => isSubmitting = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(friendlyFirebaseError(e))),
                );
              }
            }

            return AlertDialog(
              title: const Text('Ajouter un couturier'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone *',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email),
                          // Un vrai email (pas juste un contact du couturier) : la
                          // seule façon de récupérer un accès en cas de mot de
                          // passe oublié est le lien envoyé à CETTE adresse (voir
                          // AuthService.sendPasswordResetEmail — aucun accès admin
                          // ne permet de forcer un mot de passe sans ça).
                          helperText: 'Le couturier doit pouvoir consulter cette boîte mail',
                          helperMaxLines: 2,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@') ? 'Email valide requis' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
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
                      icon: const Icon(Icons.add),
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
                          Icons.info_outline,
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
                      icon: Icons.content_cut_outlined,
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
              icon: Icon(tailor.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline),
              color: tailor.isActive ? c.onSurfaceVariant : c.success,
              tooltip: tailor.isActive ? 'Suspendre' : 'Réactiver',
              onPressed: onToggleActive,
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: c.primary,
                tooltip: 'Modifier',
                onPressed: onEdit,
              ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
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
