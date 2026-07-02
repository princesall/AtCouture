import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/client.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

/// Onglet Clients de l'espace Styliste (compte solo).
///
/// PAS de création manuelle de client : les fiches clients apparaissent
/// AUTOMATIQUEMENT à partir des commandes. Dès qu'une commande est créée avec
/// un nom de client, ce client est ajouté ici (ou sa fiche mise à jour).
class StylistClientsTab extends StatefulWidget {
  const StylistClientsTab({super.key});
  @override
  State<StylistClientsTab> createState() => _StylistClientsTabState();
}

class _StylistClientsTabState extends State<StylistClientsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final atelierId = user.atelierId ?? user.id;
    var clients = CompanyService.instance.clientsOfAtelier(atelierId);

    if (_search.isNotEmpty) {
      clients = clients.where((c) =>
        c.fullName.toLowerCase().contains(_search.toLowerCase()) ||
        c.phone.contains(_search)
      ).toList();
    }

    return Column(children: [
      // ── Header ────────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mes Clients', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          Text('${clients.length} client${clients.length > 1 ? 's' : ''}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      ),
      const SizedBox(height: 12),

      // ── Bandeau info : clients créés depuis les commandes ─────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Vos clients apparaissent automatiquement dès que vous créez une commande.',
              style: AppTextStyles.labelXs.copyWith(color: AppColors.primary),
            )),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      // ── Barre de recherche ────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Rechercher un client...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant, size: 20),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = '')) : null,
          ),
        ),
      ),
      const SizedBox(height: 8),

      // ── Liste clients ─────────────────────────────────────────────────────
      Expanded(
        child: clients.isEmpty
            ? _EmptyClients(hasSearch: _search.isNotEmpty)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                itemCount: clients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ClientCard(client: clients[i], index: i),
              ),
      ),
    ]);
  }
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients({required this.hasSearch});
  final bool hasSearch;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: const Icon(Icons.people_outline, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(hasSearch ? 'Aucun résultat' : 'Aucun client', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Aucun client ne correspond à votre recherche.'
                : 'Créez une commande dans l\'onglet Commandes : le client sera automatiquement ajouté ici.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.index});
  final Client client; final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.4), shape: BoxShape.circle),
          child: Center(child: Text(client.initials, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client.fullName, style: AppTextStyles.titleSm),
          if (client.phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(client.phone, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${client.orderCount} cmd${client.orderCount > 1 ? 's' : ''}', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 10)),
          if (client.totalSpent > 0) ...[
            const SizedBox(height: 2),
            Text('${Formatters.formatCurrency(client.totalSpent)} F', style: AppTextStyles.labelXs.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700)),
          ],
        ]),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms).slideY(begin: 0.04, end: 0);
  }
}
