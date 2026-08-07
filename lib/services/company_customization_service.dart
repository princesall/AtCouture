import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'firebase_service.dart';

/// Personnalisation d'un compte Entreprise appliquée aux documents générés
/// (PDF de commande, devis). Plan Entreprise uniquement (hasCustomization).
class CompanyBranding {
  const CompanyBranding({this.brandName, this.accentColor});
  final String? brandName;
  final Color? accentColor;
}

/// Personnalisation par entreprise (indexée par companyId, c-à-d AppUser.id
/// du Chef d'Entreprise — voir CompanyService.createCompanyForNewOwner),
/// persistée dans Firestore (collection companyBranding) pour survivre au
/// redémarrage de l'app — en mode démo (Firebase non connecté), reste en
/// mémoire comme avant.
class CompanyCustomizationService {
  CompanyCustomizationService._();
  static final CompanyCustomizationService instance = CompanyCustomizationService._();

  final Map<String, CompanyBranding> _demoBranding = {};

  Future<CompanyBranding> brandingFor(String? companyId) async {
    if (companyId == null) return const CompanyBranding();

    if (!FirebaseService.isAvailable) {
      return _demoBranding[companyId] ?? const CompanyBranding();
    }

    final doc = await FirebaseFirestore.instance.collection('companyBranding').doc(companyId).get();
    if (!doc.exists) return const CompanyBranding();

    final data = doc.data()!;
    final accentValue = data['accentColorValue'] as int?;
    return CompanyBranding(
      brandName: data['brandName'] as String?,
      accentColor: accentValue != null ? Color(accentValue) : null,
    );
  }

  Future<void> setBranding(String companyId, CompanyBranding branding) async {
    if (!FirebaseService.isAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _demoBranding[companyId] = branding;
      return;
    }

    await FirebaseFirestore.instance.collection('companyBranding').doc(companyId).set({
      'brandName': branding.brandName,
      'accentColorValue': branding.accentColor?.toARGB32(),
    });
  }
}
