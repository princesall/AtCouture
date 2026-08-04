import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_color_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/build_context_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/order_messages.dart';
import '../../../core/utils/order_pdf.dart';
import '../../../core/utils/plan_guard.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/company_service.dart';
import '../../../services/order_service.dart';

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

/// Miniature tappable d'une photo déjà enregistrée sur une commande
/// (modelPhotos/fabricPhotos — des chemins/URLs, pas des XFile fraîchement
/// choisis, voir XFileThumbnail pour ce cas). Tap = zoom plein écran.
class SavedPhotoThumbnail extends StatelessWidget {
  const SavedPhotoThumbnail({super.key, required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _SavedPhotoImage(url: url, width: 300, height: 300),
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
      ),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: _SavedPhotoImage(url: url, width: 88, height: 88)),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
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
/// (celui renvoyé par image_picker à la création de la commande), avec un
/// repli discret si le fichier n'existe plus (ex: démo réinstallée, cache
/// vidé, ou commande créée sur un autre appareil).
class _SavedPhotoImage extends StatelessWidget {
  const _SavedPhotoImage({required this.url, required this.width, required this.height});
  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Sur le web, image_picker renvoie une URL `blob:` (pas un vrai chemin de
    // fichier) : `dart:io File` n'y fonctionne pas et fait planter l'écran.
    final isRemote = kIsWeb ||
        url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('blob:');
    final errorFallback = Container(
      width: width,
      height: height,
      color: c.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: c.onSurfaceVariant),
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

void _exportOrderDocument(
  BuildContext context, {
  required bool isAllowed,
  required String lockedMessage,
  required Future<void> Function() generate,
}) {
  if (!PlanGuard.requireFeature(
    context: context,
    isAllowed: isAllowed,
    featureName: 'Documents PDF',
    lockedMessage: lockedMessage,
  )) {
    return;
  }
  generate();
}

/// Feuille de détail complète d'une commande (client, statut, couturier
/// assigné, historique, mesures, prix, photos, contact WhatsApp, export
/// PDF/devis) — partagée entre l'écran Commandes du styliste et la vue des
/// commandes d'un couturier précis (voir StylistTailorsScreen), pour que les
/// deux affichent exactement les mêmes informations. `onChanged` est appelé
/// après toute action qui modifie la commande (changement de statut,
/// réassignation), pour que l'écran appelant rafraîchisse sa liste.
void showOrderDetailSheet(
  BuildContext context,
  Order order, {
  required VoidCallback onChanged,
}) {
  final c = context.colors;
  final hasModelPhotos = order.modelPhotos != null && order.modelPhotos!.isNotEmpty;
  final hasFabricPhotos = order.fabricPhotos != null && order.fabricPhotos!.isNotEmpty;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text('Détails de la commande', style: AppTextStyles.headlineMd),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Client info
                  OrderDetailSection(
                    title: 'Client',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.clientName, style: AppTextStyles.titleMd),
                        const SizedBox(height: 4),
                        Text(
                          order.clientPhone,
                          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  // Statut
                  OrderDetailSection(
                    title: 'Statut',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: orderStatusColor(c, order.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.statusLabel,
                            style: AppTextStyles.labelCaps.copyWith(color: orderStatusColor(c, order.status)),
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<OrderStatus>(
                          value: order.status,
                          items: OrderStatus.values.map((status) {
                            return DropdownMenuItem(value: status, child: Text(status.label));
                          }).toList(),
                          onChanged: (newStatus) async {
                            if (newStatus != null) {
                              final changedBy = context.read<AuthProvider>().user!.fullName;
                              await OrderService.instance.updateOrderStatus(
                                order.id,
                                newStatus,
                                changedByName: changedBy,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              onChanged();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Couturier — assignable ou réassignable à tout moment,
                  // pas seulement à la création de la commande.
                  OrderDetailSection(
                    title: 'Couturier',
                    child: Builder(builder: (context) {
                      final tailors = CompanyService.instance.tailorsOfAtelier(order.atelierId);
                      final currentTailor = tailors.where((t) => t.id == order.tailorId).firstOrNull;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentTailor?.fullName ?? 'Non assigné',
                              style: AppTextStyles.bodySm.copyWith(
                                color: currentTailor == null ? c.onSurfaceVariant : null,
                              ),
                            ),
                          ),
                          DropdownButton<String?>(
                            value: currentTailor?.id,
                            hint: const Text('Assigner'),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('Aucun')),
                              ...tailors.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.fullName))),
                            ],
                            onChanged: (tailorId) async {
                              await OrderService.instance.assignTailor(order.id, tailorId);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              onChanged();
                            },
                          ),
                        ],
                      );
                    }),
                  ),

                  // Historique du statut — quand et par qui, utile pour
                  // mesurer les délais réels et arbitrer les litiges.
                  if (order.statusHistory.isNotEmpty)
                    OrderDetailSection(
                      title: 'Historique du statut',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final change in order.statusHistory.reversed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: orderStatusColor(c, change.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          change.status.label,
                                          style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${Formatters.dateTime.format(change.changedAt)} — ${change.changedByName}',
                                          style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Mesures
                  if (order.measurements != null && order.measurements!.isNotEmpty)
                    OrderDetailSection(
                      title: 'Mesures',
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: order.measurements!.entries.map((entry) {
                          return Chip(
                            label: Text('${entry.key}: ${entry.value}cm'),
                            backgroundColor: c.primary.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                    ),

                  // Description
                  if (order.description != null)
                    OrderDetailSection(title: 'Description', child: Text(order.description!)),

                  // Photos du modèle et du tissu, jointes à la création de
                  // la commande (voir PhotoPickerSection) — jusqu'ici jamais
                  // reconsultables depuis le détail d'une commande.
                  if (hasModelPhotos)
                    OrderDetailSection(
                      title: 'Photos du modèle',
                      child: SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: order.modelPhotos!.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) => SavedPhotoThumbnail(
                            url: order.modelPhotos![i],
                            label: 'Modèle ${i + 1}',
                          ),
                        ),
                      ),
                    ),
                  if (hasFabricPhotos)
                    OrderDetailSection(
                      title: 'Photos du tissu',
                      child: SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: order.fabricPhotos!.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) => SavedPhotoThumbnail(
                            url: order.fabricPhotos![i],
                            label: 'Tissu ${i + 1}',
                          ),
                        ),
                      ),
                    ),

                  // Prix
                  if (order.price != null) ...[
                    OrderDetailSection(
                      title: 'Prix',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.formatCurrency(order.price!),
                            style: AppTextStyles.headlineSm.copyWith(color: c.primary),
                          ),
                          if (order.deposit != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Acompte: ${Formatters.formatCurrency(order.deposit!)}',
                              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reste: ${Formatters.formatCurrency(order.price! - order.deposit!)}',
                              style: AppTextStyles.bodySm.copyWith(color: c.error, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Date de livraison
                  if (order.dueDate != null)
                    OrderDetailSection(title: 'Date de livraison', child: Text(Formatters.date.format(order.dueDate!))),

                  // Date de création
                  if (order.createdAt != null)
                    OrderDetailSection(title: 'Créée le', child: Text(Formatters.date.format(order.createdAt!))),

                  // Contacter le client via WhatsApp — rappel de livraison
                  // (plan Pro et plus, même accès que l'écran Rappels) et
                  // partage du numéro de suivi (libre d'accès).
                  OrderDetailSection(
                    title: 'Contacter le client',
                    child: Builder(builder: (context) {
                      final permissions = context.read<AuthProvider>().user!.permissions;
                      return Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (!PlanGuard.requireFeature(
                                context: context,
                                isAllowed: permissions.hasReminders,
                                featureName: 'Rappels WhatsApp',
                                lockedMessage: permissions.remindersLockedMessage,
                              )) {
                                return;
                              }
                              WhatsAppLauncher.sendMessage(
                                phone: order.clientPhone,
                                message: OrderMessages.reminder(order),
                              );
                            },
                            icon: const Icon(Icons.notifications_active_outlined, size: 18),
                            label: const Text('Rappel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => WhatsAppLauncher.sendMessage(
                              phone: order.clientPhone,
                              message: OrderMessages.tracking(order),
                            ),
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: const Text('Partager le suivi'),
                          ),
                        ),
                      ]);
                    }),
                  ),

                  // Actions — export PDF / devis (plan Pro et plus)
                  OrderDetailSection(
                    title: 'Documents',
                    child: Builder(builder: (context) {
                      final permissions = context.read<AuthProvider>().user!.permissions;
                      final companyId = context.read<AuthProvider>().user!.companyId;
                      return Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportOrderDocument(
                              context,
                              isAllowed: permissions.hasPdfExport,
                              lockedMessage: permissions.pdfExportLockedMessage,
                              generate: () => OrderPdf.shareInvoice(order, companyId: companyId),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: const Text('Exporter PDF'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportOrderDocument(
                              context,
                              isAllowed: permissions.hasQuotes,
                              lockedMessage: permissions.quotesLockedMessage,
                              generate: () => OrderPdf.shareQuote(order, companyId: companyId),
                            ),
                            icon: const Icon(Icons.request_quote_outlined, size: 18),
                            label: const Text('Créer un devis'),
                          ),
                        ),
                      ]);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
