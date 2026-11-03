import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/subscription_periods.dart';
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

/// Sélection de la durée d'un renouvellement d'abonnement (1 à 12 mois).
///
/// Les plans sont facturés au mois : imposer « 12 mois » à chaque clic ne
/// correspondait ni au prix affiché ni à l'approbation d'un plan (30 jours).
/// L'admin choisit ici la période réellement accordée au compte.
Future<int?> adminPickRenewalMonths(
  BuildContext context, {
  required String userFullName,
  required SubscriptionPlan plan,
  DateTime? currentExpiry,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _RenewalMonthsDialog(
      userFullName: userFullName,
      plan: plan,
      currentExpiry: currentExpiry,
    ),
  );
}

class _RenewalMonthsDialog extends StatefulWidget {
  const _RenewalMonthsDialog({
    required this.userFullName,
    required this.plan,
    this.currentExpiry,
  });

  final String userFullName;
  final SubscriptionPlan plan;
  final DateTime? currentExpiry;

  @override
  State<_RenewalMonthsDialog> createState() => _RenewalMonthsDialogState();
}

class _RenewalMonthsDialogState extends State<_RenewalMonthsDialog> {
  int _months = SubscriptionPeriods.minMonths;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final start = SubscriptionPeriods.renewalStart(widget.currentExpiry);
    final end = SubscriptionPeriods.renewalEnd(widget.currentExpiry, _months);
    final continuesFromExpiry = widget.currentExpiry != null &&
        widget.currentExpiry!.isAfter(DateTime.now());

    return Dialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renouveler l\'abonnement',
                  style: AppTextStyles.titleMd.copyWith(
                    fontSize: 17,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.userFullName} — plan ${widget.plan.name}. '
                  'Choisissez la durée à accorder : de 1 à 12 mois.',
                  style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                Text(
                  'DURÉE',
                  style: AppTextStyles.labelCaps.copyWith(
                    fontSize: 9,
                    color: c.goldInk,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var months = SubscriptionPeriods.minMonths;
                        months <= SubscriptionPeriods.maxMonths;
                        months++)
                      _MonthChip(
                        months: months,
                        selected: months == _months,
                        onTap: () => setState(() => _months = months),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOUVELLE ÉCHÉANCE',
                        style: AppTextStyles.labelCaps.copyWith(
                          fontSize: 9,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.date.format(end),
                        style: AppTextStyles.titleMd.copyWith(
                          fontSize: 16,
                          color: c.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        continuesFromExpiry
                            ? 'Prolongation depuis l\'échéance actuelle '
                                '(${Formatters.date.format(start)}), sans perdre '
                                'les jours restants.'
                            : 'Point de départ : aujourd\'hui '
                                '(${Formatters.date.format(start)}).',
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 11.5,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AdminButton(
                      label: 'Annuler',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    AdminButton(
                      label:
                          'Renouveler ${SubscriptionPeriods.monthsLabel(_months)}',
                      primary: true,
                      onTap: () => Navigator.of(context).pop(_months),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.months,
    required this.selected,
    required this.onTap,
  });

  final int months;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.tertiaryContainer : c.surfaceContainerLow,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? c.goldInk
                  : c.outlineVariant.withValues(alpha: 0.8),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            '$months',
            style: AppTextStyles.titleSm.copyWith(
              fontSize: 13,
              color: c.onSurface,
            ),
          ),
        ),
      ),
    );
  }
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

/// Affiche le diagnostic à faire quand Firebase accepte la demande de
/// réinitialisation mais que l'email n'arrive pas.
///
/// `sendPasswordResetEmail` peut réussir sans qu'aucun email ne soit envoyé :
/// avec la protection contre l'énumération des comptes, Firebase renvoie un
/// succès générique même si l'adresse n'existe pas dans Auth. Et même quand
/// le compte existe, les emails Firebase par défaut finissent très souvent en
/// spam. Ce dialogue donne donc les vérifications concrètes à l'admin.
Future<void> showPasswordResetDiagnosticDialog(
  BuildContext context, {
  required String email,
}) {
  final c = context.colorsRead;
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
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
                        color: c.tertiaryContainer,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        size: 19,
                        color: c.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Demande acceptée par Firebase',
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
                  'Firebase a accepté d\'envoyer un lien à $email. '
                  'Aucun email reçu ? Voici les causes réelles, dans l\'ordre :',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                _DiagnosticLine(
                  number: '1',
                  text: 'Vérifiez le dossier Spam / Indésirables. Les emails '
                      'Firebase partent de noreply@<projet>.firebaseapp.com et '
                      'sont souvent filtrés.',
                ),
                _DiagnosticLine(
                  number: '2',
                  text: 'Vérifiez que $email existe dans Firebase Console → '
                      'Authentication → Users. Avec la protection contre '
                      'l\'énumération, Firebase répond « succès » même si '
                      'l\'adresse est inconnue.',
                ),
                _DiagnosticLine(
                  number: '3',
                  text: 'L\'adresse du document users/{uid} doit être la même '
                      'que celle du compte Auth. Si elle a été modifiée dans '
                      'l\'application, le lien part à l\'ancienne adresse.',
                ),
                _DiagnosticLine(
                  number: '4',
                  text: 'Configurez Authentication → Templates → SMTP avec un '
                      'vrai serveur d\'envoi : c\'est ce qui règle la majorité '
                      'des emails qui n\'arrivent jamais.',
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: AdminButton(
                    label: 'Compris',
                    primary: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DiagnosticLine extends StatelessWidget {
  const _DiagnosticLine({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: AppTextStyles.labelCaps.copyWith(
                fontSize: 9,
                color: c.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 12,
                color: c.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
