import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../models/subscription_plan.dart';
import 'admin_kit.dart';

/// Confirmation d'action destructive ou irréversible.
Future<bool> adminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  bool danger = false,
}) async {
  final c = context.colorsRead;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (danger ? c.statusProblemBg : c.tertiaryContainer),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                      size: 19,
                      color: danger ? c.statusProblem : c.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleMd.copyWith(
                        fontSize: 16,
                        color: c.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: AppTextStyles.bodySm.copyWith(
                  color: c.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminButton(
                    label: 'Annuler',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 10),
                  AdminButton(
                    label: confirmLabel,
                    primary: !danger,
                    danger: danger,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Sélection d'un plan pour un changement manuel (action admin).
Future<SubscriptionPlan?> adminPickPlan(
  BuildContext context, {
  required SubscriptionPlan current,
}) async {
  final c = context.colorsRead;
  final result = await showDialog<SubscriptionPlan>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Changer le plan',
                style: AppTextStyles.titleMd.copyWith(
                  fontSize: 17,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Le nouveau plan prend effet immédiatement, avec une expiration à 30 jours. '
                'Le compte est notifié automatiquement.',
                style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              for (final plan in SubscriptionPlan.values) ...[
                _PlanOption(
                  plan: plan,
                  selected: plan == current,
                  onTap: () => Navigator.of(context).pop(plan),
                ),
                if (plan != SubscriptionPlan.values.last) const SizedBox(height: 8),
              ],
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: AdminButton(
                  label: 'Annuler',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result;
}

class _PlanOption extends StatefulWidget {
  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PlanOption> createState() => _PlanOptionState();
}

class _PlanOptionState extends State<_PlanOption> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plan = widget.plan;
    final accent = switch (plan) {
      SubscriptionPlan.free => c.onSurfaceVariant,
      SubscriptionPlan.starter => c.statusInProgress,
      SubscriptionPlan.pro => c.secondary,
      SubscriptionPlan.enterprise => c.goldInk,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: widget.selected
            ? c.tertiaryContainer
            : (_hover ? c.surfaceContainerLow : c.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.selected
                    ? c.tertiary.withValues(alpha: 0.7)
                    : c.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: AppTextStyles.titleSm.copyWith(
                          fontSize: 13.5,
                          color: c.onSurface,
                        ),
                      ),
                      Text(
                        _descriptionFor(plan),
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 11.5,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  plan.priceLabel,
                  style: AppTextStyles.labelCaps.copyWith(
                    color: c.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                if (widget.selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, size: 17, color: c.goldInk),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(SubscriptionPlan plan) => switch (plan) {
        SubscriptionPlan.free => '1 couturier · 20 clients',
        SubscriptionPlan.starter => '5 couturiers · statistiques',
        SubscriptionPlan.pro => '20 couturiers · calendrier · PDF',
        SubscriptionPlan.enterprise => 'Ateliers illimités · multi-sites',
      };
}

/// Snackbar cohérente avec la charte (et lisible en clair comme en sombre).
void showAdminSnack(BuildContext context, String message, {bool error = false}) {
  final c = context.colorsRead;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        backgroundColor: c.inverseSurface,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 18,
              color: error ? c.error : c.statusDone,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySm.copyWith(color: c.inverseOnSurface),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Exécute une action admin en gérant l'erreur et le retour visuel.
Future<void> runAdminAction(
  BuildContext context, {
  required Future<void> Function() action,
  required String successMessage,
  String failureMessage = 'L\'action a échoué. Réessayez.',
}) async {
  try {
    await action();
    if (!context.mounted) return;
    showAdminSnack(context, successMessage);
  } catch (error) {
    if (!context.mounted) return;
    showAdminSnack(context, failureMessage, error: true);
  }
}
