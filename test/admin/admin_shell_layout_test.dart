import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:styleconnect/admin/shell/admin_shell.dart';
import 'package:styleconnect/core/theme/app_theme.dart';
import 'package:styleconnect/data/admin_demo_data.dart';
import 'package:styleconnect/models/app_user.dart';
import 'package:styleconnect/models/subscription_plan.dart';
import 'package:styleconnect/models/user_role.dart';
import 'package:styleconnect/providers/auth_provider.dart';
import 'package:styleconnect/providers/theme_provider.dart';
import 'package:styleconnect/services/auth_service.dart';
import 'package:styleconnect/services/company_service.dart';
import 'package:styleconnect/services/order_service.dart';
import 'package:styleconnect/services/platform_config_service.dart';

/// Vérifie que la console admin se construit et navigue sur toutes ses
/// destinations, en desktop large comme en fenêtre compacte, sans exception
/// de layout (overflow) ni de provider manquant.
void main() {
  testWidgets('la console admin se construit sur toutes les pages', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AuthService.seedDebugAdmin();

    final auth = AuthProvider();
    final theme = ThemeProvider();

    await tester.runAsync(() async {
      await initializeDateFormatting('fr_FR');
      await _seedDemoAccounts();
      await auth.initialize();
      final ok = await auth.signIn(
        'admin@styleconnect.ml',
        'admin123',
        requireAdmin: true,
      );
      expect(ok, isTrue);
      await theme.initialize();
    });

    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
          ChangeNotifierProvider<CompanyService>.value(value: CompanyService.instance),
          ChangeNotifierProvider<OrderService>.value(value: OrderService.instance),
          ChangeNotifierProvider<PlatformConfigService>.value(
            value: PlatformConfigService.instance,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AdminShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'tableau de bord');

    for (final label in [
      'Stylistes',
      'Abonnements',
      'Entreprises',
      'Messages',
      'Mon compte',
      'Plateforme',
      'Tableau de bord',
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'page $label');
    }

    // Les quatre onglets Plateforme ont des mises en page très différentes :
    // on les construit tous pour détecter les overflows.
    await tester.tap(find.text('Plateforme').first);
    await tester.pumpAndSettle();
    for (final tab in ["QUALITÉ", "ADOPTION", "SYSTÈME", "VUE D'ENSEMBLE"]) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'onglet $tab');
    }

    // Fenêtre compacte : la sidebar passe en drawer, les tableaux en scroll
    // horizontal, la boîte de réception en mode liste/détail.
    await tester.binding.setSurfaceSize(const Size(700, 900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'layout compact');

    // Les onglets Plateforme en fenêtre compacte (formulaires, jobs, erreurs).
    for (final tab in ["QUALITÉ", "ADOPTION", "SYSTÈME"]) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'compact $tab');
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Jeu de comptes minimal pour exercer les tableaux, les badges d'expiration
/// et une demande d'abonnement en attente — sans Firebase.
Future<void> _seedDemoAccounts() async {
  final now = DateTime.now();
  final accounts = [
    AppUser(
      id: 'demo_stylist_1',
      email: 'awa@demo.ml',
      fullName: 'Awa Cissé',
      phone: '+223 70 00 00 11',
      role: UserRole.stylist,
      atelierId: 'atelier_awa',
      atelierName: 'Awa Couture',
      plan: SubscriptionPlan.pro,
      planExpiresAt: now.add(const Duration(days: 4)),
      createdAt: now.subtract(const Duration(days: 140)),
    ),
    AppUser(
      id: 'demo_stylist_2',
      email: 'ibrahim@demo.ml',
      fullName: 'Ibrahim Keïta',
      phone: '+223 70 00 00 12',
      role: UserRole.stylist,
      atelierId: 'atelier_ibrahim',
      atelierName: 'Le Fil d\'Or',
      plan: SubscriptionPlan.starter,
      planExpiresAt: now.add(const Duration(days: 60)),
      createdAt: now.subtract(const Duration(days: 80)),
    ),
    AppUser(
      id: 'demo_stylist_3',
      email: 'seydou@demo.ml',
      fullName: 'Seydou Bagayoko',
      phone: '+223 70 00 00 13',
      role: UserRole.stylist,
      atelierId: 'atelier_seydou',
      atelierName: 'Bagayoko & Frères',
      plan: SubscriptionPlan.free,
      isActive: false,
      createdAt: now.subtract(const Duration(days: 30)),
    ),
  ];

  for (final account in accounts) {
    await AdminDemoData.addStylist(account);
  }
  await AdminDemoData.requestSubscription(
    'demo_stylist_1',
    SubscriptionPlan.enterprise,
  );
}
