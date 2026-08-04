import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../stylist/orders/order_list_widgets.dart' show SavedPhotoThumbnail;

class TailorPhotosScreen extends StatefulWidget {
  const TailorPhotosScreen({super.key});

  @override
  State<TailorPhotosScreen> createState() => _TailorPhotosScreenState();
}

class _TailorPhotosScreenState extends State<TailorPhotosScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
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
                    color: c.onSurfaceVariant,
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
    final c = context.colors;
    final hasModelPhotos = order.modelPhotos != null && order.modelPhotos!.isNotEmpty;
    final hasFabricPhotos = order.fabricPhotos != null && order.fabricPhotos!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: c.softShadow,
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
                        color: c.onSurfaceVariant,
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
                color: c.onSurfaceVariant,
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
                  return SavedPhotoThumbnail(
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
                color: c.onSurfaceVariant,
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
                  return SavedPhotoThumbnail(
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

