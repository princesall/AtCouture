import 'package:url_launcher/url_launcher.dart';

/// Ouvre WhatsApp (app ou web) avec un message pré-rempli à destination du
/// numéro d'un client — utilisé pour les rappels de livraison et le partage
/// du numéro de suivi de commande, deux canaux bien plus utilisés par les
/// clients que les notifications in-app.
abstract final class WhatsAppLauncher {
  /// Retourne `false` si aucune application ne peut ouvrir le lien
  /// (permet à l'appelant d'afficher un message d'erreur adapté).
  static Future<bool> sendMessage({
    required String phone,
    required String message,
  }) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;

    final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
