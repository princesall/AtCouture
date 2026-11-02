import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/subscription_receipt_pdf.dart';
import '../../data/admin_demo_data.dart';
import '../../models/admin_account.dart';
import '../../models/app_user.dart';
import '../../models/client.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../models/support_message.dart';
import '../../models/user_role.dart';
import '../../services/account_360_service.dart';
import '../../services/admin_notes_service.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_payment_service.dart';
import '../../services/support_message_service.dart';
import '../dialogs/record_payment_dialog.dart';
import '../pages/admin_support_preview_page.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Fiche 360 d'un compte : identité, abonnement, activité, équipe, support et
/// notes internes. Toutes les données viennent de `Account360Service`.
class AdminAccount360Page extends StatefulWidget {
  const AdminAccount360Page({
    super.key,
    required this.userId,
    this.onBack,
  });

  final String userId;
  final VoidCallback? onBack;

  @override
  State<AdminAccount360Page> createState() => _AdminAccount360PageState();
}

class _AdminAccount360PageState extends State<AdminAccount360Page> {
  static const _tabs = [
    'SYNTHÈSE',
    'ABONNEMENT',
    'ACTIVITÉ',
    'ÉQUIPE',
    'SUPPORT',
    'NOTES',
  ];

  Account360Data? _data;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  int _tab = 0;

  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load(force: true);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    if (_data == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await Account360Service.instance.load(
        widget.userId,
        force: force,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showAdminSnack(context, success);
      await _load(force: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _canManagePlan {
    final user = _data?.user;
    if (user == null) return false;
    if (user.role != UserRole.stylist && user.role != UserRole.companyOwner) {
      return false;
    }
    return AdminDemoData.stylists.any((entry) => entry.user.id == user.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = _data;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: AdminPageBody(
          children: [
            _topBar(context),
            if (data == null && _loading)
              const AdminPanel(
                child: AdminEmptyState(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'Chargement de la fiche…',
                  message: 'Compte, abonnement, commandes, équipe et support.',
                ),
              )
            else if (_error != null)
              AdminInfoBanner(
                icon: Icons.error_outline_rounded,
                text: 'Impossible de charger ce compte : $_error',
                accent: c.statusProblem,
                action: AdminButton(
                  label: 'Réessayer',
                  small: true,
                  onTap: () => _load(force: true),
                ),
              )
            else if (data != null) ...[
              _AccountHeader(
                data: data,
                busy: _busy,
                canManagePlan: _canManagePlan,
                onPayment: _recordPayment,
                onMenu: _handleMenu,
                onWhatsApp: () => _openWhatsApp(data.user),
              ),
              const SizedBox(height: 16),
              _KpiGrid(data: data),
              const SizedBox(height: 18),
              AdminFilterChips(
                labels: _tabs,
                selected: _tab,
                onSelect: (index) => setState(() => _tab = index),
              ),
              const SizedBox(height: 16),
              switch (_tab) {
                1 => _SubscriptionTab(
                    data: data,
                    canManagePlan: _canManagePlan,
                    onPayment: _recordPayment,
                    onReceipt: _shareReceipt,
                    onPlan: _changePlan,
                    onRenew: _renew,
                    onApprove: _approve,
                    onReject: _reject,
                  ),
                2 => _ActivityTab(data: data),
                3 => _TeamTab(data: data),
                4 => _SupportTab(
                    messages: data.supportMessages,
                    onReply: _replySupport,
                  ),
                5 => _NotesTab(
                    notes: data.notes,
                    controller: _noteController,
                    busy: _busy,
                    onAdd: _addNote,
                    onDelete: _deleteNote,
                  ),
                _ => _OverviewTab(
                    data: data,
                    canManagePlan: _canManagePlan,
                    onPayment: _recordPayment,
                    onPlan: _changePlan,
                    onRenew: _renew,
                  ),
              },
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
          icon: Icon(Icons.arrow_back_rounded, color: c.onSurface),
          tooltip: 'Retour',
        ),
        const SizedBox(width: 4),
        Text(
          'CONSOLE ADMIN',
          style: AppTextStyles.labelCaps.copyWith(
            fontSize: 9,
            color: c.onSurfaceVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: c.onSurfaceVariant,
          ),
        ),
        Text(
          'FICHE 360',
          style: AppTextStyles.labelCaps.copyWith(
            fontSize: 9,
            color: c.goldInk,
          ),
        ),
        const Spacer(),
        AdminButton(
          label: 'Actualiser',
          icon: Icons.refresh_rounded,
          small: true,
          onTap: _busy ? null : () => _load(force: true),
        ),
      ],
    );
  }

  Future<void> _handleMenu(String action) async {
    final data = _data;
    if (data == null) return;
    switch (action) {
      case 'plan':
        await _changePlan();
        return;
      case 'renew':
        await _renew();
        return;
      case 'approve':
        await _approve();
        return;
      case 'reject':
        await _reject();
        return;
      case 'toggle':
        await _toggleActive();
        return;
      case 'reset':
        await _resetPassword();
        return;
      case 'preview':
        await _openPreview();
        return;
      case 'copy':
        Clipboard.setData(ClipboardData(text: data.user.id));
        if (!mounted) return;
        showAdminSnack(context, 'Identifiant du compte copié.');
        return;
    }
  }

  Future<void> _changePlan() async {
    final data = _data;
    if (data == null) return;
    final plan = await adminPickPlan(context, current: data.user.plan);
    if (!mounted) return;
    if (plan == null || plan == data.user.plan) return;
    final confirmed = await adminConfirm(
      context,
      title: 'Changer le plan ?',
      message:
          '${data.user.fullName} passera du plan ${data.user.plan.name} au plan ${plan.name} pour 30 jours.',
      confirmLabel: 'Changer le plan',
    );
    if (!confirmed) return;
    await _runAction(
      () => AdminDemoData.applyManualPlanChange(data.user.id, plan),
      success: 'Plan changé vers ${plan.name}.',
    );
  }

  Future<void> _renew() async {
    final data = _data;
    if (data == null) return;
    final confirmed = await adminConfirm(
      context,
      title: 'Renouveler 12 mois ?',
      message:
          'L\'abonnement ${data.user.plan.name} de ${data.user.fullName} sera prolongé de 12 mois.',
      confirmLabel: 'Renouveler',
    );
    if (!confirmed) return;
    await _runAction(
      () => AdminDemoData.renewSubscription(data.user.id),
      success: 'Abonnement renouvelé pour 12 mois.',
    );
  }

  Future<void> _approve() async {
    final data = _data;
    if (data == null || data.pendingRequest == null) return;
    final confirmed = await adminConfirm(
      context,
      title: 'Approuver la demande ?',
      message:
          'Le plan ${data.pendingRequest!.requestedPlan.name} sera activé pour ${data.user.fullName}.',
      confirmLabel: 'Approuver',
    );
    if (!confirmed) return;
    await _runAction(
      () => AdminDemoData.approveRequest(data.user.id),
      success: 'Demande approuvée.',
    );
  }

  Future<void> _reject() async {
    final data = _data;
    if (data == null || data.pendingRequest == null) return;
    final confirmed = await adminConfirm(
      context,
      title: 'Refuser la demande ?',
      message:
          'La demande de plan ${data.pendingRequest!.requestedPlan.name} sera refusée. Le compte sera notifié.',
      confirmLabel: 'Refuser',
      danger: true,
    );
    if (!confirmed) return;
    await _runAction(
      () => AdminDemoData.rejectRequest(data.user.id),
      success: 'Demande refusée.',
    );
  }

  Future<void> _toggleActive() async {
    final data = _data;
    if (data == null) return;
    final suspend = data.user.isActive;
    final confirmed = await adminConfirm(
      context,
      title: suspend ? 'Suspendre ce compte ?' : 'Réactiver ce compte ?',
      message: suspend
          ? '${data.user.fullName} ne pourra plus se connecter tant que le compte reste suspendu.'
          : '${data.user.fullName} pourra de nouveau se connecter.',
      confirmLabel: suspend ? 'Suspendre' : 'Réactiver',
      danger: suspend,
    );
    if (!confirmed) return;
    await _runAction(
      () => AdminDemoData.toggleActive(data.user.id),
      success: suspend ? 'Compte suspendu.' : 'Compte réactivé.',
    );
  }

  Future<void> _resetPassword() async {
    final data = _data;
    if (data == null) return;
    final confirmed = await adminConfirm(
      context,
      title: 'Envoyer un lien de réinitialisation ?',
      message:
          'Un email sera envoyé à ${data.user.email}. Le compte choisira un nouveau mot de passe.',
      confirmLabel: 'Envoyer',
    );
    if (!confirmed) return;
    try {
      await AuthService().sendPasswordResetEmail(data.user.email);
      if (!mounted) return;
      showAdminSnack(context, 'Email de réinitialisation envoyé.');
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, '$error', error: true);
    }
  }

  Future<void> _openPreview() async {
    final data = _data;
    if (data == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminSupportPreviewPage(data: data),
      ),
    );
  }

  Future<void> _recordPayment() async {
    final data = _data;
    if (data == null || !_canManagePlan) return;
    final draft = await showRecordPaymentDialog(context, user: data.user);
    if (draft == null) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SubscriptionPaymentService.instance.recordPayment(
        user: data.user,
        plan: draft.plan,
        amount: draft.amount,
        method: draft.method,
        periodMonths: draft.months,
        reference: draft.reference,
        note: draft.note,
      );
      if (!mounted) return;
      showAdminSnack(
        context,
        'Paiement enregistré. Abonnement prolongé jusqu\'au ${Formatters.date.format(_periodEndFor(draft))}.',
      );
      await _load(force: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  DateTime _periodEndFor(PaymentDraft draft) {
    final now = DateTime.now();
    final expiry = _data?.user.planExpiresAt;
    final start = expiry != null && expiry.isAfter(now) ? expiry : now;
    final rawMonth = start.month + draft.months;
    final year = start.year + (rawMonth - 1) ~/ 12;
    final month = (rawMonth - 1) % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, start.day > lastDay ? lastDay : start.day);
  }

  Future<void> _shareReceipt(SubscriptionPayment payment) async {
    final data = _data;
    if (data == null) return;
    try {
      await SubscriptionReceiptPdf.share(payment, data.user);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Reçu indisponible : $error', error: true);
    }
  }

  Future<void> _openWhatsApp(AppUser user) async {
    final digits = user.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      showAdminSnack(context, 'Aucun numéro de téléphone.', error: true);
      return;
    }
    final message = Uri.encodeComponent(
      'Bonjour ${user.fullName}, l\'équipe StyleConnect vous contacte au sujet de votre compte.',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$message');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        showAdminSnack(context, 'WhatsApp n\'a pas pu être ouvert.', error: true);
      }
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'WhatsApp indisponible : $error', error: true);
    }
  }

  Future<void> _replySupport(SupportMessage message) async {
    final controller = TextEditingController(text: message.reply ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.colors;
        return AlertDialog(
          backgroundColor: c.surfaceContainerLowest,
          title: Text(
            'Répondre à ${message.senderName}',
            style: AppTextStyles.titleMd.copyWith(
              fontSize: 17,
              color: c.onSurface,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              style: AppTextStyles.bodySm.copyWith(color: c.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surfaceContainerLow,
                hintText: 'Votre réponse…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Annuler',
                style: AppTextStyles.bodySm.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
              ),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    try {
      await SupportMessageService.instance.reply(
        messageId: message.id,
        replyContent: text,
      );
      if (!mounted) return;
      showAdminSnack(context, 'Réponse envoyée.');
      await _load(force: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, '$error', error: true);
    }
  }

  Future<void> _addNote() async {
    final data = _data;
    final text = _noteController.text.trim();
    if (data == null || text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await AdminNotesService.instance.add(data.user.id, text);
      _noteController.clear();
      if (!mounted) return;
      showAdminSnack(context, 'Note interne ajoutée.');
      await _load(force: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteNote(AdminNote note) async {
    final data = _data;
    if (data == null) return;
    final confirmed = await adminConfirm(
      context,
      title: 'Supprimer cette note ?',
      message: 'Cette action est définitive.',
      confirmLabel: 'Supprimer',
      danger: true,
    );
    if (!confirmed) return;
    try {
      await AdminNotesService.instance.delete(data.user.id, note.id);
      if (!mounted) return;
      showAdminSnack(context, 'Note supprimée.');
      await _load(force: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, '$error', error: true);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// En-tête
// ─────────────────────────────────────────────────────────────────────────────

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.data,
    required this.busy,
    required this.canManagePlan,
    required this.onPayment,
    required this.onMenu,
    required this.onWhatsApp,
  });

  final Account360Data data;
  final bool busy;
  final bool canManagePlan;
  final VoidCallback onPayment;
  final ValueChanged<String> onMenu;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = data.user;
    final alerts = data.qualityAlerts;

    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 820;
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminAvatar.fromName(user.fullName, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: AppTextStyles.headlineLgMobile.copyWith(
                          fontSize: 24,
                          color: c.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.role.label} · ${user.atelierName ?? data.company?.name ?? 'Sans atelier'}',
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 13,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 7,
                        children: [
                          AdminPlanBadge(
                            plan: user.plan,
                            isCompanyStaff: user.companyId != null,
                          ),
                          AdminBadge(
                            label: user.isActive ? 'ACTIF' : 'SUSPENDU',
                            foreground: user.isActive
                                ? c.statusDone
                                : c.statusProblem,
                            background: user.isActive
                                ? c.statusDoneBg
                                : c.statusProblemBg,
                            dot: true,
                          ),
                          if (alerts.isNotEmpty)
                            AdminBadge(
                              label:
                                  '${alerts.length} ALERTE${alerts.length > 1 ? 'S' : ''}',
                              foreground: c.statusInProgress,
                              background: c.statusInProgressBg,
                              icon: Icons.warning_amber_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _ContactLine(
                            icon: Icons.mail_outline_rounded,
                            text: user.email,
                          ),
                          _ContactLine(
                            icon: Icons.phone_outlined,
                            text: user.phone.trim().isEmpty
                                ? 'Téléphone manquant'
                                : user.phone,
                          ),
                          _ContactLine(
                            icon: Icons.login_rounded,
                            text: user.lastLoginAt == null
                                ? 'Connexion inconnue'
                                : 'Vu ${Formatters.dateTime.format(user.lastLoginAt!)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.phone.trim().isNotEmpty)
                  AdminButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline_rounded,
                    small: true,
                    onTap: busy ? null : onWhatsApp,
                  ),
                if (canManagePlan)
                  AdminButton(
                    label: 'Paiement',
                    icon: Icons.payments_rounded,
                    small: true,
                    primary: true,
                    onTap: busy ? null : onPayment,
                  ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: 'Actions',
                  // Les libellés d'actions sont longs (« Réinitialiser le mot
                  // de passe ») : sans élargissement explicite, le menu par
                  // défaut (256 px) débordait de plus de 100 px en debug.
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: c.onSurfaceVariant,
                  ),
                  onSelected: onMenu,
                  itemBuilder: (_) => [
                    if (canManagePlan) ...[
                      _menuItem('plan', Icons.workspace_premium_rounded,
                          'Changer de plan'),
                      _menuItem('renew', Icons.autorenew_rounded,
                          'Renouveler 12 mois'),
                      if (data.pendingRequest != null) ...[
                        _menuItem('approve', Icons.check_circle_outline_rounded,
                            'Approuver la demande'),
                        _menuItem('reject', Icons.cancel_outlined,
                            'Refuser la demande'),
                      ],
                    ],
                    _menuItem(
                      'toggle',
                      user.isActive
                          ? Icons.block_rounded
                          : Icons.lock_open_rounded,
                      user.isActive ? 'Suspendre le compte' : 'Réactiver le compte',
                    ),
                    _menuItem('reset', Icons.lock_reset_rounded,
                        'Réinitialiser le mot de passe'),
                    _menuItem('preview', Icons.visibility_rounded,
                        'Aperçu support (lecture seule)'),
                    _menuItem('copy', Icons.copy_rounded,
                        'Copier l\'identifiant'),
                  ],
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact) ...[
                  identity,
                  const SizedBox(height: 16),
                  actions,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 20),
                      actions,
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTextStyles.bodySm.copyWith(
            fontSize: 11.5,
            color: c.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final Account360Data data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = data.daysBeforeExpiry;
    final cards = <Widget>[
      AdminKpiCard(
        label: 'CLIENTS',
        value: '${data.clientCount}',
        icon: Icons.people_alt_outlined,
        accent: c.secondary,
        hint: '${data.orders.length} commandes',
      ),
      AdminKpiCard(
        label: 'COMMANDES ACTIVES',
        value: '${data.activeOrders}',
        icon: Icons.receipt_long_rounded,
        accent: c.statusInProgress,
        hint: '${data.orders.length} au total',
      ),
      AdminKpiCard(
        label: 'CA ATELIER',
        value: Formatters.compactCurrency(data.totalRevenue),
        icon: Icons.trending_up_rounded,
        accent: c.statusDone,
        hint: '${Formatters.compactCurrency(data.cashCollected)} encaissés',
      ),
      AdminKpiCard(
        label: 'RESTE À ENCAISSER',
        value: Formatters.compactCurrency(data.outstanding),
        icon: Icons.account_balance_wallet_outlined,
        accent: data.outstanding > 0 ? c.statusProblem : c.statusDone,
        hint: 'sur les commandes en cours',
      ),
      AdminKpiCard(
        label: 'ABONNEMENT ENCAISSÉ',
        value: Formatters.compactCurrency(data.subscriptionPaid),
        icon: Icons.payments_rounded,
        accent: c.goldInk,
        hint: data.lastPayment == null
            ? 'aucun paiement enregistré'
            : 'dernier ${Formatters.date.format(data.lastPayment!.createdAt)}',
      ),
      AdminKpiCard(
        label: 'ÉQUIPE',
        value: '${data.teamCount}',
        icon: Icons.group_outlined,
        accent: c.secondary,
        hint: '${data.ateliers.length} atelier(s)',
      ),
      AdminKpiCard(
        label: 'EXPIRATION',
        value: days == null
            ? '—'
            : (data.hasExpired ? 'Expiré' : '$days j'),
        icon: Icons.event_available_outlined,
        accent: data.hasExpired || (days != null && days <= 7)
            ? c.statusProblem
            : c.statusDone,
        hint: data.user.planExpiresAt == null
            ? 'sans date d\'expiration'
            : Formatters.date.format(data.user.planExpiresAt!),
        highlight: data.hasExpired || (days != null && days <= 7),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final columns = constraints.maxWidth >= 1200
            ? 4
            : (constraints.maxWidth >= 640 ? 2 : 1);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Synthèse
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.data,
    required this.canManagePlan,
    required this.onPayment,
    required this.onPlan,
    required this.onRenew,
  });

  final Account360Data data;
  final bool canManagePlan;
  final VoidCallback onPayment;
  final VoidCallback onPlan;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1060;
        final left = Column(
          children: [
            _SubscriptionCard(
              data: data,
              canManagePlan: canManagePlan,
              onPayment: onPayment,
              onPlan: onPlan,
              onRenew: onRenew,
            ),
            const SizedBox(height: 16),
            _RecentOrdersPanel(orders: data.orders),
          ],
        );
        final right = Column(
          children: [
            _QualityPanel(alerts: data.qualityAlerts),
            const SizedBox(height: 16),
            _TopClientsPanel(clients: data.clients),
          ],
        );
        if (!wide) {
          return Column(
            children: [left, const SizedBox(height: 16), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: left),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: right),
          ],
        );
      },
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.data,
    required this.canManagePlan,
    required this.onPayment,
    required this.onPlan,
    required this.onRenew,
  });

  final Account360Data data;
  final bool canManagePlan;
  final VoidCallback onPayment;
  final VoidCallback onPlan;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = data.user;
    final days = data.daysBeforeExpiry;
    final progress = days == null ? 0.0 : (days / 365).clamp(0.0, 1.0);

    return AdminPanel(
      title: 'Abonnement',
      subtitle: data.pendingRequest == null
          ? 'Plan ${user.plan.name}'
          : 'Demande ${data.pendingRequest!.requestedPlan.name} en attente',
      trailing: AdminPlanBadge(
        plan: user.plan,
        isCompanyStaff: user.companyId != null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_rounded, size: 15, color: c.onSurfaceVariant),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    user.planExpiresAt == null
                        ? 'Aucune date d\'expiration'
                        : 'Expire le ${Formatters.date.format(user.planExpiresAt!)}',
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 12.5,
                      color: c.onSurface,
                    ),
                  ),
                ),
                Text(
                  days == null ? '—' : (days < 0 ? 'Expiré' : '$days j'),
                  style: AppTextStyles.labelCaps.copyWith(
                    fontSize: 9.5,
                    color: days != null && days <= 7
                        ? c.statusProblem
                        : c.statusDone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AdminProgressBar(
              value: progress,
              color: days != null && days <= 7 ? c.statusProblem : c.secondary,
              height: 7,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'ENCAISSÉ',
                    value: Formatters.compactCurrency(data.subscriptionPaid),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'DERNIER PAIEMENT',
                    value: data.lastPayment == null
                        ? '—'
                        : Formatters.date.format(data.lastPayment!.createdAt),
                  ),
                ),
              ],
            ),
            if (data.pendingRequest != null) ...[
              const SizedBox(height: 14),
              AdminInfoBanner(
                icon: Icons.workspace_premium_rounded,
                text:
                    'Demande de plan ${data.pendingRequest!.requestedPlan.name} depuis le ${Formatters.date.format(data.pendingRequest!.requestedAt)}.',
                accent: c.statusInProgress,
              ),
            ],
            if (canManagePlan) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminButton(
                    label: 'Enregistrer un paiement',
                    icon: Icons.add_card_rounded,
                    primary: true,
                    small: true,
                    onTap: onPayment,
                  ),
                  AdminButton(
                    label: 'Renouveler 12 mois',
                    icon: Icons.autorenew_rounded,
                    small: true,
                    onTap: onRenew,
                  ),
                  AdminButton(
                    label: 'Changer de plan',
                    icon: Icons.swap_horiz_rounded,
                    small: true,
                    onTap: onPlan,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            fontSize: 8,
            color: c.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSm.copyWith(
            fontSize: 13,
            color: c.onSurface,
          ),
        ),
      ],
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const AdminPanel(
        child: AdminEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Aucune commande',
          message: 'Ce compte n\'a encore enregistré aucune commande.',
        ),
      );
    }
    return AdminPanel(
      clip: true,
      padding: EdgeInsets.zero,
      title: 'Dernières commandes',
      subtitle: '${orders.length} commande${orders.length > 1 ? 's' : ''} au total',
      child: AdminTable(
        minWidth: 700,
        columns: const [
          AdminColumn('CLIENT', flex: 3),
          AdminColumn('ATELIER', flex: 2),
          AdminColumn('STATUT', width: 120),
          AdminColumn('MONTANT', width: 120, align: TextAlign.right),
          AdminColumn('RESTE', width: 110, align: TextAlign.right),
        ],
        rows: [
          for (final order in orders.take(6))
            AdminRow([
              Text(
                order.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSm.copyWith(
                  fontSize: 12.5,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                order.atelierName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 11.5,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              _OrderStatusBadge(status: order.status),
              Text(
                Formatters.formatCurrency(order.price ?? 0),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                Formatters.formatCurrency(order.balanceDue),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: order.balanceDue > 0
                      ? context.colors.statusProblem
                      : context.colors.statusDone,
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (status) {
      OrderStatus.pending => (c.goldInk, c.tertiaryContainer),
      OrderStatus.inProgress => (c.statusInProgress, c.statusInProgressBg),
      OrderStatus.completed => (c.statusDone, c.statusDoneBg),
      OrderStatus.problem => (c.statusProblem, c.statusProblemBg),
    };
    return AdminBadge(label: status.label, foreground: fg, background: bg);
  }
}

class _QualityPanel extends StatelessWidget {
  const _QualityPanel({required this.alerts});

  final List<AccountQualityAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Qualité du compte',
      subtitle: alerts.isEmpty
          ? 'Aucune anomalie détectée'
          : '${alerts.length} point${alerts.length > 1 ? 's' : ''} à surveiller',
      trailing: AdminBadge(
        label: '${alerts.length}',
        foreground: alerts.isEmpty ? c.statusDone : c.statusInProgress,
        background: alerts.isEmpty ? c.statusDoneBg : c.statusInProgressBg,
      ),
      child: alerts.isEmpty
          ? const AdminEmptyState(
              icon: Icons.verified_rounded,
              title: 'Compte cohérent',
              message: 'Téléphone, atelier, activité et abonnement sont en ordre.',
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Column(
                children: [
                  for (var i = 0; i < alerts.length; i++) ...[
                    _QualityRow(alert: alerts[i]),
                    if (i != alerts.length - 1)
                      Divider(
                        height: 1,
                        color: c.outlineVariant.withValues(alpha: 0.6),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  const _QualityRow({required this.alert});

  final AccountQualityAlert alert;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = alert.severity >= 3
        ? c.statusProblem
        : (alert.severity == 2 ? c.statusInProgress : c.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alert.icon, size: 15, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.label,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 12,
                    color: c.onSurface,
                  ),
                ),
                if (alert.detail != null)
                  Text(
                    alert.detail!,
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 11,
                      color: c.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopClientsPanel extends StatelessWidget {
  const _TopClientsPanel({required this.clients});

  final List<Client> clients;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = clients.take(5).toList();
    return AdminPanel(
      title: 'Top clients',
      subtitle: '${clients.length} client${clients.length > 1 ? 's' : ''}',
      child: top.isEmpty
          ? const AdminEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Aucun client',
              message: 'Les clients apparaîtront avec les premières commandes.',
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: c.surfaceContainerLow,
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.labelXs.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                top[i].fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleSm.copyWith(
                                  fontSize: 12,
                                  color: c.onSurface,
                                ),
                              ),
                              Text(
                                '${top[i].orderCount} commande(s)',
                                style: AppTextStyles.bodySm.copyWith(
                                  fontSize: 10.5,
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.compactCurrency(top[i].totalSpent),
                          style: AppTextStyles.labelXs.copyWith(
                            color: c.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (i != top.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Abonnement
// ─────────────────────────────────────────────────────────────────────────────

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab({
    required this.data,
    required this.canManagePlan,
    required this.onPayment,
    required this.onReceipt,
    required this.onPlan,
    required this.onRenew,
    required this.onApprove,
    required this.onReject,
  });

  final Account360Data data;
  final bool canManagePlan;
  final VoidCallback onPayment;
  final ValueChanged<SubscriptionPayment> onReceipt;
  final VoidCallback onPlan;
  final VoidCallback onRenew;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SubscriptionCard(
          data: data,
          canManagePlan: canManagePlan,
          onPayment: onPayment,
          onPlan: onPlan,
          onRenew: onRenew,
        ),
        if (data.pendingRequest != null) ...[
          const SizedBox(height: 16),
          AdminPanel(
            title: 'Demande en attente',
            subtitle:
                'Plan ${data.pendingRequest!.requestedPlan.name} demandé le ${Formatters.date.format(data.pendingRequest!.requestedAt)}',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Wrap(
                spacing: 8,
                children: [
                  AdminButton(
                    label: 'Approuver',
                    icon: Icons.check_rounded,
                    primary: true,
                    small: true,
                    onTap: onApprove,
                  ),
                  AdminButton(
                    label: 'Refuser',
                    icon: Icons.close_rounded,
                    small: true,
                    danger: true,
                    onTap: onReject,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _PaymentsPanel(
          data: data,
          canManagePlan: canManagePlan,
          onPayment: onPayment,
          onReceipt: onReceipt,
        ),
        const SizedBox(height: 16),
        _SubscriptionHistoryPanel(data: data),
      ],
    );
  }
}

class _PaymentsPanel extends StatelessWidget {
  const _PaymentsPanel({
    required this.data,
    required this.canManagePlan,
    required this.onPayment,
    required this.onReceipt,
  });

  final Account360Data data;
  final bool canManagePlan;
  final VoidCallback onPayment;
  final ValueChanged<SubscriptionPayment> onReceipt;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      clip: true,
      padding: EdgeInsets.zero,
      title: 'Paiements d\'abonnement',
      subtitle:
          '${data.payments.length} paiement${data.payments.length > 1 ? 's' : ''} · ${Formatters.formatCurrency(data.subscriptionPaid)} encaissés',
      trailing: canManagePlan
          ? AdminButton(
              label: 'Nouveau paiement',
              icon: Icons.add_card_rounded,
              small: true,
              primary: true,
              onTap: onPayment,
            )
          : null,
      child: data.payments.isEmpty
          ? const AdminEmptyState(
              icon: Icons.payments_outlined,
              title: 'Aucun paiement enregistré',
              message:
                  'Enregistrez le premier encaissement pour suivre les revenus réels de ce compte.',
            )
          : AdminTable(
              minWidth: 900,
              columns: const [
                AdminColumn('DATE', width: 110),
                AdminColumn('MONTANT', width: 120, align: TextAlign.right),
                AdminColumn('MÉTHODE', width: 130),
                AdminColumn('PÉRIODE', flex: 2),
                AdminColumn('RÉFÉRENCE', flex: 2),
                AdminColumn('REÇU', width: 66, align: TextAlign.right),
              ],
              rows: [
                for (final payment in data.payments)
                  AdminRow([
                    Text(
                      Formatters.date.format(payment.createdAt),
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11.5,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(payment.amount),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.titleSm.copyWith(
                        fontSize: 12,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      payment.method.label,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11.5,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${Formatters.date.format(payment.periodStart)} → ${Formatters.date.format(payment.periodEnd)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      payment.reference ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    AdminIconAction(
                      icon: Icons.download_rounded,
                      tooltip: 'Télécharger le reçu',
                      color: context.colors.onSurface,
                      background: context.colors.surfaceContainerLow,
                      onTap: () => onReceipt(payment),
                    ),
                  ]),
              ],
            ),
    );
  }
}

class _SubscriptionHistoryPanel extends StatelessWidget {
  const _SubscriptionHistoryPanel({required this.data});

  final Account360Data data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final events = data.auditLogs
        .where((log) =>
            log.action.startsWith('subscription') ||
            log.action.startsWith('payment'))
        .toList();
    return AdminPanel(
      title: 'Historique de l\'abonnement',
      subtitle:
          '${events.length} action${events.length > 1 ? 's' : ''} administrative(s)',
      clip: true,
      padding: EdgeInsets.zero,
      child: events.isEmpty
          ? const AdminEmptyState(
              icon: Icons.history_rounded,
              title: 'Historique vide',
              message:
                  'Les prochaines actions (approbation, renouvellement, paiement) seront tracées ici.',
            )
          : Column(
              children: [
                for (var i = 0; i < events.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(events[i].icon, size: 16, color: c.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                events[i].label,
                                style: AppTextStyles.titleSm.copyWith(
                                  fontSize: 12,
                                  color: c.onSurface,
                                ),
                              ),
                              Text(
                                '${events[i].details ?? ''} · ${events[i].actorName}',
                                style: AppTextStyles.bodySm.copyWith(
                                  fontSize: 10.5,
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.dateTime.format(events[i].createdAt),
                          style: AppTextStyles.labelXs.copyWith(
                            fontSize: 8.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != events.length - 1)
                    Divider(
                      height: 1,
                      color: c.outlineVariant.withValues(alpha: 0.6),
                    ),
                ],
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activité
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.data});

  final Account360Data data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1060;
        final timeline = _TimelinePanel(events: data.timeline);
        final usage = _UsagePanel(data: data);
        if (!wide) {
          return Column(
            children: [timeline, const SizedBox(height: 16), usage],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: timeline),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: usage),
          ],
        );
      },
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.events});

  final List<AccountTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Chronologie',
      subtitle: '${events.length} événement(s)',
      clip: true,
      padding: EdgeInsets.zero,
      child: events.isEmpty
          ? const AdminEmptyState(
              icon: Icons.history_rounded,
              title: 'Aucun événement',
              message: 'L\'activité du compte apparaîtra ici.',
            )
          : Column(
              children: [
                for (var i = 0; i < events.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            events[i].icon,
                            size: 15,
                            color: c.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                events[i].title,
                                style: AppTextStyles.titleSm.copyWith(
                                  fontSize: 12,
                                  color: c.onSurface,
                                ),
                              ),
                              if (events[i].subtitle != null)
                                Text(
                                  events[i].subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontSize: 10.5,
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.dateTime.format(events[i].date),
                          style: AppTextStyles.labelXs.copyWith(
                            fontSize: 8.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != events.length - 1)
                    Divider(
                      height: 1,
                      color: c.outlineVariant.withValues(alpha: 0.55),
                    ),
                ],
              ],
            ),
    );
  }
}

class _UsagePanel extends StatelessWidget {
  const _UsagePanel({required this.data});

  final Account360Data data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final used = data.usage.where((stat) => stat.events > 0).toList();
    return AdminPanel(
      title: 'Fonctionnalités utilisées',
      subtitle: '${data.usageEvents} usage(s) sur 30 jours',
      child: used.isEmpty
          ? const AdminEmptyState(
              icon: Icons.insights_outlined,
              title: 'Pas encore d\'usage',
              message:
                  'Les fonctionnalités apparaîtront dès que ce compte utilisera l\'application.',
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                children: [
                  for (var i = 0; i < used.take(8).length; i++) ...[
                    Row(
                      children: [
                        Icon(
                          used[i].info.icon,
                          size: 15,
                          color: c.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            used[i].info.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11.5,
                              color: c.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${used[i].events}',
                          style: AppTextStyles.labelXs.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    AdminProgressBar(
                      value: data.usageEvents == 0
                          ? 0
                          : used[i].events / data.usageEvents,
                      color: c.secondary,
                      height: 5,
                    ),
                    if (i != used.take(8).length - 1)
                      const SizedBox(height: 11),
                  ],
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Équipe
// ─────────────────────────────────────────────────────────────────────────────

class _TeamTab extends StatelessWidget {
  const _TeamTab({required this.data});

  final Account360Data data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        AdminPanel(
          title: 'Ateliers',
          subtitle:
              '${data.ateliers.length} atelier${data.ateliers.length > 1 ? 's' : ''}',
          child: data.ateliers.isEmpty
              ? const AdminEmptyState(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Aucun atelier',
                  message: 'Ce compte n\'est rattaché à aucun atelier.',
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final atelier in data.ateliers)
                        Container(
                          width: 240,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                atelier.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleSm.copyWith(
                                  fontSize: 13,
                                  color: c.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                atelier.headStylistName,
                                style: AppTextStyles.bodySm.copyWith(
                                  fontSize: 11,
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                              if (atelier.address != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  atelier.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontSize: 10.5,
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        AdminPanel(
          clip: true,
          padding: EdgeInsets.zero,
          title: 'Membres de l\'équipe',
          subtitle:
              '${data.teamCount} membre${data.teamCount > 1 ? 's' : ''}',
          child: data.team.isEmpty
              ? const AdminEmptyState(
                  icon: Icons.group_outlined,
                  title: 'Aucun membre',
                  message:
                      'Ce compte travaille seul ou n\'encadre aucun membre pour le moment.',
                )
              : AdminTable(
                  minWidth: 760,
                  columns: const [
                    AdminColumn('MEMBRE', flex: 3),
                    AdminColumn('RÔLE', flex: 2),
                    AdminColumn('TÉLÉPHONE', flex: 2),
                    AdminColumn('ATELIER', flex: 2),
                    AdminColumn('STATUT', width: 110),
                  ],
                  rows: [
                    for (final member in data.team)
                      AdminRow([
                        Text(
                          member.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSm.copyWith(
                            fontSize: 12.5,
                            color: c.onSurface,
                          ),
                        ),
                        Text(
                          member.role.label,
                          style: AppTextStyles.bodySm.copyWith(
                            fontSize: 11.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          member.phone.trim().isEmpty ? '—' : member.phone,
                          style: AppTextStyles.bodySm.copyWith(
                            fontSize: 11.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          member.atelierName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            fontSize: 11.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        AdminBadge(
                          label: member.isActive ? 'ACTIF' : 'SUSPENDU',
                          foreground: member.isActive
                              ? c.statusDone
                              : c.statusProblem,
                          background: member.isActive
                              ? c.statusDoneBg
                              : c.statusProblemBg,
                        ),
                      ]),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Support
// ─────────────────────────────────────────────────────────────────────────────

class _SupportTab extends StatelessWidget {
  const _SupportTab({required this.messages, required this.onReply});

  final List<SupportMessage> messages;
  final ValueChanged<SupportMessage> onReply;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Messages support',
      subtitle:
          '${messages.length} message${messages.length > 1 ? 's' : ''} envoyé${messages.length > 1 ? 's' : ''} par ce compte',
      child: messages.isEmpty
          ? const AdminEmptyState(
              icon: Icons.forum_outlined,
              title: 'Aucun message',
              message: 'Ce compte n\'a jamais contacté le support.',
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                children: [
                  for (var i = 0; i < messages.length; i++) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: messages[i].isRead
                              ? c.outlineVariant
                              : c.statusInProgress.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 15,
                                color: c.secondary,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  messages[i].senderName,
                                  style: AppTextStyles.titleSm.copyWith(
                                    fontSize: 12,
                                    color: c.onSurface,
                                  ),
                                ),
                              ),
                              if (!messages[i].isRead)
                                AdminBadge(
                                  label: 'NON LU',
                                  foreground: c.statusInProgress,
                                  background: c.statusInProgressBg,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                Formatters.dateTime.format(messages[i].sentAt),
                                style: AppTextStyles.labelXs.copyWith(
                                  fontSize: 8.5,
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            messages[i].content,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 12,
                              color: c.onSurface,
                            ),
                          ),
                          if (messages[i].reply != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: c.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Réponse : ${messages[i].reply}',
                                style: AppTextStyles.bodySm.copyWith(
                                  fontSize: 11.5,
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AdminButton(
                              label: messages[i].isReplied
                                  ? 'Modifier la réponse'
                                  : 'Répondre',
                              icon: Icons.reply_rounded,
                              small: true,
                              onTap: () => onReply(messages[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != messages.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes
// ─────────────────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({
    required this.notes,
    required this.controller,
    required this.busy,
    required this.onAdd,
    required this.onDelete,
  });

  final List<AdminNote> notes;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<AdminNote> onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        AdminPanel(
          title: 'Nouvelle note interne',
          subtitle: 'Visible uniquement par les administrateurs.',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 3,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12.5,
                    color: c.onSurface,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.surfaceContainerLow,
                    hintText:
                        'Ex. A appelé pour un problème de connexion, promesse de paiement au 15.',
                    hintStyle: AppTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      color: c.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.goldInk, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: AdminButton(
                    label: 'Ajouter la note',
                    icon: Icons.add_rounded,
                    primary: true,
                    small: true,
                    onTap: busy ? null : onAdd,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AdminPanel(
          title: 'Notes internes',
          subtitle: '${notes.length} note${notes.length > 1 ? 's' : ''}',
          child: notes.isEmpty
              ? const AdminEmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'Aucune note',
                  message:
                      'Ajoutez du contexte support : appels, promesses, incidents.',
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      for (var i = 0; i < notes.length; i++) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: c.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.sticky_note_2_outlined,
                                    size: 14,
                                    color: c.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      notes[i].authorName,
                                      style: AppTextStyles.labelCaps.copyWith(
                                        fontSize: 8.5,
                                        color: c.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.dateTime.format(
                                      notes[i].createdAt,
                                    ),
                                    style: AppTextStyles.labelXs.copyWith(
                                      fontSize: 8,
                                      color: c.onSurfaceVariant,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => onDelete(notes[i]),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 15,
                                      color: c.statusProblem,
                                    ),
                                    tooltip: 'Supprimer',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notes[i].text,
                                style: AppTextStyles.bodySm.copyWith(
                                  fontSize: 12,
                                  color: c.onSurface,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i != notes.length - 1)
                          const SizedBox(height: 9),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
