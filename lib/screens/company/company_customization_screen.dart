import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/plan_guard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/company_customization_service.dart';

/// Personnalisation de marque — plan Entreprise uniquement
/// (permissions.hasCustomization). Le nom et la couleur choisis sont
/// appliqués à l'en-tête des documents PDF générés (factures, devis) —
/// voir OrderPdf.
class CompanyCustomizationScreen extends StatefulWidget {
  const CompanyCustomizationScreen({super.key});

  @override
  State<CompanyCustomizationScreen> createState() => _CompanyCustomizationScreenState();
}

class _CompanyCustomizationScreenState extends State<CompanyCustomizationScreen> {
  late final TextEditingController _brandNameController;
  late Color _accentColor;
  late String _companyId;
  bool _isSaving = false;
  bool _isLoading = true;

  List<Color> _palette(AppColorPalette c) => [
    c.primary,
    c.secondary,
    c.tertiary,
    const Color(0xFF2E7D32),
    const Color(0xFFB71C1C),
    const Color(0xFF6A1B9A),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _companyId = user.companyId ?? user.id;
    // Valeurs par défaut affichées pendant le chargement — remplacées ci-
    // dessous dès que la personnalisation déjà enregistrée arrive de Firestore.
    _brandNameController = TextEditingController(text: user.atelierName ?? '');
    _accentColor = context.read<ThemeProvider>().colors.primary;
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    final branding = await CompanyCustomizationService.instance.brandingFor(_companyId);
    if (!mounted) return;
    setState(() {
      if (branding.brandName != null) _brandNameController.text = branding.brandName!;
      if (branding.accentColor != null) _accentColor = branding.accentColor!;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await CompanyCustomizationService.instance.setBranding(
      _companyId,
      CompanyBranding(brandName: _brandNameController.text.trim(), accentColor: _accentColor),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personnalisation enregistrée')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<AuthProvider>().user!.permissions;
    if (!permissions.hasCustomization) {
      return PlanLockedScreen(title: 'Personnalisation', message: permissions.customizationLockedMessage);
    }
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Personnalisation'),
        backgroundColor: c.background,
        foregroundColor: c.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: c.primary))
            : Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personnalisez le nom de marque et la couleur utilisés sur vos documents '
                'générés (factures, devis).',
                style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Nom de marque', style: AppTextStyles.labelCaps.copyWith(color: c.secondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _brandNameController,
                decoration: const InputDecoration(hintText: 'Ex : Keïta Prestige'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Couleur d\'accent', style: AppTextStyles.labelCaps.copyWith(color: c.secondary)),
              const SizedBox(height: 8),
              Row(
                children: _palette(c).map((color) {
                  final isSelected = color.toARGB32() == _accentColor.toARGB32();
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _accentColor = color),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: c.onSurface, width: 2) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PreviewCard(brandName: _brandNameController, accentColor: _accentColor),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.brandName, required this.accentColor});
  final TextEditingController brandName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: brandName,
      builder: (context, _) {
        final c = context.colors;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Text(
              brandName.text.isEmpty ? 'StyleConnect' : brandName.text,
              style: AppTextStyles.titleMd.copyWith(color: accentColor, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text('Facture', style: AppTextStyles.bodySm.copyWith(color: accentColor)),
          ]),
        );
      },
    );
  }
}
