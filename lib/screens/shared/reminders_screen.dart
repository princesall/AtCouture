import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_messages.dart';
import '../../core/utils/whatsapp_launcher.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../../services/order_service.dart';

List<Order> _visibleOrders(AppUser user) {
  if (user.isCompanyOwner && user.companyId != null) {
    return CompanyService.instance.allOrdersOfCompany(user.companyId!);
  }
  final atelierId = user.atelierId;
  return atelierId == null ? [] : OrderService.instance.ordersOfAtelier(atelierId);
}

/// Rappels automatiques — plan Pro et plus (permissions.hasReminders).
/// Regroupe les commandes non terminées par urgence de livraison : en retard,
/// aujourd'hui, demain, cette semaine.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pending = _visibleOrders(user).where((o) =>
        o.dueDate != null &&
        o.status != OrderStatus.completed).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final overdue = <Order>[];
    final dueToday = <Order>[];
    final dueTomorrow = <Order>[];
    final dueThisWeek = <Order>[];
    final later = <Order>[];

    for (final o in pending) {
      final due = DateTime(o.dueDate!.year, o.dueDate!.month, o.dueDate!.day);
      final diff = due.difference(today).inDays;
      if (diff < 0) {
        overdue.add(o);
      } else if (diff == 0) {
        dueToday.add(o);
      } else if (diff == 1) {
        dueTomorrow.add(o);
      } else if (diff <= 7) {
        dueThisWeek.add(o);
      } else {
        later.add(o);
      }
    }

    final sections = <(String, List<Order>, Color)>[
      ('En retard', overdue, c.error),
      ('Aujourd\'hui', dueToday, c.tertiary),
      ('Demain', dueTomorrow, c.primary),
      ('Cette semaine', dueThisWeek, c.secondary),
      ('Plus tard', later, c.onSurfaceVariant),
    ].where((s) => s.$2.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Rappels automatiques'),
        backgroundColor: c.background,
        foregroundColor: c.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: sections.isEmpty
            ? Center(
                child: EmptyState(
                  title: 'Aucun rappel',
                  subtitle: 'Aucune commande en attente n\'a de date de livraison proche',
                  icon: Icons.notifications_none_rounded,
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 32),
                children: [
                  for (final section in sections) ...[
                    Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: section.$3, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(section.$1, style: AppTextStyles.titleSm.copyWith(color: section.$3)),
                      const SizedBox(width: 6),
                      Text('(${section.$2.length})', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    ...section.$2.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: OrderListItem(
                            clientName: o.clientName,
                            garmentType: '${o.description ?? 'Sans description'} · ${Formatters.date.format(o.dueDate!)}',
                            price: (o.price ?? 0).toString(),
                            status: o.status,
                            trailing: IconButton(
                              icon: const Icon(Icons.notifications_active_outlined),
                              color: c.primary,
                              tooltip: 'Envoyer un rappel WhatsApp',
                              onPressed: () => WhatsAppLauncher.sendMessage(
                                phone: o.clientPhone,
                                message: OrderMessages.reminder(o),
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
      ),
    );
  }
}
