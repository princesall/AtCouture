import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/data/admin_demo_data.dart';
import 'package:styleconnect/models/app_user.dart';
import 'package:styleconnect/models/platform_health.dart';
import 'package:styleconnect/models/user_role.dart';
import 'package:styleconnect/services/auth_service.dart';
import 'package:styleconnect/services/feature_usage_service.dart';
import 'package:styleconnect/services/platform_health_service.dart';
import 'package:styleconnect/services/platform_telemetry_service.dart';

void main() {
  test('le rapport plateforme agrège comptes, qualité, usage et erreurs', () async {
    AuthService.seedDebugAdmin();

    final now = DateTime.now();
    await AdminDemoData.addStylist(
      AppUser(
        id: 'health_test_1',
        email: 'health-test@demo.ml',
        fullName: 'Compte Santé',
        phone: '',
        role: UserRole.stylist,
        atelierName: 'Atelier Santé',
        createdAt: now.subtract(const Duration(days: 120)),
      ),
    );

    FeatureUsageService.instance.clearLocalEvents();
    FeatureUsageService.instance.track(FeatureKeys.ordersCreate);
    FeatureUsageService.instance.track(FeatureKeys.ordersCreate);
    FeatureUsageService.instance.track(FeatureKeys.pdfExport);

    PlatformTelemetryService.instance.recordError(
      Exception('erreur de test santé'),
      StackTrace.current,
      context: 'platform_health_test',
    );

    final snapshot =
        await PlatformHealthService.instance.loadSnapshot(force: true);

    expect(snapshot.users.total, greaterThanOrEqualTo(2));
    expect(snapshot.users.count(UserRole.admin), 1);
    expect(snapshot.users.count(UserRole.stylist), greaterThanOrEqualTo(1));

    expect(
      snapshot.quality.count(QualityIssueType.missingPhone),
      greaterThanOrEqualTo(1),
    );
    expect(
      snapshot.quality.count(QualityIssueType.inactive90),
      greaterThanOrEqualTo(1),
    );

    final orderCreate = snapshot.usage.stats
        .firstWhere((stat) => stat.feature == FeatureKeys.ordersCreate);
    expect(orderCreate.events, 2);
    expect(snapshot.usage.totalEvents, 3);

    expect(
      snapshot.errors.any(
        (error) => error.message.contains('erreur de test santé'),
      ),
      isTrue,
    );
  });
}
