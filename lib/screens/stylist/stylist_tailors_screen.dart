import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/admin_demo_data.dart';
import '../../models/app_user.dart';
import '../../models/subscription_plan.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

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
                _showSubscriptionDialog(context);
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
            onPressed: () {
              if (nameController.text.trim().isEmpty || 
                  phoneController.text.trim().isEmpty) {
                return;
              }

              final newTailor = CompanyService.instance.createTailor(
                atelierId: user.atelierId!,
                atelierName: user.atelierName!,
                fullName: nameController.text.trim(),
                email: emailController.text.trim().isEmpty 
                    ? 'couturier_${DateTime.now().millisecondsSinceEpoch}@demo.ml'
                    : emailController.text.trim(),
                phone: phoneController.text.trim(),
              );

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
                      Text('Mot de passe temporaire: bienvenue123'),
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
                      onPressed: () {
                        if (nameController.text.trim().isEmpty || 
                            phoneController.text.trim().isEmpty) {
                          return;
                        }

                        CompanyService.instance.updateTailor(
                          tailorId: tailor.id,
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim().isEmpty 
                              ? null 
                              : emailController.text.trim(),
                          phone: phoneController.text.trim(),
                        );

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

  void _showSubscriptionDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    final currentPlan = user.plan;

    // Vérifier si une demande est déjà en cours
    final stylistEntry = AdminDemoData.stylists.firstWhere(
      (s) => s.user.id == user.id,
      orElse: () => throw Exception('Styliste non trouvé'),
    );

    if (stylistEntry.subscriptionRequest != null && !stylistEntry.subscriptionRequest!.approved) {
      // Demande déjà en cours
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pending_rounded,
                  color: AppColors.tertiary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Demande en cours',
                  style: AppTextStyles.titleMd.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre demande pour le plan ${stylistEntry.subscriptionRequest!.requestedPlan.name} est en cours de traitement par l\'administrateur.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Compris'),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: AppColors.tertiary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Choisir un abonnement',
                    style: AppTextStyles.titleMd.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Votre plan actuel : ${currentPlan.name}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ...SubscriptionPlan.values
                  .where((plan) => plan != SubscriptionPlan.free && plan != currentPlan)
                  .map((plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SubscriptionPlanCard(
                          plan: plan,
                          onTap: () {
                            Navigator.pop(context);
                            _confirmSubscriptionRequest(context, plan);
                          },
                        ),
                      )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSubscriptionRequest(BuildContext context, SubscriptionPlan plan) {
    final user = context.read<AuthProvider>().user!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la demande'),
        content: Text(
          'Voulez-vous envoyer une demande pour le plan ${plan.name} (${plan.priceLabel}) à l\'administrateur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              AdminDemoData.requestSubscription(user.id, plan);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Demande envoyée pour le plan ${plan.name}'),
                  backgroundColor: AppColors.tertiary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmer'),
          ),
        ],
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
                                        onPressed: () {
                                          CompanyService.instance.removeTailor(tailor.id);
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

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.plan,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.name.toUpperCase(),
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  plan.priceLabel,
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.tailorsLabel,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.clientsLabel,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
