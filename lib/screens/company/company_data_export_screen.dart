import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

/// Export des données de l'Entreprise (clients, commandes, couturiers) au
/// format JSON, partageable via n'importe quelle app (email, stockage
/// cloud...). Plan Entreprise uniquement (permissions.hasApiExport).
class CompanyDataExportScreen extends StatelessWidget {
  const CompanyDataExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final companyId = user.companyId ?? user.id;
    final ateliers = CompanyService.instance.ateliersOfCompany(companyId);
    final clients = CompanyService.instance.allClientsOfCompany(companyId);
    final orders = CompanyService.instance.allOrdersOfCompany(companyId);
    final tailors = CompanyService.instance.allTailorsOfCompany(companyId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export de données'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exportez l\'intégralité des données de votre entreprise au format JSON, '
                'pour les archiver ou les intégrer à un autre outil.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CountRow(label: 'Ateliers', count: ateliers.length),
              _CountRow(label: 'Couturiers', count: tailors.length),
              _CountRow(label: 'Clients', count: clients.length),
              _CountRow(label: 'Commandes', count: orders.length),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _export(context, ateliers: ateliers, clients: clients, orders: orders, tailors: tailors),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Exporter au format JSON'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context, {
    required List<dynamic> ateliers,
    required List<dynamic> clients,
    required List<dynamic> orders,
    required List<dynamic> tailors,
  }) async {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'ateliers': ateliers.map((a) => {'id': a.id, 'name': a.name}).toList(),
      'tailors': tailors.map((t) => {'id': t.id, 'fullName': t.fullName, 'atelierId': t.atelierId}).toList(),
      'clients': clients.map((c) => c.toMap()..['id'] = c.id).toList(),
      'orders': orders.map((o) => o.toMap()..['id'] = o.id).toList(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await SharePlus.instance.share(
      ShareParams(text: json, subject: 'Export StyleConnect ${DateTime.now().toIso8601String()}'),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(Icons.circle, size: 6, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySm),
        const Spacer(),
        Text('$count', style: AppTextStyles.titleSm.copyWith(color: AppColors.primary)),
      ]),
    );
  }
}
