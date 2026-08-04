import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../data/admin_demo_data.dart';
import '../../models/subscription_plan.dart';
import '../../providers/auth_provider.dart';

/// Sélecteur d'abonnement — accessible à tout moment depuis l'onglet Profil
/// (tuile "Abonnement"), et pas seulement quand une limite de plan est
/// atteinte (voir les dialogues "Limite atteinte" des écrans Commandes/
/// Clients/Couturiers, qui appellent aussi `show()` en dernière étape).
abstract final class SubscriptionDialog {
  static void show(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    final currentPlan = user.plan;

    // Vérifier si une demande est déjà en cours pour ce compte.
    final entry = AdminDemoData.stylists.where((s) => s.user.id == user.id).firstOrNull;
    final pendingRequest = entry?.subscriptionRequest;

    if (pendingRequest != null && !pendingRequest.approved) {
      showDialog(
        context: context,
        builder: (context) {
          final c = context.colors;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending_rounded, color: c.tertiary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Demande en cours',
                    style: AppTextStyles.titleMd.copyWith(color: c.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Votre demande pour le plan ${pendingRequest.requestedPlan.name} est en cours de traitement par l\'administrateur.',
                    style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Compris'),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 980,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: _PlanPicker(
            currentPlan: currentPlan,
            onPick: (plan) {
              Navigator.pop(context);
              _confirmRequest(context, plan);
            },
          ),
        ),
      ),
    );
  }

  static void _confirmRequest(BuildContext context, SubscriptionPlan plan) {
    final user = context.read<AuthProvider>().user!;

    showDialog(
      context: context,
      builder: (context) {
        final c = context.colors;
        return AlertDialog(
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
              onPressed: () async {
                await AdminDemoData.requestSubscription(user.id, plan);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Demande envoyée pour le plan ${plan.name}'),
                    backgroundColor: c.tertiary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: c.primary),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }
}

/// Un point vendu par un plan — icône + couleur + libellé.
typedef _Feature = (IconData, Color, String);

class _PlanPicker extends StatefulWidget {
  const _PlanPicker({required this.currentPlan, required this.onPick});

  final SubscriptionPlan currentPlan;
  final ValueChanged<SubscriptionPlan> onPick;

  @override
  State<_PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends State<_PlanPicker> {
  final bool _annual = false;

  static final _plans = [SubscriptionPlan.starter, SubscriptionPlan.pro, SubscriptionPlan.enterprise];

  List<_Feature> _featuresFor(SubscriptionPlan plan) {
    final c = context.colors;
    switch (plan) {
      case SubscriptionPlan.starter:
        return [
          (Icons.person_outline_rounded, c.primary, plan.tailorsLabel),
          (Icons.people_outline_rounded, c.primary, plan.clientsLabel),
          (Icons.receipt_long_outlined, c.success, plan.ordersLabel),
          (Icons.straighten_rounded, c.success, 'Mensurations sauvegardées'),
          (Icons.notifications_active_outlined, c.secondary, 'Notifications push'),
        ];
      case SubscriptionPlan.pro:
        return [
          (Icons.person_outline_rounded, c.primary, plan.tailorsLabel),
          (Icons.people_outline_rounded, c.primary, 'Clients illimités'),
          (Icons.insights_rounded, c.success, 'Statistiques avancées'),
          (Icons.calendar_month_rounded, c.secondary, 'Calendrier & rappels automatiques'),
          (Icons.request_quote_outlined, c.secondary, 'Devis & factures PDF'),
          (Icons.headset_mic_outlined, c.tertiary, 'Support prioritaire'),
        ];
      case SubscriptionPlan.enterprise:
        return [
          (Icons.person_outline_rounded, c.primary, 'Couturiers illimités'),
          (Icons.people_outline_rounded, c.primary, 'Clients illimités'),
          (Icons.apartment_rounded, c.success, 'Plusieurs ateliers'),
          (Icons.palette_outlined, c.secondary, 'Personnalisation & API'),
          (Icons.verified_outlined, c.tertiary, 'Toutes les fonctionnalités Pro incluses'),
          (Icons.headset_mic_outlined, c.tertiary, 'Gestionnaire dédié 24/7'),
        ];
      case SubscriptionPlan.free:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: c.tertiary, size: 28),
              const SizedBox(width: 12),
              Text('Choisir un abonnement', style: AppTextStyles.headlineSm.copyWith(color: c.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: 'Votre plan actuel : ',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
              children: [
                TextSpan(
                  text: widget.currentPlan.name,
                  style: AppTextStyles.bodySm.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: c.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: c.success),
                const SizedBox(width: 6),
                Text('Plan actuel', style: AppTextStyles.labelXs.copyWith(color: c.success)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 760;
                final cards = _plans
                    .map((plan) => _PlanCard(
                          plan: plan,
                          annual: _annual,
                          isCurrent: plan == widget.currentPlan,
                          isPopular: plan == SubscriptionPlan.pro,
                          features: _featuresFor(plan),
                          onPick: () => widget.onPick(plan),
                        ))
                    .toList();

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final card in cards) ...[
                          Expanded(child: card),
                          if (card != cards.last) const SizedBox(width: AppSpacing.md),
                        ],
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.annual,
    required this.isCurrent,
    required this.isPopular,
    required this.features,
    required this.onPick,
  });

  final SubscriptionPlan plan;
  final bool annual;
  final bool isCurrent;
  final bool isPopular;
  final List<_Feature> features;
  final VoidCallback onPick;

  Color _accent(AppColorPalette c) => plan == SubscriptionPlan.enterprise
      ? c.tertiary
      : (isPopular ? c.primary : c.onSurfaceVariant);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = _accent(c);
    final numberFormat = NumberFormat.decimalPattern('fr_FR');
    final displayAmount = annual ? (plan.price * 12 * 0.8).round() : plan.price;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(top: isPopular ? 14 : 0),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
          decoration: BoxDecoration(
            color: plan == SubscriptionPlan.enterprise
                ? c.tertiary.withValues(alpha: 0.05)
                : c.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isPopular ? c.primary : accent.withValues(alpha: 0.3),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: c.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  plan.name.toUpperCase(),
                  style: AppTextStyles.labelCaps.copyWith(color: accent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: numberFormat.format(displayAmount),
                    style: AppTextStyles.headlineMd.copyWith(color: accent, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(
                        text: ' ${AppConstants.currency}',
                        style: AppTextStyles.bodySm.copyWith(color: accent),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Text(
                  annual ? '/an' : '/mois',
                  style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              for (final feature in features) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: feature.$2.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(feature.$1, size: 13, color: feature.$2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(feature.$3, style: AppTextStyles.bodySm)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: isCurrent
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Plan actuel'),
                      )
                    : isPopular
                        ? ElevatedButton(
                            onPressed: onPick,
                            style: ElevatedButton.styleFrom(backgroundColor: c.primary),
                            child: const Text('Choisir'),
                          )
                        : OutlinedButton(
                            onPressed: onPick,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accent,
                              side: BorderSide(color: accent),
                            ),
                            child: const Text('Choisir'),
                          ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'LE PLUS POPULAIRE',
                      style: AppTextStyles.labelXs.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
