import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Logo ──────────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: c.tertiaryContainer.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/branding/logo_mark_transparent.png',
                  fit: BoxFit.contain,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 24),

              // ── Nom ───────────────────────────────────────────────────────
              Text(
                'StyleConnect',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              // ── Tagline ──────────────────────────────────────────────────
              Text(
                'L\'excellence de la couture africaine',
                style: AppTextStyles.bodyLg.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

              const Spacer(flex: 2),

              // ── Loader ────────────────────────────────────────────────────
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.tertiaryFixedDim.withValues(alpha: 0.8),
                ),
              ).animate(onPlay: (c) => c.repeat()).fadeIn(delay: 500.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
