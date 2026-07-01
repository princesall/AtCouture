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
}
