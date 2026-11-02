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

  testWidgets('les actions de la fiche 360 aboutissent sans erreur', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AuthService.seedDebugAdmin();

    final now = DateTime.now();
    final user = AppUser(
      id: 'demo_360_actions',
      email: 'actions@demo.ml',
      fullName: 'Fatoumata Diallo',
      phone: '+223 70 00 44 44',
      role: UserRole.stylist,
      atelierId: 'atelier_actions',
      atelierName: 'Diallo Couture',
      plan: SubscriptionPlan.pro,
      planExpiresAt: now.add(const Duration(days: 30)),
      createdAt: now.subtract(const Duration(days: 90)),
      lastLoginAt: now.subtract(const Duration(hours: 3)),
    );
    await tester.runAsync(() async {
      await initializeDateFormatting('fr_FR');
      await AdminDemoData.addStylist(user);
    });

    await tester.binding.setSurfaceSize(const Size(1500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: ThemeProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AdminAccount360Page(userId: 'demo_360_actions'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Note interne : passe par showAdminSnack() après un await. Sans lecture
    // non-écoutante du thème, ce callback levait en debug l'assertion provider
    // « Tried to listen to a value exposed with provider ».
    await _tapChip(tester, 'NOTES');
    await tester.enterText(
      find.byType(TextField).first,
      'A appelé pour un problème de connexion',
    );
    await _tapVisible(tester, find.text('Ajouter la note'));
    expect(tester.takeException(), isNull, reason: 'ajout de note');
    expect(
      find.textContaining('problème de connexion'),
      findsWidgets,
      reason: 'la note ajoutée doit apparaître dans la liste',
    );

    // Changement de plan depuis le menu d'actions.
    await _tapChip(tester, 'SYNTHÈSE');
    final menu = find.byIcon(Icons.more_horiz_rounded);
    await _tapVisible(tester, menu);
    await tester.tap(find.text('Changer de plan').last);
    await tester.pumpAndSettle();
    expect(find.text('Starter'), findsWidgets, reason: 'sélecteur de plan');
    await tester.tap(find.text('Starter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changer le plan').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'changement de plan');
    expect(
      AdminDemoData.findAnyUserById('demo_360_actions')!.plan,
      SubscriptionPlan.starter,
    );

    // Les snackbars vivent 3 s : on les laisse expirer, sinon les timers
    // encore actifs font échouer les invariants de fin de test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('le renouvellement prolonge depuis l\'échéance en cours', () async {
    SharedPreferences.setMockInitialValues({});
    AuthService.seedDebugAdmin();

    final expiry = DateTime.now().add(const Duration(days: 180));
    final user = AppUser(
      id: 'demo_360_renew',
      email: 'renew@demo.ml',
      fullName: 'Kadiatou Bah',
      phone: '+223 70 00 55 55',
      role: UserRole.stylist,
      atelierId: 'atelier_renew',
      atelierName: 'Bah Couture',
      plan: SubscriptionPlan.pro,
      planExpiresAt: expiry,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    );
    await AdminDemoData.addStylist(user);

    await AdminDemoData.renewSubscription(user.id);

    final updated = AdminDemoData.findAnyUserById('demo_360_renew')!;
    // 12 mois ajoutés AU-delà des 180 jours restants (et non 365 jours à
    // partir d'aujourd'hui, ce qui aurait raccourci l'abonnement).
    expect(
      updated.planExpiresAt!.difference(expiry).inDays,
      closeTo(365, 1),
    );
  });
}

/// Amène un widget dans la zone visible puis tape dessus. Indispensable dans
/// la fiche 360 : les onglets passent sur plusieurs lignes en fenêtre compacte
/// et les actions d'en-tête sortent de l'écran dès qu'on a fait défiler.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
