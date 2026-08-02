import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_color_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/build_context_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';

Color orderStatusColor(AppColorPalette c, OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return c.tertiary;
    case OrderStatus.inProgress:
      return c.primary;
    case OrderStatus.completed:
      return c.secondary;
    case OrderStatus.problem:
      return c.success;
  }
}

class OrderFilterChip extends StatelessWidget {
  const OrderFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: c.primary.withValues(alpha: 0.2),
      checkmarkColor: c.primary,
      labelStyle: AppTextStyles.labelCaps.copyWith(
        color: isSelected ? c.primary : c.onSurfaceVariant,
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                        order.clientPhone,
                        style: AppTextStyles.bodySm.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: orderStatusColor(c, order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: AppTextStyles.labelXs.copyWith(
                      color: orderStatusColor(c, order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (order.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                order.description!,
                style: AppTextStyles.bodySm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (order.price != null) ...[
                  Text(
                    Formatters.formatCurrency(order.price!),
                    style: AppTextStyles.titleSm.copyWith(
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (order.createdAt != null)
                  Text(
                    Formatters.date.format(order.createdAt!),
                    style: AppTextStyles.labelXs.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: c.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre en petites capitales + contenu, utilisé pour chaque bloc du détail
/// d'une commande (Client, Statut, Couturier, Mesures, Prix...).
class OrderDetailSection extends StatelessWidget {
  const OrderDetailSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelCaps.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// ── Sélecteur de photos (modèle / tissu) ─────────────────────────────────────
// remainingSlots == null signifie "illimité" (plan Entreprise).
class PhotoPickerSection extends StatelessWidget {
  const PhotoPickerSection({
    super.key,
    required this.label,
    required this.photos,
    required this.remainingSlots,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<XFile> photos;
  final int? remainingSlots;
  final ValueChanged<List<XFile>> onAdd;
  final ValueChanged<XFile> onRemove;

  Future<void> _pick(BuildContext context) async {
    final limit = remainingSlots;
    if (limit != null && limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite de photos par commande atteinte pour votre plan')),
      );
      return;
    }
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    onAdd(limit == null ? picked : picked.take(limit).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: const Text('Ajouter'),
          ),
        ]),
        if (photos.isNotEmpty)
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final file = photos[i];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: XFileThumbnail(file: file, size: 64),
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: GestureDetector(
                        onTap: () => onRemove(file),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: context.colors.error, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Miniature d'une photo tout juste sélectionnée. Utilise `XFile.readAsBytes`
/// (au lieu de `dart:io File`) car sur le web, `File(path)` plante : le
/// chemin renvoyé par image_picker y est une URL `blob:`, pas un vrai fichier
/// sur disque.
class XFileThumbnail extends StatelessWidget {
  const XFileThumbnail({super.key, required this.file, required this.size});
  final XFile file;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: size,
            height: size,
            color: context.colors.surfaceContainerLow,
          );
        }
        return Image.memory(snapshot.data!, width: size, height: size, fit: BoxFit.cover);
      },
    );
  }
}
