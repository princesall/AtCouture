import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/premium_button.dart';
import '../../models/app_user.dart';
import '../../models/support_message.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../services/support_message_service.dart';

/// Signalement d'un problème à l'admin + historique des échanges avec leurs
/// réponses. Accessible depuis le profil styliste/entreprise/couturier.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactSupportScreen()));
  }

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _contentController = TextEditingController();
  bool _isSending = false;
  String _idempotencyKey = const Uuid().v4();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _send(String senderId, String senderName, String senderRole) async {
    if (_isSending || _contentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    await SupportMessageService.instance.send(
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: _contentController.text,
      idempotencyKey: _idempotencyKey,
    );
    if (!mounted) return;
    setState(() {
      _contentController.clear();
      _isSending = false;
      // Nouvelle clé pour le prochain envoi — l'ancienne reste associée au
      // message qui vient d'être créé.
      _idempotencyKey = const Uuid().v4();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message envoyé à l\'assistance')),
    );
  }

  String _roleLabel(AppUser user) {
    if (user.isCompanyOwner) return 'Chef d\'Entreprise — ${user.atelierName ?? ''}';
    if (user.role == UserRole.tailor) return 'Couturier — ${user.atelierName ?? ''}';
    return 'Styliste — ${user.atelierName ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    // Réagit en direct dès que l'admin répond, pendant que cet écran est
    // déjà ouvert (voir SupportMessageService, désormais un ChangeNotifier).
    return ListenableBuilder(
      listenable: SupportMessageService.instance,
      builder: (context, _) => _buildScaffold(context, user),
    );
  }

  Widget _buildScaffold(BuildContext context, AppUser user) {
    final c = context.colors;
    final myMessages = SupportMessageService.instance.messagesFrom(user.id);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Assistance', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Décrivez votre problème, un administrateur vous répondra ici même.',
            style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _contentController,
            maxLines: 4,
            enabled: !_isSending,
            decoration: InputDecoration(
              hintText: 'Ex : je n\'arrive pas à ajouter une photo à une commande...',
              filled: true,
              fillColor: c.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.outlineVariant.withValues(alpha: 0.4))),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PremiumButton(
            label: 'Envoyer',
            isLoading: _isSending,
            onPressed: _isSending ? null : () => _send(user.id, user.fullName, _roleLabel(user)),
          ),

          if (myMessages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('MES MESSAGES', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.sm),
            ...myMessages.map((m) => _MyMessageCard(message: m)),
          ],
        ],
      ),
    );
  }
}

class _MyMessageCard extends StatelessWidget {
  const _MyMessageCard({required this.message});
  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: c.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.content, style: AppTextStyles.bodySm),
        const SizedBox(height: 8),
        if (message.isReplied) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.primaryFixed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Réponse de l\'assistance', style: AppTextStyles.labelXs.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(message.reply!, style: AppTextStyles.bodySm),
            ]),
          ),
        ] else
          Row(children: [
            Icon(Icons.hourglass_empty_rounded, size: 14, color: c.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('En attente de réponse', style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant)),
          ]),
      ]),
    );
  }
}
