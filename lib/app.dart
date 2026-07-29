import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/firebase_service.dart';

class StyleConnectApp extends StatefulWidget {
  const StyleConnectApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

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
      ],
      child: MaterialApp.router(
        title: 'StyleConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
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

  runApp(StyleConnectApp(authProvider: authProvider));
}
