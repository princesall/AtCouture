import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/order_messages.dart';
import '../../core/utils/whatsapp_launcher.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
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
                            onTap: () => showOrderDetailSheet(context, order, onChanged: () => setState(() {})),
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

