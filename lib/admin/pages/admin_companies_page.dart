import 'package:flutter/material.dart';

import '../../data/admin_demo_data.dart';
import '../screens/admin_companies_screen.dart';
import '../widgets/admin_kit.dart';

/// Destination « Entreprises » de la console : la vue hiérarchie existante
/// est conservée telle quelle (lecture seule), mais intégrée dans le chrome
/// desktop et rafraîchie par le même notifier que le reste de l'admin.
class AdminCompaniesPage extends StatelessWidget {
  const AdminCompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1400 ? 44.0 : (width >= 900 ? 32.0 : 18.0);

    return ValueListenableBuilder<int>(
      valueListenable: AdminDemoData.revision,
      builder: (context, _, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 0),
            child: AdminPageHeader(
              title: 'Entreprises',
              subtitle:
                  '${AdminDemoData.companies.length} compte${AdminDemoData.companies.length > 1 ? 's' : ''} plan Entreprise · structure des ateliers en lecture seule',
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: const AdminCompaniesScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
