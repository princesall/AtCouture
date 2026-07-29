import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/client.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class StylistClientsScreen extends StatefulWidget {
  const StylistClientsScreen({super.key});

  @override
  State<StylistClientsScreen> createState() => _StylistClientsScreenState();
}

class _StylistClientsScreenState extends State<StylistClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> _getFilteredClients(String atelierId) {
    final clients = OrderService.instance.clientsOfAtelier(atelierId);
    if (_searchQuery.isEmpty) return clients;
    
    return OrderService.instance.searchClients(_searchQuery, atelierId);
  }

  void _showClientDetails(Client client) {
    final orders = OrderService.instance.ordersOfClient(client.id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    UserAvatar(initials: client.initials, size: 60),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.fullName, style: AppTextStyles.headlineMd),
                          const SizedBox(height: 4),
                          Text(
                            client.phone,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (client.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              client.email!,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Stats
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Commandes',
                        value: '${client.orderCount}',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        label: 'Total dépensé',
                        value: Formatters.formatCurrency(client.totalSpent),
                        icon: Icons.payments_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Commandes du client
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: EmptyState(
                          title: 'Aucune commande',
                          subtitle: 'Ce client n\'a pas encore de commande',
                          icon: Icons.receipt_long_outlined,
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _OrderCard(order: order);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddClientDialog() {
    final user = context.read<AuthProvider>().user!;
    final permissions = user.permissions;
    final currentClients = OrderService.instance.clientsOfAtelier(user.atelierId!).length;
    
    // Vérifier si l'utilisateur peut ajouter des clients
    if (!permissions.canAddClient(currentClients)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limite atteinte'),
          content: Text(permissions.canAddClientMessage),
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

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || 
                  phoneController.text.trim().isEmpty) {
                return;
              }

              OrderService.instance.addClient(
                atelierId: user.atelierId!,
                atelierName: user.atelierName!,
                fullName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
              );

              Navigator.pop(context);
              setState(() {}); // Refresh
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final clients = _getFilteredClients(user.atelierId!);

    return SafeArea(
      child: Column(
        children: [
          // Header avec recherche
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Clients',
                      style: AppTextStyles.headlineLgMobile,
                    ),
                    const Spacer(),
                    Text(
                      '${clients.length} client${clients.length > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showAddClientDialog,
                      tooltip: 'Ajouter un client',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par nom ou téléphone',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ],
            ),
          ),
          // Liste des clients
          Expanded(
            child: clients.isEmpty
                ? Center(
                    child: EmptyState(
                      title: 'Aucun client',
                      subtitle: _searchQuery.isEmpty
                          ? 'Commencez par ajouter votre premier client'
                          : 'Aucun client ne correspond à votre recherche',
                      icon: Icons.people_outline,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: clients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return _ClientCard(
                        client: client,
                        onTap: () => _showClientDetails(client),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onTap,
  });

  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            UserAvatar(initials: client.initials, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.fullName,
                    style: AppTextStyles.titleMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.phone,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${client.orderCount} commande${client.orderCount > 1 ? 's' : ''}',
                        style: AppTextStyles.labelXs.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusLabel,
                  style: AppTextStyles.labelXs.copyWith(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (order.price != null)
                Text(
                  Formatters.formatCurrency(order.price!),
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          if (order.description != null) ...[
            const SizedBox(height: 8),
            Text(
              order.description!,
              style: AppTextStyles.bodySm,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (order.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Créée le ${Formatters.date.format(order.createdAt!)}',
              style: AppTextStyles.labelXs.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.tertiary;
      case OrderStatus.inProgress:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.secondary;
      case OrderStatus.problem:
        return AppColors.success;
    }
  }
}
