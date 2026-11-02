import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'admin_preview/admin_preview_shell.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

/// Point d'entrée de la MAQUETTE de la console admin web.
///
/// Lancement :
///   flutter run -d chrome -t lib/main_admin_preview.dart
///
/// Cet entrypoint est totalement indépendant de l'application mobile : il
/// n'initialise ni Firebase, ni l'authentification, et n'affiche que des
/// données factices (`lib/admin_preview/preview_data.dart`). Il sert à valider
/// le layout desktop avant d'engager la vraie migration « admin sur web ».
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  try {
    await themeProvider.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Stockage local indisponible (navigation privée, stockage partitionné) :
    // on reste simplement sur le thème clair par défaut.
  }

  runApp(AdminPreviewApp(themeProvider: themeProvider));
}

class AdminPreviewApp extends StatelessWidget {
  const AdminPreviewApp({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'StyleConnect — Console admin (maquette)',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AdminPreviewShell(),
        ),
      ),
    );
  }
}
