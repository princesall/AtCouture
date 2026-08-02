import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_messages.dart';
import '../../core/utils/order_pdf.dart';
import '../../core/utils/plan_guard.dart';
import '../../core/utils/whatsapp_launcher.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../../services/order_service.dart';
import 'orders/create_order_dialog.dart';
import 'orders/order_list_widgets.dart';

class StylistOrdersScreen extends StatefulWidget {
  const StylistOrdersScreen({super.key});

  @override
  State<StylistOrdersScreen> createState() => _StylistOrdersScreenState();
}

class _StylistOrdersScreenState extends State<StylistOrdersScreen> {
  OrderStatus? _selectedStatus;

  List<Order> _getFilteredOrders(String atelierId) {
    final orders = OrderService.instance.ordersOfAtelier(atelierId);
    if (_selectedStatus == null) return orders;
    return orders.where((o) => o.status == _selectedStatus).toList();
  }

  void _showCreateOrderDialog() async {
    final user = context.read<AuthProvider>().user!;
    final permissions = user.permissions;
    final currentOrders = OrderService.instance.ordersOfAtelier(user.atelierId!).length;
    
    // Vérifier si l'utilisateur peut créer des commandes
    if (!permissions.canAddOrder(currentOrders)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limite atteinte'),
          content: Text(permissions.canAddOrderMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await showDialog<CreateOrderResult>(
      context: context,
      builder: (context) => CreateOrderDialog(user: user),
    );

    if (result == null || !mounted) return;

    // Afficher un message selon si le client existait déjà, avec un
    // raccourci pour envoyer tout de suite le numéro de suivi au client par
    // WhatsApp.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isNewClient
              ? 'Commande créée - Nouveau client ajouté'
              : 'Commande créée - Client existant réutilisé',
        ),
        backgroundColor: context.colors.success,
        action: SnackBarAction(
          label: 'Envoyer via WhatsApp',
          textColor: Colors.white,
          onPressed: () => WhatsAppLauncher.sendMessage(
            phone: result.order.clientPhone,
            message: OrderMessages.tracking(result.order),
          ),
        ),
      ),
    );

    setState(() {}); // Refresh
  }

  void _showOrderDetails(Order order) {
    final c = context.colors;
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
                    Text(
                      'Détails de la commande',
                      style: AppTextStyles.headlineMd,
                    ),
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
                          Text(
                            order.clientName,
                            style: AppTextStyles.titleMd,
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
                    
                    // Statut
                    OrderDetailSection(
                      title: 'Statut',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: orderStatusColor(c, order.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: AppTextStyles.labelCaps.copyWith(
                                color: orderStatusColor(c, order.status),
                              ),
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<OrderStatus>(
                            value: order.status,
                            items: OrderStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              );
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
                                setState(() {});
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
                                setState(() {});
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
                                          Text(change.status.label, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
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
                      OrderDetailSection(
                        title: 'Description',
                        child: Text(order.description!),
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
                              style: AppTextStyles.headlineSm.copyWith(
                                color: c.primary,
                              ),
                            ),
                            if (order.deposit != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Acompte: ${Formatters.formatCurrency(order.deposit!)}',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reste: ${Formatters.formatCurrency(order.price! - order.deposit!)}',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: c.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    
                    // Date de livraison
                    if (order.dueDate != null)
                      OrderDetailSection(
                        title: 'Date de livraison',
                        child: Text(Formatters.date.format(order.dueDate!)),
                      ),
                    
                    // Date de création
                    if (order.createdAt != null)
                      OrderDetailSection(
                        title: 'Créée le',
                        child: Text(Formatters.date.format(order.createdAt!)),
                      ),

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
                              onPressed: () => _exportDocument(
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
                              onPressed: () => _exportDocument(
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

  void _exportDocument(
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    final orders = _getFilteredOrders(user.atelierId!);

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Commandes',
                          style: AppTextStyles.headlineLgMobile,
                        ),
                        const Spacer(),
                        Text(
                          '${orders.length} commande${orders.length > 1 ? 's' : ''}',
                          style: AppTextStyles.bodySm.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          OrderFilterChip(
                            label: 'Toutes',
                            isSelected: _selectedStatus == null,
                            onTap: () => setState(() => _selectedStatus = null),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ...OrderStatus.values.map((status) {
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: OrderFilterChip(
                                label: status.label,
                                isSelected: _selectedStatus == status,
                                onTap: () => setState(() => _selectedStatus = status),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Liste des commandes
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: EmptyState(
                          title: 'Aucune commande',
                          subtitle: _selectedStatus == null
                              ? 'Créez votre première commande'
                              : 'Aucune commande avec ce statut',
                          icon: Icons.receipt_long_outlined,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg).copyWith(bottom: 100),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return OrderCard(
                            order: order,
                            onTap: () => _showOrderDetails(order),
                          ).animate().fadeIn(delay: (index * 50).ms).slideY();
                        },
                      ),
              ),
            ],
          ),
        ),
        // FAB — bottom:92 pour rester au-dessus de la GlassNavBar flottante
        // (voir StylistShell) ; à bottom:20 le bouton était caché SOUS la
        // barre de navigation et donc impossible à toucher.
        Positioned(
          bottom: 92,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: _showCreateOrderDialog,
            backgroundColor: c.secondary,
            foregroundColor: c.onSecondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.add),
            label: Text('Commande', style: AppTextStyles.labelCaps.copyWith(color: c.onSecondary)),
          ),
        ),
      ],
    );
  }
}

