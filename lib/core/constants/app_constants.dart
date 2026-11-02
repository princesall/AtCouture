abstract final class AppConstants {
  static const String appName = 'StyleConnect';
  static const String appTagline = 'L\'art de la couture, digitalisé';
  static const String currency = 'FCFA';

  /// URL publique de la console d'administration (site Firebase Hosting
  /// séparé de l'application mobile).
  static const String adminConsoleUrl = 'https://styleconnect-admin.web.app';

  /// Version de repli si package_info_plus n'est pas disponible (tests,
  /// navigateur sans version.json). Doit rester alignée sur pubspec.yaml.
  static const String appVersion = '1.1.0+2';

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
