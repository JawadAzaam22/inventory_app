import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatSyrianPounds(num value) {
    return NumberFormat.currency(
      locale: 'ar_SY',
      symbol: 'ليرة سورية',
      decimalDigits: 2,
    ).format(value);
  }

  static String formatDollars(num value) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    ).format(value);
  }
}