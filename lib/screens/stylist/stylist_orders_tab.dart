import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

/// Onglet Commandes de l'espace Styliste (compte solo).
///
/// La création d'une commande fait apparaître AUTOMATIQUEMENT son client dans
/// l'onglet Clients : le styliste n'a jamais besoin de créer une fiche client
/// séparément, il saisit simplement le nom du client dans la commande (voir
/// CompanyService.addOrder).
class StylistOrdersTab extends StatefulWidget {
  const StylistOrdersTab({super.key});
  @override
  State<StylistOrdersTab> createState() => StylistOrdersTabState();
}

class StylistOrdersTabState extends State<StylistOrdersTab> {
  int _statusFilter = 0; // 0=Tous, 1=En cours, 2=Terminé, 3=Problème
  static const _statusLabels = ['TOUT', 'EN COURS', 'TERMINÉ', 'PROBLÈME'];

  OrderStatus _toStatus(String s) => switch (s) {
    'done'       => OrderStatus.done,
    'inProgress' => OrderStatus.inProgress,
    'problem'    => OrderStatus.problem,
    _            => OrderStatus.pending,
  };

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final atelierId = user.atelierId ?? user.id;
    var orders = CompanyService.instance.ordersOfAtelier(atelierId);

    if (_statusFilter > 0) {
      final statusStr = switch (_statusFilter) { 2 => 'done', 3 => 'problem', _ => 'inProgress' };
      orders = orders.where((o) => o.status == statusStr).toList();
    }
    orders = orders.reversed.toList();
    final totalRevenue = orders.fold(0, (sum, o) => sum + o.price);

    return Column(children: [
      // ── Header + bouton ajout ─────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes Commandes', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
            Text('${orders.length} commande${orders.length > 1 ? 's' : ''} · ${Formatters.formatCurrency(totalRevenue)} FCFA', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
          GestureDetector(
            onTap: openCreateOrder,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
              child: const Icon(Icons.add_box_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // ── Filtres statut ────────────────────────────────────────────────────
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _statusLabels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
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

      // ── Liste commandes ───────────────────────────────────────────────────
      Expanded(
        child: orders.isEmpty
            ? _EmptyOrders(onAdd: openCreateOrder)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _OrderCard(order: orders[i], index: i, toStatus: _toStatus),
              ),
      ),
    ]);
  }

  /// Ouvre le formulaire de nouvelle commande. Public pour pouvoir être
  /// déclenché depuis le shell (FAB) via une GlobalKey.
  void openCreateOrder() {
    final user = context.read<AuthProvider>().user!;
    final atelierId = user.atelierId ?? user.id;
    final atelierName = user.atelierName ?? 'Mon atelier';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddOrderSheet(
        atelierId: atelierId,
        atelierName: atelierName,
        onAdded: () => setState(() {}),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Aucune commande', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('Créez une commande : le client sera automatiquement ajouté à votre espace Clients.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_box_rounded, size: 18),
            label: Text('NOUVELLE COMMANDE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), elevation: 0),
          ),
        ]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.index, required this.toStatus});
  final CompanyOrder order; final int index;
  final OrderStatus Function(String) toStatus;

  @override
  Widget build(BuildContext context) {
    final status = toStatus(order.status);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.35), shape: BoxShape.circle),
              child: Center(child: Text(
                order.clientName.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase(),
                style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.clientName, style: AppTextStyles.titleSm),
              Text(order.garment, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${Formatters.formatCurrency(order.price)} F', style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 13)),
              const SizedBox(height: 4),
              StatusBadge(status),
            ]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.content_cut_outlined, size: 12, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(order.tailorName, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
            const Spacer(),
            Text(Formatters.date.format(order.date), style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
          ]),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms).slideY(begin: 0.04, end: 0);
  }
}

class _AddOrderSheet extends StatefulWidget {
  const _AddOrderSheet({required this.atelierId, required this.atelierName, required this.onAdded});
  final String atelierId; final String atelierName; final VoidCallback onAdded;
  @override State<_AddOrderSheet> createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<_AddOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _client = TextEditingController();
  final _phone = TextEditingController();
  final _garment = TextEditingController();
  final _price = TextEditingController();
  String? _tailorName;
  bool _added = false;

  @override
  void dispose() {
    _client.dispose();
    _phone.dispose();
    _garment.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    CompanyService.instance.addOrder(
      atelierId: widget.atelierId,
      atelierName: widget.atelierName,
      clientName: _client.text,
      clientPhone: _phone.text,
      garment: _garment.text,
      price: price,
      tailorName: _tailorName ?? 'Non assigné',
    );
    setState(() => _added = true);
    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    final tailors = CompanyService.instance.tailorsOfAtelier(widget.atelierId);

    if (_added) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.statusDone, size: 56),
          const SizedBox(height: 16),
          Text('Commande créée !', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('${_client.text} a été ajouté à vos clients automatiquement.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
            child: Text('FERMER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
          )),
        ]),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nouvelle Commande', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          Text('Le client sera ajouté automatiquement à votre espace Clients', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          TextFormField(controller: _client, decoration: const InputDecoration(labelText: 'NOM DU CLIENT', hintText: 'Prénom Nom'), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE CLIENT (optionnel)', hintText: '+223 70 00 00 00')),
          const SizedBox(height: 14),
          TextFormField(controller: _garment, decoration: const InputDecoration(labelText: 'MODÈLE / VÊTEMENT', hintText: 'Ex : Boubou brodé'), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PRIX (FCFA)', hintText: 'Ex : 75000'), validator: (v) {
            final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
            return n == null || n <= 0 ? 'Prix invalide' : null;
          }),
          if (tailors.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('COUTURIER ASSIGNÉ (optionnel)', style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _tailorChip('Non assigné', _tailorName == null, () => setState(() => _tailorName = null)),
              ...tailors.map((t) => _tailorChip(t.fullName, _tailorName == t.fullName, () => setState(() => _tailorName = t.fullName))),
            ]),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
            child: Text('CRÉER LA COMMANDE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
          )),
        ])),
      ),
    );
  }

  Widget _tailorChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: AppTextStyles.labelCaps.copyWith(color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant, fontSize: 10)),
      ),
    );
  }
}
