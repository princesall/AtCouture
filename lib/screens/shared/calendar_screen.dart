import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../../services/order_service.dart';

/// Toutes les commandes visibles par cet utilisateur (styliste solo → son
/// atelier ; Chef d'Entreprise → tous les ateliers de sa société).
List<Order> _visibleOrders(AppUser user) {
  if (user.isCompanyOwner && user.companyId != null) {
    return CompanyService.instance.allOrdersOfCompany(user.companyId!);
  }
  final atelierId = user.atelierId;
  return atelierId == null ? [] : OrderService.instance.ordersOfAtelier(atelierId);
}

/// Calendrier des livraisons — plan Pro et plus (permissions.hasCalendar).
/// Regroupe les commandes ayant une date de livraison par jour, et permet
/// de naviguer mois par mois.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final orders = _visibleOrders(user).where((o) => o.dueDate != null).toList();

    final ordersByDay = <DateTime, List<Order>>{};
    for (final o in orders) {
      final d = o.dueDate!;
      final key = DateTime(d.year, d.month, d.day);
      ordersByDay.putIfAbsent(key, () => []).add(o);
    }

    final selectedOrders = _selectedDay == null ? const <Order>[] : (ordersByDay[_selectedDay] ?? const []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendrier des livraisons'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(children: [
          _buildMonthHeader(),
          const SizedBox(height: 8),
          _buildWeekdayLabels(),
          _buildMonthGrid(ordersByDay),
          const Divider(height: 24),
          Expanded(
            child: _selectedDay == null
                ? Center(
                    child: Text('Sélectionnez un jour pour voir ses livraisons',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                  )
                : selectedOrders.isEmpty
                    ? Center(
                        child: EmptyState(
                          title: 'Aucune livraison',
                          subtitle: 'Aucune commande prévue ce jour-là',
                          icon: Icons.calendar_today_outlined,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        itemCount: selectedOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final o = selectedOrders[i];
                          return OrderListItem(
                            clientName: o.clientName,
                            garmentType: o.description ?? 'Sans description',
                            price: (o.price ?? 0).toString(),
                            status: o.status,
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMonthHeader() {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
        ),
        Expanded(
          child: Text(
            '${months[_month.month - 1]} ${_month.year}',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(color: AppColors.primary),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
        ),
      ]),
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Row(
      children: labels
          .map((l) => Expanded(
                child: Center(
                  child: Text(l, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMonthGrid(Map<DateTime, List<Order>> ordersByDay) {
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // weekday: 1=lundi .. 7=dimanche → nombre de cases vides avant le 1er
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - leadingBlanks + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }
              final day = DateTime(_month.year, _month.month, dayNum);
              final hasOrders = ordersByDay.containsKey(day);
              final isSelected = _selectedDay == day;
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = isSelected ? null : day),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday && !isSelected ? Border.all(color: AppColors.primary) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: AppTextStyles.bodySm.copyWith(
                            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        if (hasOrders)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.onPrimary : AppColors.tertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
