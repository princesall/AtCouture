import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../../services/order_service.dart';
import '../admin/admin_dashboard.dart' show StylistAvatar;

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

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes Ateliers', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
            Text('${ateliers.length} maison${ateliers.length > 1 ? 's' : ''} de couture', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
          if (permissions.canCreateAtelierHead)
            GestureDetector(
              onTap: () => _showCreateAtelierSheet(context, user.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
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
      backgroundColor: AppColors.surfaceContainerLowest,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.isOwnerAtelier ? AppColors.tertiary.withValues(alpha: 0.3) : AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AppColors.softShadow,
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
                  gradient: widget.isOwnerAtelier ? AppColors.goldGradient : null,
                  color: widget.isOwnerAtelier ? null : AppColors.primaryFixed.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.isOwnerAtelier ? Icons.star_rounded : Icons.storefront_rounded, color: widget.isOwnerAtelier ? AppColors.onTertiary : AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(a.name as String, style: AppTextStyles.titleSm, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (widget.isOwnerAtelier)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(999)),
                      child: Text('MON ATELIER', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary, fontSize: 8)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(widget.isOwnerAtelier ? 'Vous gérez directement cet atelier' : 'Chef : ${a.headStylistName}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                if (a.address != null) Text(a.address as String, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
              ])),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant),
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

  Widget _buildExpanded(dynamic a) {
    final atelierId = a.id as String;
    final tailors = CompanyService.instance.tailorsOfAtelier(atelierId);
    final clientCount = CompanyService.instance.clientsOfAtelier(atelierId).length;
    final orderCount = CompanyService.instance.ordersOfAtelier(atelierId).length;
    final revenue = OrderService.instance.atelierRevenue(atelierId);
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)))),
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
          decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.payments_rounded, color: AppColors.onTertiary, size: 18),
            const SizedBox(width: 8),
            Text('${Formatters.formatCurrency(revenue)} ${AppConstants.currency} générés', style: AppTextStyles.titleSm.copyWith(color: AppColors.onTertiary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Text('COUTURIERS DE CET ATELIER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddTailorSheet(context, a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 3),
                Text('AJOUTER', style: AppTextStyles.labelXs.copyWith(color: AppColors.primary, fontSize: 9)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        if (tailors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun couturier pour le moment', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
          )
        else
          ...tailors.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                StylistAvatar(name: t.fullName, isOnline: false, size: 30),
                const SizedBox(width: 10),
                Expanded(child: Text(t.fullName, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))),
              ]),
            ),
          )),
      ]),
    );
  }

  void _showAddTailorSheet(BuildContext context, dynamic atelier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
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
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 14)),
      Text(label, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant, fontSize: 9)),
    ]),
  ));
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
    if (_created) {
      return SuccessConfirmationSheet(
        title: 'Atelier créé !',
        message: '${_headName.text} peut maintenant se connecter avec :\n${_email.text}\nMot de passe temporaire : $_temporaryPassword',
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nouvel Atelier', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        Text('Créez une nouvelle maison de couture et son chef', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextFormField(controller: _atelierName, decoration: const InputDecoration(labelText: 'NOM DE L\'ATELIER', hintText: 'Ex: Keïta Prestige — Kati'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'ADRESSE (optionnel)', hintText: 'Quartier, ville')),
        const SizedBox(height: 18),
        Text('CHEF D\'ATELIER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary)),
        const SizedBox(height: 10),
        TextFormField(controller: _headName, decoration: const InputDecoration(labelText: 'NOM COMPLET', hintText: 'Prénom Nom'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'EMAIL', hintText: 'chef@atelier.ml'), validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE', hintText: '+223 70 00 00 00'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
              : Text('CRÉER L\'ATELIER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary, letterSpacing: 1.2)),
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
    if (_created) {
      return SuccessConfirmationSheet(
        title: 'Couturier ajouté !',
        message: '${_fullName.text} peut se connecter avec :\n${_email.text}\nMot de passe temporaire : $_temporaryPassword',
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nouveau Couturier', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        Text('Pour : ${widget.atelierName}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextFormField(controller: _fullName, decoration: const InputDecoration(labelText: 'NOM COMPLET', hintText: 'Prénom Nom'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'EMAIL', hintText: 'couturier@atelier.ml'), validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE', hintText: '+223 70 00 00 00'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
              : Text('AJOUTER LE COUTURIER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary, letterSpacing: 1.2)),
        )),
      ])),
    );
  }
}
