import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:styleconnect/admin/pages/admin_account_360_page.dart';
import 'package:styleconnect/core/theme/app_theme.dart';
import 'package:styleconnect/data/admin_demo_data.dart';
import 'package:styleconnect/models/app_user.dart';
import 'package:styleconnect/models/subscription_plan.dart';
import 'package:styleconnect/models/user_role.dart';
import 'package:styleconnect/providers/theme_provider.dart';
import 'package:styleconnect/services/auth_service.dart';
import 'package:styleconnect/services/order_service.dart';

void main() {
  testWidgets('la fiche 360 se construit sur tous ses onglets', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AuthService.seedDebugAdmin();

    final now = DateTime.now();
    final user = AppUser(
      id: 'demo_360_stylist',
      email: 'fiche360@demo.ml',
      fullName: 'Aminata Traoré',
      phone: '+223 70 00 36 36',
      role: UserRole.stylist,
      atelierId: 'atelier_360',
      atelierName: 'Aminata Couture',
      plan: SubscriptionPlan.pro,
      planExpiresAt: now.add(const Duration(days: 12)),
      createdAt: now.subtract(const Duration(days: 200)),
      lastLoginAt: now.subtract(const Duration(days: 2)),
    );
    await tester.runAsync(() async {
      await initializeDateFormatting('fr_FR');
      await AdminDemoData.addStylist(user);
      await OrderService.instance.createOrder(
        clientName: 'Client Fiche 360',
        clientPhone: '+223 76 00 36 36',
        atelierId: 'atelier_360',
        atelierName: 'Aminata Couture',
        price: 75000,
        deposit: 25000,
        createdByName: 'Aminata Traoré',
      );
    });

    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final theme = ThemeProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AdminAccount360Page(userId: 'demo_360_stylist'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aminata Traoré'), findsWidgets);
    expect(tester.takeException(), isNull, reason: 'synthèse 360');

    for (final tab in [
      'ABONNEMENT',
      'ACTIVITÉ',
      'ÉQUIPE',
      'SUPPORT',
      'NOTES',
      'SYNTHÈSE',
    ]) {
      await _tapChip(tester, tab);
      expect(tester.takeException(), isNull, reason: 'onglet $tab');
    }

    await tester.binding.setSurfaceSize(const Size(700, 900));
    await tester.pumpAndSettle();
    for (final tab in ['ABONNEMENT', 'ACTIVITÉ', 'ÉQUIPE', 'SUPPORT', 'NOTES']) {
      await _tapChip(tester, tab);
      expect(tester.takeException(), isNull, reason: 'compact $tab');
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// En fenêtre compacte, les onglets passent sur plusieurs lignes et peuvent
/// sortir de l'écran : il faut les amener dans la zone visible avant de taper,
/// sinon le tap est silencieusement ignoré et l'onglet n'est jamais construit.
Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.text(label).last;
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}
