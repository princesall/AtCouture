import 'package:flutter/material.dart';

/// Personnalisation d'un compte Entreprise appliquée aux documents générés
/// (PDF de commande, devis). Plan Entreprise uniquement (hasCustomization).
class CompanyBranding {
  const CompanyBranding({this.brandName, this.accentColor});
  final String? brandName;
  final Color? accentColor;
}

/// Stocke en mémoire la personnalisation par entreprise (indexée par companyId,
/// c-à-d AppUser.id du Chef d'Entreprise — voir CompanyService.createCompanyForNewOwner).
class CompanyCustomizationService {
  CompanyCustomizationService._();
  static final CompanyCustomizationService instance = CompanyCustomizationService._();

  final Map<String, CompanyBranding> _branding = {};

  CompanyBranding brandingFor(String? companyId) =>
      (companyId == null ? null : _branding[companyId]) ?? const CompanyBranding();

  Future<void> setBranding(String companyId, CompanyBranding branding) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _branding[companyId] = branding;
  }
}
