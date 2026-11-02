import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';
import '../services/firebase_service.dart';
import '../services/order_service.dart';
import '../services/platform_config_service.dart';
import '../services/platform_telemetry_service.dart';
import 'router/admin_router.dart';

/// Bootstrap de la console admin web.
///
/// Différences assumées avec le bootstrap mobile :
///  - aucune orientation forcée, aucun overlay système mobile ;
///  - Firebase requis en production (la console n'a pas de données locales) ;
///  - en debug uniquement, un compte admin de démonstration est injecté pour
///    pouvoir développer sans projet Firebase. Le bloc est protégé par
///    `kDebugMode` : les identifiants ne sont pas compilés en release.
Future<void> adminBootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR');

  // Ne jamais bloquer le démarrage de la console sur un SDK Firebase lent à
  // charger (scripts CDN, réseau mobile) : au-delà de 15 s on continue, et
  // l'écran de connexion affiche une erreur explicite au moment de se
  // connecter plutôt qu'un écran blanc sans fin.
  try {
    await FirebaseService.initialize().timeout(const Duration(seconds: 15));
  } catch (_) {}

  if (kDebugMode && !FirebaseService.isAvailable) {
    AuthService.seedDebugAdmin();
  }

  PlatformTelemetryService.instance.installGlobalHandlers();
  try {
    await PlatformConfigService.instance
        .load()
        .timeout(const Duration(seconds: 8));
  } catch (_) {}

  final authProvider = AuthProvider();
  await authProvider.initialize();

  final themeProvider = ThemeProvider();
  try {
    await themeProvider.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Stockage local indisponible : thème clair par défaut, la console reste
    // parfaitement utilisable.
  }

  runApp(
    AdminConsoleApp(
      authProvider: authProvider,
      themeProvider: themeProvider,
    ),
  );
}

class AdminConsoleApp extends StatefulWidget {
  const AdminConsoleApp({
    super.key,
    required this.authProvider,
    required this.themeProvider,
  });

  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  @override
  State<AdminConsoleApp> createState() => _AdminConsoleAppState();
}

class _AdminConsoleAppState extends State<AdminConsoleApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AdminRouter.createRouter(widget.authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider.value(value: CompanyService.instance),
        ChangeNotifierProvider.value(value: OrderService.instance),
        ChangeNotifierProvider.value(value: PlatformConfigService.instance),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          title: 'StyleConnect — Console admin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
