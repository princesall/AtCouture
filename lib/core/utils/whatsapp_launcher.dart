import 'package:url_launcher/url_launcher.dart';

/// Ouvre WhatsApp (app ou web) avec un message pré-rempli à destination du
/// numéro d'un client — utilisé pour les rappels de livraison et le partage
/// du numéro de suivi de commande, deux canaux bien plus utilisés par les
/// clients que les notifications in-app.
abstract final class WhatsAppLauncher {
  /// Indicatif appliqué automatiquement aux numéros saisis en local. Les
  /// numéros maliens sont très majoritairement saisis sans indicatif
  /// (« 70 00 00 00 ») : dans ce cas, le lien wa.me partait sur un numéro
  /// inexistant (wa.me/70000000) et WhatsApp ne s'ouvrait jamais.
  static const String defaultCountryCode = '223';

  /// Retourne `false` si aucune application ne peut ouvrir le lien
  /// (permet à l'appelant d'afficher un message d'erreur adapté).
  static Future<bool> sendMessage({
    required String phone,
    required String message,
  }) async {
    final digits = normalizePhone(phone);
    if (digits.isEmpty) return false;

    final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Ne conserve que les chiffres, retire le préfixe international « 00 » et
  /// ajoute l'indicatif par défaut si le numéro a été saisi en local.
  ///
  /// Heuristique : un numéro malien local fait 8 chiffres (9 au maximum), un
  /// numéro déjà international en fait 11 ou plus avec l'indicatif. On ne
  /// préfixe donc QUE les numéros courts — un numéro saisi en « +223 70… »
  /// reste inchangé.
  static String normalizePhone(String phone) {
    final trimmed = phone.trim();
    final hasExplicitCountryCode = trimmed.startsWith('+') || trimmed.startsWith('00');

    var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('00')) digits = digits.substring(2);

    if (!hasExplicitCountryCode && digits.length <= 9) {
      digits = '$defaultCountryCode$digits';
    }
    return digits;
  }
}
