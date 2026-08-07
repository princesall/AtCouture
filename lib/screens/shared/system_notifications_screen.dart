import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
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
  void initState() {
    super.initState();
    // Marquer "lu" est un effet de bord (écriture Firestore) : ne doit
    // jamais se déclencher depuis itemBuilder, appelé en plein cycle de
    // build (potentiellement plusieurs fois par frame). On le fait une
    // seule fois, après le premier rendu de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllRead());
  }

  void _markAllRead() {
    final user = context.read<AuthProvider>().user!;
    for (final m in SubscriptionService.instance.systemMessagesFor(user.id)) {
      if (!m.isRead) {
        SubscriptionService.instance.markSystemMessageRead(user.id, m.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    final messages = SubscriptionService.instance.systemMessagesFor(user.id);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
      ),
      body: messages.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_off_outlined, color: c.onSurfaceVariant, size: 48),
                const SizedBox(height: 12),
                Text('Aucune notification', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
              ]),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _SystemMessageCard(message: messages[i]),
            ),
    );
  }
}

class _SystemMessageCard extends StatelessWidget {
  const _SystemMessageCard({required this.message});
  final SystemMessage message;

  (IconData, Color, Color) _style(AppColorPalette c) => switch (message.type) {
        SystemMessageType.subscriptionApproved => (Icons.check_circle_rounded, c.statusDone, c.statusDoneBg),
        SystemMessageType.subscriptionRejected => (Icons.cancel_rounded, c.error, c.errorContainer),
        SystemMessageType.subscriptionExpired => (Icons.warning_amber_rounded, c.statusInProgress, c.statusInProgressBg),
        SystemMessageType.subscriptionRenewed => (Icons.autorenew_rounded, c.statusDone, c.statusDoneBg),
        SystemMessageType.accountCreated => (Icons.celebration_rounded, c.tertiary, c.tertiaryFixed),
        SystemMessageType.accountDeactivated => (Icons.block_rounded, c.error, c.errorContainer),
        SystemMessageType.accountReactivated => (Icons.check_circle_rounded, c.statusDone, c.statusDoneBg),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, color, bgColor) = _style(c);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: c.softShadow,
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
          Text(message.body, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(_formatTime(message.createdAt), style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant.withValues(alpha: 0.6))),
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
