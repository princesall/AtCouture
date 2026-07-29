import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/company/company_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/stylist/stylist_shell.dart';
import '../screens/tailor/tailor_shell.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final location = state.matchedLocation;
        final isSplash = location == '/splash';
        final isAuthRoute = location.startsWith('/auth');

        if (auth.status == AuthStatus.initial ||
            (auth.status == AuthStatus.loading && isSplash)) {
          return isSplash ? null : '/splash';
        }

        if (!auth.isAuthenticated) {
          if (isSplash) return '/auth/login';
          return isAuthRoute ? null : '/auth/login';
        }

        if (isAuthRoute || isSplash) {
          return switch (auth.user!.role) {
            UserRole.admin => '/admin',
            UserRole.companyOwner => '/company',
            UserRole.stylist => '/stylist',
            UserRole.tailor => '/tailor',
          };
        }

        // ── Cloisonnement strict par rôle ────────────────────────────────
        // Empêche un utilisateur connecté d'accéder à un espace qui ne
        // correspond pas à son rôle réel (ex: un stylist tapant /admin
        // directement dans l'URL, ou un compte rétrogradé qui garde un
        // onglet /company ouvert). Le rôle vient TOUJOURS du document
        // utilisateur authentifié, jamais d'un état local modifiable.
        final correctHome = switch (auth.user!.role) {
          UserRole.admin => '/admin',
          UserRole.companyOwner => '/company',
          UserRole.stylist => '/stylist',
          UserRole.tailor => '/tailor',
        };
        final isOnOwnSpace = location.startsWith(correctHome);
        if (!isOnOwnSpace) {
          return correctHome;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, _) => const SplashScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/stylist',
          builder: (_, _) => const StylistShell(),
        ),
        GoRoute(
          path: '/company',
          builder: (_, _) => const CompanyShell(),
        ),
        GoRoute(
          path: '/tailor',
          builder: (_, _) => const TailorShell(),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, _) => const AdminShell(),
        ),
      ],
    );
  }
}
