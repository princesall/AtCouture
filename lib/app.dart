import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/company_service.dart';
import 'services/firebase_service.dart';
import 'services/order_service.dart';

class StyleConnectApp extends StatefulWidget {
  const StyleConnectApp({super.key, required this.authProvider, required this.themeProvider});

  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  @override
  State<StyleConnectApp> createState() => _StyleConnectAppState();
}

class _StyleConnectAppState extends State<StyleConnectApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.authProvider);
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
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          title: 'StyleConnect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await initializeDateFormatting('fr_FR');
  await FirebaseService.initialize();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  final themeProvider = ThemeProvider();
  // Un blocage/échec de SharedPreferences (observé en pratique sur certains
  // navigateurs/profils, ex: stockage partitionné ou bloqué par une
  // extension) ne doit JAMAIS empêcher l'app de démarrer — sans ce délai,
  // l'app resterait bloquée sur un écran blanc pour toujours si cet appel
  // ne se termine pas. Le thème retombe simplement sur clair par défaut.
  try {
    await themeProvider.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {}

  runApp(StyleConnectApp(authProvider: authProvider, themeProvider: themeProvider));
}
