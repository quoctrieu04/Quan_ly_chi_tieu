// lib/core/money/money_formatter.dart
import 'package:intl/intl.dart';
import 'money_settings.dart';

class MoneyFormatter {
  final MoneySettings settings;
  MoneyFormatter(this.settings);

  String format(num value) {
    // Dùng NumberFormat nhưng gán separators theo settings
    final pattern = '#,##0' + (settings.decimalDigits > 0 ? '.' + '0' * settings.decimalDigits : '');
    final f = NumberFormat(pattern)
      ..minimumFractionDigits = settings.decimalDigits
      ..maximumFractionDigits = settings.decimalDigits;

    var numeric = f.format(value);

    // Thay dấu theo settings (Intl mặc định dùng locale en_US -> , .)
    numeric = numeric
        .replaceAll(',', 'TMP_COMMA')
        .replaceAll('.', 'TMP_DOT')
        .replaceAll('TMP_COMMA', settings.thousandSeparator)
        .replaceAll('TMP_DOT', settings.decimalSeparator);

    return settings.symbolPosition == CurrencySymbolPosition.before
      ? '${settings.symbol}$numeric'
      : '$numeric${settings.symbol}';
  }
}
