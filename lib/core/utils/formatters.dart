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

  /// Jours calendaires entre [from] (aujourd'hui par défaut) et [date].
  ///
  /// 0 = aujourd'hui, 1 = demain, négatif = date passée. On compare des
  /// JOURS et non des durées : un abonnement qui expire demain à 09 h compte
  /// pour « 1 jour », alors que `difference().inDays` renvoyait 0 tant qu'il
  /// restait moins de 24 h — et affichait donc « 0 j » (voire « 11 j » pour
  /// une échéance à 12 jours) dans la fiche 360 et les listes d'abonnements.
  static int daysUntil(DateTime date, {DateTime? from}) {
    final now = from ?? DateTime.now();
    // Dates « nues » en UTC : insensible aux heures et aux changements
    // d'heure (aucun risque de 23 h / 25 h arrondies à 0 jour).
    final today = DateTime.utc(now.year, now.month, now.day);
    final target = DateTime.utc(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

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
