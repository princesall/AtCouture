import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../../services/order_service.dart';
import '../admin/admin_dashboard.dart' show StylistAvatar;
import '../shared/staff_account_actions.dart';
import '../shared/tailor_orders_screen.dart';

/// Liste des Ateliers de l'Entreprise + création de nouveaux Chefs d'atelier
/// ET de Couturiers. Le Chef d'Entreprise possède TOUS les pouvoirs d'un
/// Chef d'atelier classique : il a son propre "atelier personnel" (créé
/// automatiquement à l'activation du plan Entreprise) où il peut continuer
/// à travailler directement avec ses propres clients, sans être obligé de
/// déléguer à un Chef d'atelier. Il peut aussi ajouter des couturiers
/// directement à N'IMPORTE QUEL atelier de son Entreprise, y compris le sien.
class CompanyAteliersScreen extends StatefulWidget {
  const CompanyAteliersScreen({super.key});
  @override
  State<CompanyAteliersScreen> createState() => _CompanyAteliersScreenState();
}

class _CompanyAteliersScreenState extends State<CompanyAteliersScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final permissions = user.permissions;
    final ateliers = CompanyService.instance.ateliersOfCompany(user.id);
    final c = context.colors;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes Ateliers', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
            Text('${ateliers.length} maison${ateliers.length > 1 ? 's' : ''} de couture', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          ])),
          if (permissions.canCreateAtelierHead)
            GestureDetector(
              onTap: () => _showCreateAtelierSheet(context, user.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: c.heroGradient, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 22),
              ),
            ),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          itemCount: ateliers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _AtelierCard(
            atelier: ateliers[i],
            index: i,
            isOwnerAtelier: ateliers[i].headStylistId == user.id,
            onChanged: () => setState(() {}),
          ),
        ),
      ),
    ]);
  }

  void _showCreateAtelierSheet(BuildContext context, String companyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateAtelierSheet(companyId: companyId, onCreated: () => setState(() {})),
    );
  }
}

class _AtelierCard extends StatefulWidget {
  const _AtelierCard({required this.atelier, required this.index, required this.isOwnerAtelier, required this.onChanged});
  final dynamic atelier; final int index; final bool isOwnerAtelier; final VoidCallback onChanged;
  @override
  State<_AtelierCard> createState() => _AtelierCardState();
}
class _AtelierCardState extends State<_AtelierCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.atelier;
    final c = context.colors;
    // null pour l'atelier "personnel" du Chef d'Entreprise : il n'y a pas de
    // compte Chef d'atelier séparé à gérer, la tête EST le compte connecté.
    final AppUser? head = widget.isOwnerAtelier
        ? null
        : CompanyService.instance.findAccountById(a.headStylistId as String);
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.isOwnerAtelier ? c.tertiary.withValues(alpha: 0.3) : c.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: c.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: widget.isOwnerAtelier ? c.goldGradient : null,
                  color: widget.isOwnerAtelier ? null : c.primaryFixed.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.isOwnerAtelier ? Icons.star_rounded : Icons.storefront_rounded, color: widget.isOwnerAtelier ? c.onTertiary : c.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(a.name as String, style: AppTextStyles.titleSm, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (widget.isOwnerAtelier)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(gradient: c.goldGradient, borderRadius: BorderRadius.circular(999)),
                      child: Text('MON ATELIER', style: AppTextStyles.labelXs.copyWith(color: c.onTertiary, fontSize: 8)),
                    ),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Flexible(child: Text(widget.isOwnerAtelier ? 'Vous gérez directement cet atelier' : 'Chef : ${a.headStylistName}', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  if (head != null && !head.isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: c.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Suspendu', style: AppTextStyles.labelXs.copyWith(color: c.error)),
                    ),
                  ],
                ]),
                if (a.address != null) Text(a.address as String, style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant.withValues(alpha: 0.7))),
              ])),
              if (head != null)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: c.onSurfaceVariant),
                  onSelected: (action) => _onHeadAction(context, action, head),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'toggleActive', child: Text(head.isActive ? 'Suspendre' : 'Réactiver')),
                    const PopupMenuItem(value: 'resetLink', child: Text('Envoyer un lien de réinitialisation')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: c.onSurfaceVariant),
            ]),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildExpanded(a),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * widget.index), duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  void _onHeadAction(BuildContext context, String action, AppUser head) {
    switch (action) {
      case 'edit':
        showEditAtelierHeadDialog(context, head, widget.onChanged);
      case 'toggleActive':
        toggleAtelierHeadActive(context, head, widget.onChanged);
      case 'resetLink':
        sendAccountResetLink(context, head);
      case 'delete':
        confirmAndRemoveAtelierHead(context, head, widget.onChanged);
    }
  }

  void _onTailorAction(BuildContext context, String action, AppUser tailor) {
    switch (action) {
      case 'edit':
        showEditTailorDialog(context, tailor, widget.onChanged);
      case 'toggleActive':
        toggleTailorActive(context, tailor, widget.onChanged);
      case 'resetLink':
        sendAccountResetLink(context, tailor);
      case 'delete':
        confirmAndRemoveTailor(context, tailor, widget.onChanged);
    }
  }

  Widget _buildExpanded(dynamic a) {
    final c = context.colors;
    final atelierId = a.id as String;
    final tailors = CompanyService.instance.tailorsOfAtelier(atelierId);
    final clientCount = CompanyService.instance.clientsOfAtelier(atelierId).length;
    final orderCount = CompanyService.instance.ordersOfAtelier(atelierId).length;
    final revenue = OrderService.instance.atelierRevenue(atelierId);
    return Container(
      decoration: BoxDecoration(color: c.surfaceContainerLow, border: Border(top: BorderSide(color: c.outlineVariant.withValues(alpha: 0.3)))),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          _MiniStat(label: 'Couturiers', value: '${(a.tailorIds as List).length}', icon: Icons.content_cut_rounded),
          const SizedBox(width: 10),
          _MiniStat(label: 'Clients', value: '$clientCount', icon: Icons.people_rounded),
          const SizedBox(width: 10),
          _MiniStat(label: 'Commandes', value: '$orderCount', icon: Icons.receipt_long_rounded),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: c.goldGradient, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.payments_rounded, color: c.onTertiary, size: 18),
            const SizedBox(width: 8),
            Text('${Formatters.formatCurrency(revenue)} ${AppConstants.currency} générés', style: AppTextStyles.titleSm.copyWith(color: c.onTertiary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Text('COUTURIERS DE CET ATELIER', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant, fontSize: 10)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddTailorSheet(context, a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 12, color: c.primary),
                const SizedBox(width: 3),
                Text('AJOUTER', style: AppTextStyles.labelXs.copyWith(color: c.primary, fontSize: 9)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        if (tailors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun couturier pour le moment', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant.withValues(alpha: 0.6))),
          )
        else
          ...tailors.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TailorOrdersScreen(tailor: t)),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: c.surfaceContainerLowest, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Opacity(
                    opacity: t.isActive ? 1 : 0.4,
                    child: StylistAvatar(name: t.fullName, isOnline: false, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Row(children: [
                    Flexible(child: Text(t.fullName, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    if (!t.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: c.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('Suspendu', style: AppTextStyles.labelXs.copyWith(color: c.error)),
                      ),
                    ],
                  ])),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: c.onSurfaceVariant),
                    onSelected: (action) => _onTailorAction(context, action, t),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      PopupMenuItem(value: 'toggleActive', child: Text(t.isActive ? 'Suspendre' : 'Réactiver')),
                      const PopupMenuItem(value: 'resetLink', child: Text('Envoyer un lien de réinitialisation')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                ]),
              ),
            ),
          )),
      ]),
    );
  }

  void _showAddTailorSheet(BuildContext context, dynamic atelier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateTailorSheet(
        atelierId: atelier.id as String,
        atelierName: atelier.name as String,
        onCreated: widget.onChanged,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.icon});
  final String label; final String value; final IconData icon;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, size: 16, color: c.primary),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.titleSm.copyWith(color: c.primary, fontSize: 14)),
        Text(label, style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant, fontSize: 9)),
      ]),
    ));
  }
}

// ── Bottom sheet création atelier + chef ────────────────────────────────────
class _CreateAtelierSheet extends StatefulWidget {
  const _CreateAtelierSheet({required this.companyId, required this.onCreated});
  final String companyId; final VoidCallback onCreated;
  @override
  State<_CreateAtelierSheet> createState() => _CreateAtelierSheetState();
}
class _CreateAtelierSheetState extends State<_CreateAtelierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _atelierName = TextEditingController();
  final _headName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _created = false;
  bool _isSubmitting = false;
  final String _idempotencyKey = const Uuid().v4();
  String _temporaryPassword = '';

  @override
  void dispose() {
    _atelierName.dispose(); _headName.dispose(); _email.dispose(); _phone.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await CompanyService.instance.createAtelierHead(
        companyId: widget.companyId,
        fullName: _headName.text,
        email: _email.text,
        phone: _phone.text,
        atelierName: _atelierName.text,
        address: _address.text.isEmpty ? null : _address.text,
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      setState(() {
        _created = true;
        _temporaryPassword = result.temporaryPassword;
      });
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création de l\'atelier : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_created) {
      return SuccessConfirmationSheet(
        title: 'Atelier créé !',
        message: '${_headName.text} peut maintenant se connecter avec :\n${_email.text}\nMot de passe temporaire : $_temporaryPassword',
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nouvel Atelier', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
        Text('Créez une nouvelle maison de couture et son chef', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextFormField(controller: _atelierName, decoration: const InputDecoration(labelText: 'NOM DE L\'ATELIER', hintText: 'Ex: Keïta Prestige — Kati'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'ADRESSE (optionnel)', hintText: 'Quartier, ville')),
        const SizedBox(height: 18),
        Text('CHEF D\'ATELIER', style: AppTextStyles.labelCaps.copyWith(color: c.secondary)),
        const SizedBox(height: 10),
        TextFormField(controller: _headName, decoration: const InputDecoration(labelText: 'NOM COMPLET', hintText: 'Prénom Nom'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'EMAIL', hintText: 'chef@atelier.ml'), validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE', hintText: '+223 70 00 00 00'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: _isSubmitting
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
              : Text('CRÉER L\'ATELIER', style: AppTextStyles.labelCaps.copyWith(color: c.onPrimary, letterSpacing: 1.2)),
        )),
      ])),
    );
  }
}

// ── Bottom sheet création couturier ──────────────────────────────────────────
class _CreateTailorSheet extends StatefulWidget {
  const _CreateTailorSheet({required this.atelierId, required this.atelierName, required this.onCreated});
  final String atelierId; final String atelierName; final VoidCallback onCreated;
  @override
  State<_CreateTailorSheet> createState() => _CreateTailorSheetState();
}
class _CreateTailorSheetState extends State<_CreateTailorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _created = false;
  bool _isSubmitting = false;
  final String _idempotencyKey = const Uuid().v4();
  String _temporaryPassword = '';

  @override
  void dispose() {
    _fullName.dispose(); _email.dispose(); _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await CompanyService.instance.createTailor(
        atelierId: widget.atelierId,
        atelierName: widget.atelierName,
        fullName: _fullName.text,
        email: _email.text,
        phone: _phone.text,
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      setState(() {
        _created = true;
        _temporaryPassword = result.temporaryPassword;
      });
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du couturier : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_created) {
      return SuccessConfirmationSheet(
        title: 'Couturier ajouté !',
        message: '${_fullName.text} peut se connecter avec :\n${_email.text}\nMot de passe temporaire : $_temporaryPassword',
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nouveau Couturier', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
        Text('Pour : ${widget.atelierName}', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextFormField(controller: _fullName, decoration: const InputDecoration(labelText: 'NOM COMPLET', hintText: 'Prénom Nom'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'EMAIL', hintText: 'couturier@atelier.ml'), validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE', hintText: '+223 70 00 00 00'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: _isSubmitting
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
              : Text('AJOUTER LE COUTURIER', style: AppTextStyles.labelCaps.copyWith(color: c.onPrimary, letterSpacing: 1.2)),
        )),
      ])),
    );
  }
}
