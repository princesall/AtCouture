import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:styleconnect/app.dart';
import 'package:styleconnect/providers/auth_provider.dart';
import 'package:styleconnect/providers/theme_provider.dart';

void main() {
  testWidgets('StyleConnect affiche le splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final authProvider = AuthProvider();
    final themeProvider = ThemeProvider();
    // AuthProvider.initialize() attend un vrai Future.delayed (simulation de
    // latence réseau). Sous flutter test, l'horloge est simulée et n'avance
    // que via tester.pump(duration) : un Future.delayed réel appelé hors de
    // tester.runAsync() ne se termine donc jamais tout seul, ce qui bloquait
    // le test indéfiniment. runAsync() exécute ce bout de code dans la vraie
    // zone asynchrone pour que le délai s'écoule normalement.
    await tester.runAsync(() => authProvider.initialize());
    await tester.runAsync(() => themeProvider.initialize());

    await tester.pumpWidget(StyleConnectApp(authProvider: authProvider, themeProvider: themeProvider));
    await tester.pump();

    expect(find.text('StyleConnect'), findsOneWidget);

    // Chaque widget .animate() du splash programme son démarrage via un
    // Future.delayed interne à flutter_animate (jusqu'à 500ms ici). Sous
    // l'horloge simulée du test, ce délai ne s'écoule que si on avance le
    // temps explicitement : sans ce pump, le test échoue avec "Pending
    // timers" à la fin (le minuteur n'a jamais eu l'occasion de se déclencher).
    await tester.pump(const Duration(milliseconds: 600));

    // Démonte l'arbre de widgets pour arrêter proprement le ticker du
    // spinner en boucle infinie, plutôt que de le laisser actif jusqu'à la
    // fin du test.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
