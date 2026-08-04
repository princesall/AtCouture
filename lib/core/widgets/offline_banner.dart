import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connectivity_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/build_context_colors.dart';

/// Bandeau discret affiché en haut d'un tableau de bord quand l'appareil n'a
/// plus de connexion réseau. Les données restent consultables/modifiables
/// (cache Firestore hors-ligne) — c'est une simple information, pas un
/// blocage de l'interface.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<ConnectivityProvider>().isOffline;
    if (!isOffline) return const SizedBox.shrink();

    final c = context.colors;
    return Container(
      width: double.infinity,
      color: c.error,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: c.onError),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Hors ligne — vos modifications seront synchronisées au retour du réseau',
              style: AppTextStyles.labelXs.copyWith(color: c.onError),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
