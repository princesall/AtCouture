import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/client.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

/// Vue globale de TOUS les clients de TOUS les ateliers de l'Entreprise.
/// Le Chef Principal voit chaque client, dans quel atelier il est, et peut
/// filtrer par atelier. Il peut aussi ajouter des clients directement dans
/// son propre atelier sans passer par un Chef d'atelier.
class CompanyClientsScreen extends StatefulWidget {
  const CompanyClientsScreen({super.key});
  @override
  State<CompanyClientsScreen> createState() => _CompanyClientsScreenState();
}

class _CompanyClientsScreenState extends State<CompanyClientsScreen> {
  String? _atelierFilter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final ateliers = CompanyService.instance.ateliersOfCompany(user.id);
    var clients = CompanyService.instance.allClientsOfCompany(user.id);

    // Filtre atelier
    if (_atelierFilter != null) {
      clients = clients.where((c) => c.atelierId == _atelierFilter).toList();
    }
    // Filtre recherche
    if (_search.isNotEmpty) {
      clients = clients.where((c) =>
        c.fullName.toLowerCase().contains(_search.toLowerCase()) ||
        c.phone.contains(_search)
      ).toList();
    }

    return Column(children: [
      // ── Header + bouton ajout ─────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tous les Clients', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
            Text('${clients.length} client${clients.length > 1 ? 's' : ''} — vue consolidée', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
          GestureDetector(
            onTap: () => _showAddClientSheet(context, user.id, ateliers),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
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

      // ── Filtres par atelier ───────────────────────────────────────────────
      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _Chip(label: 'TOUS', active: _atelierFilter == null, onTap: () => setState(() => _atelierFilter = null)),
            const SizedBox(width: 8),
            ...ateliers.map((a) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: (a.name).split('—').last.trim().toUpperCase(),
                active: _atelierFilter == a.id,
                onTap: () => setState(() => _atelierFilter = a.id),
              ),
            )),
          ],
        ),
      ),
      const SizedBox(height: 8),

      // ── Liste clients ─────────────────────────────────────────────────────
      Expanded(
        child: clients.isEmpty
            ? Center(child: Text('Aucun client', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                itemCount: clients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ClientCard(client: clients[i], index: i),
              ),
      ),
    ]);
  }

  void _showAddClientSheet(BuildContext ctx, String ownerId, List<dynamic> ateliers) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddClientSheet(ownerId: ownerId, ateliers: ateliers, onAdded: () => setState(() {})),
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
        // Avatar initiales
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.4), shape: BoxShape.circle),
          child: Center(child: Text(client.initials, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client.fullName, style: AppTextStyles.titleSm),
          const SizedBox(height: 2),
          Text(client.phone, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.storefront_outlined, size: 11, color: AppColors.secondary),
            const SizedBox(width: 3),
            Expanded(child: Text(client.atelierName, style: AppTextStyles.labelXs.copyWith(color: AppColors.secondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: active ? AppColors.primary : AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppTextStyles.labelCaps.copyWith(color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant, fontSize: 10)),
    ),
  );
}

class _AddClientSheet extends StatefulWidget {
  const _AddClientSheet({required this.ownerId, required this.ateliers, required this.onAdded});
  final String ownerId; final List<dynamic> ateliers; final VoidCallback onAdded;
  @override State<_AddClientSheet> createState() => _AddClientSheetState();
}
class _AddClientSheetState extends State<_AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _selectedAtelierId;
  String? _selectedAtelierName;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    // Pré-sélectionner l'atelier personnel du Chef
    final personal = widget.ateliers.where((a) => (a.headStylistId as String) == widget.ownerId).firstOrNull;
    if (personal != null) {
      _selectedAtelierId = personal.id as String;
      _selectedAtelierName = personal.name as String;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedAtelierId == null) return;
    await CompanyService.instance.addClient(
      atelierId: _selectedAtelierId!,
      atelierName: _selectedAtelierName!,
      fullName: _name.text,
      phone: _phone.text,
      email: _email.text.isEmpty ? null : _email.text,
    );
    if (!mounted) return;
    setState(() => _added = true);
    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    if (_added) {
      return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.statusDone, size: 56),
        const SizedBox(height: 16),
        Text('Client ajouté !', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('${_name.text} a été ajouté à $_selectedAtelierName.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
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
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nouveau Client', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        Text('Ajouter un client dans un de vos ateliers', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'NOM COMPLET', hintText: 'Prénom Nom'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE', hintText: '+223 70 00 00 00'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'EMAIL (optionnel)', hintText: 'client@email.ml')),
        const SizedBox(height: 18),
        Text('ATELIER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary)),
        const SizedBox(height: 8),
        ...widget.ateliers.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() { _selectedAtelierId = a.id as String; _selectedAtelierName = a.name as String; }),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedAtelierId == a.id ? AppColors.primaryFixed.withValues(alpha: 0.3) : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedAtelierId == a.id ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(a.name as String, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))),
                if (_selectedAtelierId == a.id) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _selectedAtelierId == null ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, disabledBackgroundColor: AppColors.surfaceContainerHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: Text('AJOUTER LE CLIENT', style: AppTextStyles.labelCaps.copyWith(color: _selectedAtelierId == null ? AppColors.onSurfaceVariant : AppColors.onPrimary)),
        )),
      ])),
    );
  }
}
