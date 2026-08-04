import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';

/// Actions de gestion partagées entre les comptes créés avec un mot de passe
/// temporaire (Couturier ET Chef d'atelier — voir CompanyService.createTailor
/// / createAtelierHead) : modifier, suspendre/réactiver, envoyer un lien de
/// réinitialisation, supprimer. Utilisées à la fois par StylistTailorsScreen
/// (couturiers d'un atelier solo) et CompanyAteliersScreen/
/// CompanyTailorsScreen (couturiers ET chefs d'atelier d'une Entreprise), pour
/// que les deux espaces offrent EXACTEMENT les mêmes capacités de gestion.
typedef UpdateAccountFn = Future<void> Function({
  required String id,
  required String fullName,
  required String phone,
  String? email,
});
typedef SetAccountActiveFn = Future<void> Function(String id, bool isActive);
typedef RemoveAccountFn = Future<void> Function(String id);

Future<void> showEditTailorDialog(BuildContext context, AppUser tailor, VoidCallback onChanged) {
  return _showEditAccountDialog(
    context,
    tailor,
    title: 'Modifier le couturier',
    update: ({required id, required fullName, required phone, email}) => CompanyService.instance.updateTailor(
      tailorId: id,
      fullName: fullName,
      phone: phone,
      email: email,
    ),
    onChanged: onChanged,
  );
}

Future<void> showEditAtelierHeadDialog(BuildContext context, AppUser head, VoidCallback onChanged) {
  return _showEditAccountDialog(
    context,
    head,
    title: 'Modifier le chef d\'atelier',
    update: ({required id, required fullName, required phone, email}) => CompanyService.instance.updateAtelierHead(
      headId: id,
      fullName: fullName,
      phone: phone,
      email: email,
    ),
    onChanged: onChanged,
  );
}

Future<void> toggleTailorActive(BuildContext context, AppUser tailor, VoidCallback onChanged) {
  return _toggleAccountActive(
    context,
    tailor,
    label: 'couturier',
    setActive: CompanyService.instance.setTailorActive,
    onChanged: onChanged,
  );
}

Future<void> toggleAtelierHeadActive(BuildContext context, AppUser head, VoidCallback onChanged) {
  return _toggleAccountActive(
    context,
    head,
    label: 'chef d\'atelier',
    setActive: CompanyService.instance.setAtelierHeadActive,
    onChanged: onChanged,
  );
}

Future<void> confirmAndRemoveTailor(BuildContext context, AppUser tailor, VoidCallback onChanged) {
  return _confirmAndRemove(
    context,
    tailor,
    label: 'le couturier',
    remove: CompanyService.instance.removeTailor,
    onChanged: onChanged,
  );
}

Future<void> confirmAndRemoveAtelierHead(BuildContext context, AppUser head, VoidCallback onChanged) {
  return _confirmAndRemove(
    context,
    head,
    label: 'ce chef d\'atelier',
    extraWarning: 'Son atelier sera également supprimé (ses couturiers et données restent, '
        'mais l\'atelier lui-même disparaît).',
    remove: CompanyService.instance.removeAtelierHead,
    onChanged: onChanged,
  );
}

/// Déclenche le vrai flux Firebase d'email de réinitialisation (voir
/// AuthService.sendPasswordResetEmail) — instancié à part plutôt que via
/// AuthProvider.resetPassword pour ne PAS toucher au statut d'authentification
/// de la personne actuellement connectée (styliste ou chef d'entreprise).
Future<void> sendAccountResetLink(BuildContext context, AppUser account) async {
  final c = context.colors;
  try {
    await AuthService().sendPasswordResetEmail(account.email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lien envoyé à ${account.email}')),
    );
  } on AuthException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: c.error),
    );
  }
}

Future<void> _showEditAccountDialog(
  BuildContext context,
  AppUser account, {
  required String title,
  required UpdateAccountFn update,
  required VoidCallback onChanged,
}) {
  final nameController = TextEditingController(text: account.fullName);
  final phoneController = TextEditingController(text: account.phone);
  final emailController = TextEditingController(text: account.email);
  final formKey = GlobalKey<FormState>();

  return showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTextStyles.headlineMd),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const Divider(height: 24),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Email valide requis' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Seul recours en cas de mot de passe oublié — voir
              // AuthService.sendPasswordResetEmail. Ne marche que si l'email
              // ci-dessus est réellement consultable par la personne.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => sendAccountResetLink(dialogContext, account),
                  icon: const Icon(Icons.mail_lock_outlined, size: 18),
                  label: const Text('Envoyer un lien de réinitialisation'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        await update(
                          id: account.id,
                          fullName: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          email: emailController.text.trim(),
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        onChanged();
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
    ),
  );
}

Future<void> _toggleAccountActive(
  BuildContext context,
  AppUser account, {
  required String label,
  required SetAccountActiveFn setActive,
  required VoidCallback onChanged,
}) async {
  if (account.isActive) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Suspendre le $label'),
        content: Text(
          '${account.fullName} ne pourra plus se connecter tant que son compte est suspendu. '
          'Son historique est conservé et vous pourrez le réactiver à tout moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }

  await setActive(account.id, !account.isActive);
  onChanged();
}

Future<void> _confirmAndRemove(
  BuildContext context,
  AppUser account, {
  required String label,
  required RemoveAccountFn remove,
  required VoidCallback onChanged,
  String? extraWarning,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Supprimer $label'),
      content: Text([
        'Voulez-vous vraiment supprimer ${account.fullName} ?',
        ?extraWarning,
      ].join('\n\n')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await remove(account.id);
  onChanged();
}
