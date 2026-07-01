import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/system_message.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_service.dart';

/// Écran affichant les notifications SYSTÈME d'un compte (approbation/refus
/// d'abonnement, expiration, renouvellement, création de compte). Distinct
/// des messages texte libres — ces notifications sont générées automatiquement
/// par l'application suite à une action administrative.
class SystemNotificationsScreen extends StatefulWidget {
  const SystemNotificationsScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const SystemNotificationsScreen(),
      fullscreenDialog: true,
    ));
  }

  @override
  State<SystemNotificationsScreen> createState() => _SystemNotificationsScreenState();
}

class _SystemNotificationsScreenState extends State<SystemNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final messages = SubscriptionService.instance.systemMessagesFor(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
      ),
      body: messages.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.notifications_off_outlined, color: AppColors.onSurfaceVariant, size: 48),
                const SizedBox(height: 12),
                Text('Aucune notification', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ]),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final m = messages[i];
                if (!m.isRead) {
                  SubscriptionService.instance.markSystemMessageRead(user.id, m.id);
                }
                return _SystemMessageCard(message: m);
              },
            ),
    );
  }
}

class _SystemMessageCard extends StatelessWidget {
  const _SystemMessageCard({required this.message});
  final SystemMessage message;

  (IconData, Color, Color) get _style => switch (message.type) {
        SystemMessageType.subscriptionApproved => (Icons.check_circle_rounded, AppColors.statusDone, AppColors.statusDoneBg),
        SystemMessageType.subscriptionRejected => (Icons.cancel_rounded, AppColors.error, AppColors.errorContainer),
        SystemMessageType.subscriptionExpired => (Icons.warning_amber_rounded, AppColors.statusInProgress, AppColors.statusInProgressBg),
        SystemMessageType.subscriptionRenewed => (Icons.autorenew_rounded, AppColors.statusDone, AppColors.statusDoneBg),
        SystemMessageType.accountCreated => (Icons.celebration_rounded, AppColors.tertiary, AppColors.tertiaryFixed),
        SystemMessageType.accountDeactivated => (Icons.block_rounded, AppColors.error, AppColors.errorContainer),
        SystemMessageType.accountReactivated => (Icons.check_circle_rounded, AppColors.statusDone, AppColors.statusDoneBg),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color, bgColor) = _style;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.5), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text('SYSTÈME', style: AppTextStyles.labelXs.copyWith(color: color, fontSize: 8)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(message.title, style: AppTextStyles.titleSm.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(message.body, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(_formatTime(message.createdAt), style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
        ])),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} min';
    return 'à l\'instant';
  }
}
