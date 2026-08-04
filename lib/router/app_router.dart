import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/auth/force_password_change_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/google_profile_completion_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/company/company_shell.dart';
import '../services/auth_service.dart';
import '../screens/shared/order_tracking_screen.dart';
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
        // Écran de suivi de commande : public, ne nécessite aucun compte
        // (un client final y accède avec juste son numéro de commande).
        final isTrackingRoute = location.startsWith('/suivi');

        if (auth.status == AuthStatus.initial ||
            (auth.status == AuthStatus.loading && isSplash)) {
          return isSplash ? null : '/splash';
        }

        if (isTrackingRoute) return null;

        if (!auth.isAuthenticated) {
          if (isSplash) return '/auth/login';
          return isAuthRoute ? null : '/auth/login';
        }

        // Rôle actuel, utilisé pour tous les cas ci-dessous. Vient TOUJOURS
        // du document utilisateur authentifié, jamais d'un état local
        // modifiable.
        final correctHome = switch (auth.user!.role) {
          UserRole.admin => '/admin',
          UserRole.companyOwner => '/company',
          UserRole.stylist => '/stylist',
          UserRole.tailor => '/tailor',
        };

        // Compte créé par un chef (Couturier ou Chef d'atelier, voir
        // CompanyService.createTailor / createAtelierHead) avec un mot de
        // passe temporaire : on bloque tout accès à l'app tant qu'il n'a pas
        // choisi son propre mot de passe, quel que soit l'écran visé.
        final isForcePasswordRoute = location == '/auth/force-password-change';
        if (auth.user!.mustChangePassword) {
          return isForcePasswordRoute ? null : '/auth/force-password-change';
        }

        if (isAuthRoute || isSplash) {
          return correctHome;
        }

        // ── Cloisonnement strict par rôle ────────────────────────────────
        // Empêche un utilisateur connecté d'accéder à un espace qui ne
        // correspond pas à son rôle réel (ex: un stylist tapant /admin
        // directement dans l'URL, ou un compte rétrogradé qui garde un
        // onglet /company ouvert).
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
          path: '/auth/complete-profile',
          builder: (context, state) {
            final pending = state.extra;
            if (pending is! GoogleSignInNeedsProfile) {
              // Arrivé directement sur cette URL sans passer par la connexion
              // Google (ex: rafraîchissement de page) — rien à compléter.
              return const LoginScreen();
            }
            return GoogleProfileCompletionScreen(pending: pending);
          },
        ),
        GoRoute(
          path: '/auth/force-password-change',
          builder: (_, _) => const ForcePasswordChangeScreen(),
        ),
        GoRoute(
          path: '/suivi',
          builder: (_, _) => const OrderTrackingScreen(),
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
