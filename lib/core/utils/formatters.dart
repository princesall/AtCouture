import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

abstract final class Formatters {
  static final NumberFormat currency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: AppConstants.currency,
    decimalDigits: 0,
  );

  static final DateFormat date = DateFormat('dd MMM yyyy', 'fr_FR');
  static final DateFormat dateTime = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');
  static final DateFormat time = DateFormat('HH:mm', 'fr_FR');
  static final DateFormat monthYear = DateFormat('MMMM yyyy', 'fr_FR');

  static String formatCurrency(int amount) => currency.format(amount);

  /// Version courte pour les cartes de statistique, où un montant complet
  /// (« 1 250 000 FCFA ») ne tient pas dans la typo d'affichage.
  /// Ex. 1 250 000 → « 1,3 M FCFA », 850 000 → « 850 k FCFA ».
  static String compactCurrency(int amount) {
    final abs = amount.abs();
    if (abs >= 1000000) {
      final millions = amount / 1000000;
      final text = millions.toStringAsFixed(abs >= 10000000 ? 0 : 1);
      return '${text.replaceAll('.', ',')} M ${AppConstants.currency}';
    }
    if (abs >= 1000) {
      final thousands = amount / 1000;
      final text = thousands.toStringAsFixed(abs >= 100000 ? 0 : 1);
      return '${text.replaceAll('.', ',')} k ${AppConstants.currency}';
    }
    return formatCurrency(amount);
  }
}
