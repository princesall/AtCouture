import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_pdf.dart';
import '../../core/utils/plan_guard.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';


/// Vue globale de TOUTES les commandes de TOUS les ateliers,
/// filtrables par atelier et par statut, avec couturier assigné visible.
class CompanyOrdersScreen extends StatefulWidget {
  const CompanyOrdersScreen({super.key});
  @override
  State<CompanyOrdersScreen> createState() => _CompanyOrdersScreenState();
}

class _CompanyOrdersScreenState extends State<CompanyOrdersScreen> {
  String? _atelierFilter;
  int _statusFilter = 0; // 0=Tous, 1=En cours, 2=Terminé, 3=Problème

  static const _statusLabels = ['TOUT', 'EN COURS', 'TERMINÉ', 'PROBLÈME'];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final ateliers = CompanyService.instance.ateliersOfCompany(user.id);
    var orders = CompanyService.instance.allOrdersOfCompany(user.id);

    if (_atelierFilter != null) {
      orders = orders.where((o) => o.atelierId == _atelierFilter).toList();
    }
    if (_statusFilter > 0) {
      final status = switch (_statusFilter) {
        2 => OrderStatus.completed,
        3 => OrderStatus.problem,
        _ => OrderStatus.inProgress,
      };
      orders = orders.where((o) => o.status == status).toList();
    }

    final totalRevenue = orders.fold(0, (sum, o) => sum + (o.price ?? 0));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Toutes les Commandes', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
            Text('${orders.length} commandes · ${Formatters.formatCurrency(totalRevenue)} FCFA', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
        ]),
      ),

      // ── Filtres statut ────────────────────────────────────────────────────
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _statusLabels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == _statusFilter;
            return GestureDetector(
              onTap: () => setState(() => _statusFilter = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(_statusLabels[i], style: AppTextStyles.labelCaps.copyWith(
                  color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant, fontSize: 10)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),

      // ── Filtres atelier ───────────────────────────────────────────────────
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _AtelierChip(label: 'TOUS LES ATELIERS', active: _atelierFilter == null, onTap: () => setState(() => _atelierFilter = null)),
            const SizedBox(width: 6),
            ...ateliers.map((a) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _AtelierChip(
                label: (a.name).split('—').last.trim(),
                active: _atelierFilter == a.id,
                onTap: () => setState(() => _atelierFilter = a.id),
              ),
            )),
          ],
        ),
      ),
      const SizedBox(height: 8),

      // ── Liste commandes ───────────────────────────────────────────────────
      Expanded(
        child: orders.isEmpty
            ? Center(child: Text('Aucune commande', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _OrderCard(order: orders[i], index: i),
              ),
      ),
    ]);
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.index});
  final Order order; final int index;

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final tailorName = CompanyService.instance.tailorNameForOrder(order) ?? 'Non assigné';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(children: [
        // Ligne principale
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            // Avatar client initiales
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.35), shape: BoxShape.circle),
              child: Center(child: Text(
                (order.clientName).split(' ').take(2).map((p) => p[0]).join().toUpperCase(),
                style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.clientName, style: AppTextStyles.titleSm),
              Text(order.description ?? 'Vêtement non précisé', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${Formatters.formatCurrency(order.price ?? 0)} F', style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 13)),
              const SizedBox(height: 4),
              StatusBadge(status),
            ]),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant, size: 18),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pdf', child: Text('Exporter en PDF')),
                PopupMenuItem(value: 'quote', child: Text('Créer un devis')),
              ],
              onSelected: (value) => _handleDocumentAction(context, value, order),
            ),
          ]),
        ),
        // Footer : atelier + couturier
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.storefront_outlined, size: 12, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(order.atelierName, style: AppTextStyles.labelXs.copyWith(color: AppColors.secondary)),
            const SizedBox(width: 12),
            const Icon(Icons.content_cut_outlined, size: 12, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(tailorName, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
            const Spacer(),
            if (order.createdAt != null)
              Text(Formatters.date.format(order.createdAt!), style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
          ]),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms).slideY(begin: 0.04, end: 0);
  }

  void _handleDocumentAction(BuildContext context, String action, Order order) {
    final user = context.read<AuthProvider>().user!;
    final permissions = user.permissions;
    final isAllowed = action == 'pdf' ? permissions.hasPdfExport : permissions.hasQuotes;
    final lockedMessage = action == 'pdf' ? permissions.pdfExportLockedMessage : permissions.quotesLockedMessage;

    if (!PlanGuard.requireFeature(
      context: context,
      isAllowed: isAllowed,
      featureName: 'Documents PDF',
      lockedMessage: lockedMessage,
    )) {
      return;
    }
    if (action == 'pdf') {
      OrderPdf.shareInvoice(order, companyId: user.companyId);
    } else {
      OrderPdf.shareQuote(order, companyId: user.companyId);
    }
  }
}

class _AtelierChip extends StatelessWidget {
  const _AtelierChip({required this.label, required this.active, required this.onTap});
  final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.surfaceTint.withValues(alpha: 0.15) : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? AppColors.surfaceTint.withValues(alpha: 0.4) : Colors.transparent),
      ),
      child: Text(label, style: AppTextStyles.labelXs.copyWith(color: active ? AppColors.surfaceTint : AppColors.onSurfaceVariant, fontSize: 10)),
    ),
  );
}
