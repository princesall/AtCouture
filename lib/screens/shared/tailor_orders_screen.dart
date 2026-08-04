import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../services/order_service.dart';
import '../stylist/orders/order_list_widgets.dart';

/// Commandes assignées à un couturier précis, ouvert depuis
/// StylistTailorsScreen ou CompanyAteliersScreen/CompanyTailorsScreen.
/// Réutilise exactement le même détail de commande (showOrderDetailSheet)
/// que l'écran Commandes général, pour que le styliste/chef d'entreprise
/// retrouve toutes les informations (statut, mesures, prix, photos...) sans
/// avoir à changer d'écran.
class TailorOrdersScreen extends StatefulWidget {
  const TailorOrdersScreen({super.key, required this.tailor});

  final AppUser tailor;

  @override
  State<TailorOrdersScreen> createState() => _TailorOrdersScreenState();
}

class _TailorOrdersScreenState extends State<TailorOrdersScreen> {
  OrderStatus? _selectedStatus;

  List<Order> _filteredOrders() {
    final orders = OrderService.instance.ordersOfTailor(
      atelierId: widget.tailor.atelierId!,
      tailorId: widget.tailor.id,
    );
    if (_selectedStatus == null) return orders;
    return orders.where((o) => o.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orders = _filteredOrders();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(widget.tailor.fullName),
        backgroundColor: c.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Text(
                    '${orders.length} commande${orders.length > 1 ? 's' : ''}',
                    style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: EmptyState(
                        title: 'Aucune commande',
                        subtitle: _selectedStatus == null
                            ? '${widget.tailor.firstName} n\'a aucune commande assignée'
                            : 'Aucune commande avec ce statut',
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                      ),
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
    );
  }
}
