import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../screens/admin_access_denied_screen.dart';
import '../screens/admin_force_password_screen.dart';
import '../screens/admin_login_screen.dart';
import '../pages/admin_account_360_page.dart';
import '../shell/admin_shell.dart';

/// Routes de la console admin. Le cloisonnement est ici, pas dans les écrans :
/// aucune page protégée n'est construite tant que le rôle admin n'est pas
/// confirmé par le document `users/{uid}` (voir AuthProvider).
abstract final class AdminRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final location = state.matchedLocation;
        final isLogin = location == '/login';
        final isDenied = location == '/access-denied';
        final isForcedPassword = location == '/force-password';

        // Pendant l'initialisation ou une tentative de connexion, on laisse
        // l'écran courant afficher son état de chargement.
        if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
          return null;
        }

        if (!auth.isAuthenticated || auth.user == null) {
          return isLogin ? null : '/login';
        }

        // Session valide mais rôle non-admin (compte restauré depuis ce
        // navigateur, ou compte rétrogradé) : jamais d'accès à la console.
        if (!auth.user!.isAdmin) {
          return isDenied ? null : '/access-denied';
        }

        // Mot de passe temporaire : on bloque tout le reste tant qu'il n'est
        // pas changé.
        if (auth.user!.mustChangePassword) {
          return isForcedPassword ? null : '/force-password';
        }

        if (isLogin || isDenied || isForcedPassword) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/access-denied',
          builder: (_, _) => const AdminAccessDeniedScreen(),
        ),
        GoRoute(
          path: '/force-password',
          builder: (_, _) => const AdminForcePasswordScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) => const AdminShell(),
        ),
        GoRoute(
          path: '/stylists/:id',
          builder: (context, state) => AdminAccount360Page(
            userId: state.pathParameters['id']!,
            onBack: () => context.go('/'),
          ),
        ),
      ],
    );
  }
}
