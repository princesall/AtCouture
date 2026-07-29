import '../../models/order.dart';
import 'formatters.dart';

/// Textes envoyés au client final (WhatsApp/SMS) au sujet d'une commande —
/// centralisés ici pour garder un ton cohérent partout où ils sont déclenchés
/// (création de commande, rappels, détail de commande).
abstract final class OrderMessages {
  static String tracking(Order order) =>
      'Bonjour ${order.clientName}, votre commande chez ${order.atelierName} a bien été enregistrée. '
      'Suivez son avancement à tout moment sans compte via "Suivre une commande" dans l\'app, '
      'avec le numéro : ${order.id}.';

  static String reminder(Order order) {
    final due = order.dueDate != null
        ? Formatters.date.format(order.dueDate!)
        : 'très bientôt';
    return 'Bonjour ${order.clientName}, petit rappel : votre commande '
        '(${order.description ?? 'vêtement'}) chez ${order.atelierName} '
        'est prévue pour le $due. Merci de votre confiance !';
  }
}
