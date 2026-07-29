import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class TailorPhotosScreen extends StatefulWidget {
  const TailorPhotosScreen({super.key});

  @override
  State<TailorPhotosScreen> createState() => _TailorPhotosScreenState();
}

class _TailorPhotosScreenState extends State<TailorPhotosScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final permissions = user.permissions;
    final orders = OrderService.instance.ordersOfAtelier(user.atelierId!);
    
    // Filtrer les commandes qui ont des photos
    final ordersWithPhotos = orders.where((o) => 
      (o.modelPhotos != null && o.modelPhotos!.isNotEmpty) ||
      (o.fabricPhotos != null && o.fabricPhotos!.isNotEmpty)
    ).toList();

    // Vérifier si l'utilisateur a accès aux photos (0 photo = pas d'accès)
    if (permissions.maxPhotosPerOrder == 0) {
      return SafeArea(
        child: Center(
          child: EmptyState(
            title: 'Photos non disponibles',
            subtitle: permissions.photosLockedMessage,
            icon: Icons.photo_library_outlined,
            action: permissions.isExpired
                ? null
                : ElevatedButton(
                    onPressed: () {
                      // Naviguer vers l'écran d'upgrade
                    },
                    child: const Text('Voir les plans'),
                  ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  'Galerie photos',
                  style: AppTextStyles.headlineLgMobile,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${ordersWithPhotos.length} commande${ordersWithPhotos.length > 1 ? 's' : ''} avec photos',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Liste des photos
          Expanded(
            child: ordersWithPhotos.isEmpty
                ? Center(
                    child: EmptyState(
                      title: 'Aucune photo',
                      subtitle: 'Aucune commande avec photos enregistrées',
                      icon: Icons.photo_library_outlined,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: ordersWithPhotos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final order = ordersWithPhotos[index];
                      return _PhotoCard(
                        order: order,
                      ).animate().fadeIn(delay: (index * 50).ms).slideY();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final hasModelPhotos = order.modelPhotos != null && order.modelPhotos!.isNotEmpty;
    final hasFabricPhotos = order.fabricPhotos != null && order.fabricPhotos!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec info client
          Row(
            children: [
              UserAvatar(
                initials: order.clientName.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.clientName,
                      style: AppTextStyles.titleMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.description ?? 'Sans description',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          
          // Photos du modèle
          if (hasModelPhotos) ...[
            Text(
              'Photos du modèle',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.modelPhotos!.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return _PhotoThumbnail(
                    url: order.modelPhotos![index],
                    label: 'Modèle ${index + 1}',
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Photos du tissu
          if (hasFabricPhotos) ...[
            Text(
              'Photos du tissu',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.fabricPhotos!.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return _PhotoThumbnail(
                    url: order.fabricPhotos![index],
                    label: 'Tissu ${index + 1}',
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.url,
    required this.label,
  });

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _PhotoImage(url: url, width: 300, height: 300),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: _PhotoImage(url: url, width: 100, height: 100)),
            // Label
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiche une photo depuis une URL réseau ou un chemin de fichier local
/// (celui renvoyé par image_picker côté styliste), avec un repli discret si
/// le fichier n'existe plus (ex: démo réinstallée, cache vidé).
class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.url, required this.width, required this.height});
  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Sur le web, image_picker renvoie une URL `blob:` (pas un vrai chemin de
    // fichier) : `dart:io File` n'y fonctionne pas et fait planter l'écran.
    // On charge alors la photo via Image.network, qui sait lire les blob:.
    final isRemote = kIsWeb ||
        url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('blob:');
    final errorFallback = Container(
      width: width,
      height: height,
      color: AppColors.surfaceContainerLow,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: AppColors.onSurfaceVariant),
    );

    if (isRemote) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => errorFallback,
      );
    }
    return Image.file(
      File(url),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => errorFallback,
    );
  }
}
