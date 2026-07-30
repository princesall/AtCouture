import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../shared/subscription_dialog.dart';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un couturier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                return;
              }

              final result = await CompanyService.instance.createTailor(
                atelierId: user.atelierId!,
                atelierName: user.atelierName!,
                fullName: nameController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? 'couturier_${DateTime.now().millisecondsSinceEpoch}@demo.ml'
                    : emailController.text.trim(),
                phone: phoneController.text.trim(),
              );
              final newTailor = result.user;

              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});

              // Afficher l'identifiant du couturier créé
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
                      Text('Identifiant: ${newTailor.id}'),
                      const SizedBox(height: 8),
                      Text('Email: ${newTailor.email}'),
                      const SizedBox(height: 8),
                      Text('Mot de passe temporaire: ${result.temporaryPassword}'),
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
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  int _getCurrentTailorCount() {
    final user = context.read<AuthProvider>().user!;
    return CompanyService.instance.tailorsOfAtelier(user.atelierId!).length;
  }

  void _showEditTailorDialog(AppUser tailor) {
    final nameController = TextEditingController(text: tailor.fullName);
    final phoneController = TextEditingController(text: tailor.phone);
    final emailController = TextEditingController(text: tailor.email);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Modifier le couturier',
                    style: AppTextStyles.headlineMd,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty ||
                            phoneController.text.trim().isEmpty) {
                          return;
                        }

                        await CompanyService.instance.updateTailor(
                          tailorId: tailor.id,
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                          phone: phoneController.text.trim(),
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final permissions = user.permissions;
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
                        color: canAdd ? AppColors.primary : AppColors.error,
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
                      color: AppColors.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            permissions.canAddTailorMessage,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.tertiary,
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
                        onEdit: canAdd 
                            ? () => _showEditTailorDialog(tailor)
                            : null,
                        onRemove: canAdd 
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Supprimer le couturier'),
                                    content: Text('Voulez-vous vraiment supprimer ${tailor.fullName} ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await CompanyService.instance.removeTailor(tailor.id);
                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                          setState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                );
                              }
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
    required this.onEdit,
    required this.onRemove,
  });

  final AppUser tailor;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          UserAvatar(initials: tailor.initials, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tailor.fullName,
                  style: AppTextStyles.titleMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  tailor.phone,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
              onPressed: onEdit,
            ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
