import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/plan_guard.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

/// Onglet Couturiers de l'espace Styliste (compte solo).
///
/// RÈGLE DE PLAN : le nombre de couturiers autorisés dépend du plan.
/// Le plan Gratuit n'a droit qu'à UN SEUL couturier. Le bouton "+" reste
/// toujours visible, mais dès que le quota est atteint, un appui ouvre une
/// fenêtre invitant à prendre un abonnement pour créer plus de couturiers
/// (voir PlanGuard.requireCapacity). La vérification s'appuie sur
/// `user.permissions.canAddTailor(...)`, qui tient déjà compte de l'expiration
/// éventuelle de l'abonnement.
class StylistTailorsTab extends StatefulWidget {
  const StylistTailorsTab({super.key});
  @override
  State<StylistTailorsTab> createState() => _StylistTailorsTabState();
}

class _StylistTailorsTabState extends State<StylistTailorsTab> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final atelierId = user.atelierId ?? user.id;
    final tailors = CompanyService.instance.tailorsOfAtelier(atelierId);
    final permissions = user.permissions;
    final maxLabel = permissions.isUnlimitedTailors
        ? 'illimité'
        : '${permissions.maxTailorsPerAtelier} max';

    return Column(children: [
      // ── Header + bouton ajout ─────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes Couturiers', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
            Text('${tailors.length} couturier${tailors.length > 1 ? 's' : ''} — $maxLabel', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
          GestureDetector(
            onTap: () => _onAddPressed(context, user, tailors.length),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Liste couturiers ──────────────────────────────────────────────────
      Expanded(
        child: tailors.isEmpty
            ? _EmptyTailors(onAdd: () => _onAddPressed(context, user, 0))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                itemCount: tailors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TailorCard(
                  tailor: tailors[i],
                  index: i,
                  onRemove: () {
                    CompanyService.instance.removeTailor(tailors[i].id);
                    setState(() {});
                  },
                ),
              ),
      ),
    ]);
  }

  void _onAddPressed(BuildContext context, AppUser user, int currentCount) {
    // Dernière ligne de défense côté client : on vérifie le quota du plan
    // AVANT d'ouvrir le formulaire. Si le quota est atteint, PlanGuard affiche
    // automatiquement la fenêtre d'upsell (prendre un abonnement).
    final allowed = PlanGuard.requireCapacity(
      context: context,
      hasCapacity: user.permissions.canAddTailor(currentCount),
      resourceName: 'Couturiers',
      lockedMessage:
          'Le plan Gratuit ne permet qu\'un seul couturier. Prenez un abonnement pour ajouter plus de couturiers à votre atelier.',
    );
    if (!allowed) return;

    final atelierId = user.atelierId ?? user.id;
    final atelierName = user.atelierName ?? 'Mon atelier';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddTailorSheet(
        atelierId: atelierId,
        atelierName: atelierName,
        onAdded: () => setState(() {}),
      ),
    );
  }
}

class _EmptyTailors extends StatelessWidget {
  const _EmptyTailors({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: const Icon(Icons.content_cut_outlined, color: AppColors.secondary, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Aucun couturier', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('Ajoutez votre couturier pour lui assigner des commandes.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('AJOUTER UN COUTURIER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), elevation: 0),
          ),
        ]),
      ),
    );
  }
}

class _TailorCard extends StatelessWidget {
  const _TailorCard({required this.tailor, required this.index, required this.onRemove});
  final AppUser tailor; final int index; final VoidCallback onRemove;

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
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
          child: Center(child: Text(tailor.initials, style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tailor.fullName, style: AppTextStyles.titleSm),
          const SizedBox(height: 2),
          Text(tailor.phone, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ])),
        IconButton(
          onPressed: () => _confirmRemove(context),
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms).slideY(begin: 0.04, end: 0);
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Retirer ce couturier ?', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        content: Text('${tailor.fullName} sera retiré de votre atelier.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ANNULER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); onRemove(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text('RETIRER', style: AppTextStyles.labelCaps.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AddTailorSheet extends StatefulWidget {
  const _AddTailorSheet({required this.atelierId, required this.atelierName, required this.onAdded});
  final String atelierId; final String atelierName; final VoidCallback onAdded;
  @override State<_AddTailorSheet> createState() => _AddTailorSheetState();
}

class _AddTailorSheetState extends State<_AddTailorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _added = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    CompanyService.instance.createTailor(
      atelierId: widget.atelierId,
      atelierName: widget.atelierName,
      fullName: _name.text,
      email: _email.text.trim().isEmpty ? '${_name.text.trim().toLowerCase().replaceAll(' ', '.')}@atelier.ml' : _email.text,
      phone: _phone.text,
    );
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
          Text('Couturier ajouté !', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('${_name.text} a été ajouté à votre atelier.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
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
        Text('Nouveau Couturier', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        Text('Ajouter un couturier à votre atelier', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'NOM COMPLET', hintText: 'Prénom Nom'), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'TÉLÉPHONE', hintText: '+223 70 00 00 00'), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'EMAIL (optionnel)', hintText: 'couturier@email.ml')),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: Text('AJOUTER LE COUTURIER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
        )),
      ])),
    );
  }
}
