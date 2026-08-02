import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
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
    final c = context.colors;

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
            Text('Tous les Clients', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
            Text('${clients.length} client${clients.length > 1 ? 's' : ''} — vue consolidée', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          ])),
          GestureDetector(
            onTap: () => _showAddClientSheet(context, user.id, ateliers),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: c.heroGradient, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
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
            prefixIcon: Icon(Icons.search_rounded, color: c.onSurfaceVariant, size: 20),
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
            ? Center(child: Text('Aucun client', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)))
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
      backgroundColor: ctx.colors.surfaceContainerLowest,
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
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: c.softShadow,
      ),
      child: Row(children: [
        // Avatar initiales
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: c.primaryFixed.withValues(alpha: 0.4), shape: BoxShape.circle),
          child: Center(child: Text(client.initials, style: AppTextStyles.titleSm.copyWith(color: c.primary))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client.fullName, style: AppTextStyles.titleSm),
          const SizedBox(height: 2),
          Text(client.phone, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.storefront_outlined, size: 11, color: c.secondary),
            const SizedBox(width: 3),
            Expanded(child: Text(client.atelierName, style: AppTextStyles.labelXs.copyWith(color: c.secondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${client.orderCount} cmd${client.orderCount > 1 ? 's' : ''}', style: AppTextStyles.labelCaps.copyWith(color: c.primary, fontSize: 10)),
          if (client.totalSpent > 0) ...[
            const SizedBox(height: 2),
            Text('${Formatters.formatCurrency(client.totalSpent)} F', style: AppTextStyles.labelXs.copyWith(color: c.tertiary, fontWeight: FontWeight.w700)),
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
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: active ? c.primary : c.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: AppTextStyles.labelCaps.copyWith(color: active ? c.onPrimary : c.onSurfaceVariant, fontSize: 10)),
      ),
    );
  }
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
  bool _isSubmitting = false;
  final String _idempotencyKey = const Uuid().v4();

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
    if (_isSubmitting || !_formKey.currentState!.validate() || _selectedAtelierId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await CompanyService.instance.addClient(
        atelierId: _selectedAtelierId!,
        atelierName: _selectedAtelierName!,
        fullName: _name.text,
        phone: _phone.text,
        email: _email.text.isEmpty ? null : _email.text,
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      setState(() => _added = true);
      widget.onAdded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du client : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_added) {
      return SuccessConfirmationSheet(
        title: 'Client ajouté !',
        message: '${_name.text} a été ajouté à $_selectedAtelierName.',
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nouveau Client', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
        Text('Ajouter un client dans un de vos ateliers', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'NOM COMPLET', hintText: 'Prénom Nom'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE', hintText: '+223 70 00 00 00'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'EMAIL (optionnel)', hintText: 'client@email.ml')),
        const SizedBox(height: 18),
        Text('ATELIER', style: AppTextStyles.labelCaps.copyWith(color: c.secondary)),
        const SizedBox(height: 8),
        ...widget.ateliers.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() { _selectedAtelierId = a.id as String; _selectedAtelierName = a.name as String; }),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedAtelierId == a.id ? c.primaryFixed.withValues(alpha: 0.3) : c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedAtelierId == a.id ? c.primary.withValues(alpha: 0.4) : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                Icon(Icons.storefront_rounded, size: 18, color: c.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(a.name as String, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))),
                if (_selectedAtelierId == a.id) Icon(Icons.check_circle_rounded, color: c.primary, size: 18),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _selectedAtelierId == null || _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, disabledBackgroundColor: c.surfaceContainerHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: _isSubmitting
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
              : Text('AJOUTER LE CLIENT', style: AppTextStyles.labelCaps.copyWith(color: _selectedAtelierId == null ? c.onSurfaceVariant : c.onPrimary)),
        )),
      ])),
    );
  }
}
