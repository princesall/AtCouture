import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/build_context_colors.dart';

/// Source de vérité UNIQUE pour "cet utilisateur a-t-il le droit de faire X ?".
///
/// Règle absolue : le plan vient TOUJOURS du document utilisateur stocké côté
/// serveur (Firestore `users/{uid}.plan`), jamais d'une valeur locale modifiable,
/// jamais d'un paramètre passé par l'UI elle-même. Quand Firebase sera branché,
/// `PlanGuard` doit lire le plan depuis le AppUser rafraîchi à chaque connexion
/// (déjà le cas via AuthProvider → ne JAMAIS court-circuiter ce flux).
///
/// Toute action sensible (créer un atelier, ajouter un couturier au-delà du
/// quota, etc.) DOIT être enveloppée par `PlanGuard.requireFeature` ou
/// `PlanGuard.requireCapacity` AVANT d'exécuter l'action, pas seulement
/// masquée dans l'UI — ceci est la dernière ligne de défense côté client,
/// en complément des règles Firestore (voir firestore.rules).
class PlanGuard {
  PlanGuard._();

  /// Vérifie qu'une fonctionnalité booléenne est autorisée par le plan.
  /// Si non autorisée : affiche un dialog d'upsell et retourne false.
  /// Si autorisée : retourne true, l'appelant peut procéder.
  static bool requireFeature({
    required BuildContext context,
    required bool isAllowed,
    required String featureName,
    required String lockedMessage,
  }) {
    if (isAllowed) return true;
    _showUpsellDialog(context, featureName: featureName, message: lockedMessage);
    return false;
  }

  /// Vérifie qu'on ne dépasse pas un quota numérique (ex: nb couturiers max).
  static bool requireCapacity({
    required BuildContext context,
    required bool hasCapacity,
    required String resourceName,
    required String lockedMessage,
  }) {
    if (hasCapacity) return true;
    _showUpsellDialog(context, featureName: resourceName, message: lockedMessage);
    return false;
  }

  static void _showUpsellDialog(BuildContext context, {required String featureName, required String message}) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(gradient: c.goldGradient, shape: BoxShape.circle),
          child: Icon(Icons.lock_rounded, color: c.onTertiary, size: 26),
        ),
        title: Text(
          'Fonctionnalité verrouillée',
          style: AppTextStyles.titleMd.copyWith(color: c.primary),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('COMPRIS', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('CONTACTER L\'ADMIN', style: AppTextStyles.labelCaps.copyWith(color: c.onPrimary)),
          ),
        ],
      ),
    );
  }
}

/// Écran de secours affiché QUAND UN ÉCRAN PREMIUM EST OUVERT DIRECTEMENT
/// sans passer par son point d'entrée normal (qui filtre déjà via
/// PlanGuard.requireFeature — voir ProfileTabContent). Deuxième ligne de
/// défense pour CompanyCustomizationScreen/CompanyDataExportScreen/
/// CompanyDedicatedManagerScreen : ces écrans n'ont aujourd'hui qu'un seul
/// point d'entrée protégé, mais rien ne garantit que ça reste vrai si un
/// futur lien direct est ajouté — jamais la SEULE protection, toujours en
/// plus du point d'entrée existant.
class PlanLockedScreen extends StatelessWidget {
  const PlanLockedScreen({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: c.background,
        foregroundColor: c.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(gradient: c.goldGradient, shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, color: c.onTertiary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Fonctionnalité verrouillée',
                style: AppTextStyles.titleMd.copyWith(color: c.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Petit badge "cadenas" à poser sur un bouton/icône désactivé par le plan,
/// pour que l'utilisateur comprenne immédiatement pourquoi c'est grisé.
class PlanLockBadge extends StatelessWidget {
  const PlanLockBadge({super.key, this.size = 14});
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(size * 0.25),
      decoration: BoxDecoration(gradient: c.goldGradient, shape: BoxShape.circle),
      child: Icon(Icons.lock_rounded, size: size, color: c.onTertiary),
    );
  }
}
