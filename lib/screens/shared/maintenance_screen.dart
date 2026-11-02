import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/platform_config_service.dart';

/// Écran public affiché quand `systemConfig/app.maintenanceMode` est actif.
/// Les administrateurs ne sont pas bloqués (le router les laisse passer).
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await PlatformConfigService.instance.reload();
      if (!mounted) return;
      if (!PlatformConfigService.instance.maintenanceMode) {
        // Le router rebascule automatiquement ; ce message couvre le cas où
        // l'utilisateur est déjà sur l'écran au moment de la bascule.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La plateforme est de nouveau disponible.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toujours indisponible. Réessayez dans quelques instants.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final config = context.watch<PlatformConfigService>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: c.heroGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.construction_rounded,
                      size: 30,
                      color: c.tertiary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Maintenance en cours',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLgMobile.copyWith(
                      color: c.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    config.maintenanceMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm.copyWith(
                      color: c.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _retrying ? null : _retry,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _retrying
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.onPrimary,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        _retrying ? 'VÉRIFICATION…' : 'RÉESSAYER',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: c.onPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  if (auth.isAuthenticated) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<AuthProvider>().signOut(),
                      child: Text(
                        'Se déconnecter',
                        style: AppTextStyles.bodySm.copyWith(
                          color: c.onSurfaceVariant,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'StyleConnect · ${config.version}',
                    style: AppTextStyles.labelXs.copyWith(
                      color: c.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
