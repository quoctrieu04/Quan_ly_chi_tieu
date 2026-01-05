// lib/core/money/money_settings.dart
enum CurrencySymbolPosition { before, after }

class MoneySettings {
  final String currencyCode; // "VND", "USD"...
  final String symbol; // "đ", "$", "₫"
  final CurrencySymbolPosition symbolPosition;
  final int decimalDigits; // VND: 0, USD: 2
  final String thousandSeparator; // ".", ","
  final String decimalSeparator; // ",", "."
  // ví dụ "123.457đ" chỉ dùng cho demo trong UI settings
  const MoneySettings({
    required this.currencyCode,
    required this.symbol,
    required this.symbolPosition,
    required this.decimalDigits,
    required this.thousandSeparator,
    required this.decimalSeparator,
  });

  MoneySettings copyWith({
    String? currencyCode,
    String? symbol,
    CurrencySymbolPosition? symbolPosition,
    int? decimalDigits,
    String? thousandSeparator,
    String? decimalSeparator,
  }) =>
      MoneySettings(
        currencyCode: currencyCode ?? this.currencyCode,
        symbol: symbol ?? this.symbol,
        symbolPosition: symbolPosition ?? this.symbolPosition,
        decimalDigits: decimalDigits ?? this.decimalDigits,
        thousandSeparator: thousandSeparator ?? this.thousandSeparator,
        decimalSeparator: decimalSeparator ?? this.decimalSeparator,
      );

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        'symbol': symbol,
        'symbolPosition': symbolPosition.name,
        'decimalDigits': decimalDigits,
        'thousandSeparator': thousandSeparator,
        'decimalSeparator': decimalSeparator,
      };

  factory MoneySettings.fromJson(Map<String, dynamic> j) => MoneySettings(
        currencyCode: j['currencyCode'] as String,
        symbol: j['symbol'] as String,
        symbolPosition: CurrencySymbolPosition.values
            .firstWhere((e) => e.name == j['symbolPosition']),
        decimalDigits: j['decimalDigits'] as int,
        thousandSeparator: j['thousandSeparator'] as String,
        decimalSeparator: j['decimalSeparator'] as String,
      );

  static final vnd = MoneySettings(
    currencyCode: 'VND',
    symbol: 'đ',
    thousandSeparator: '.',
    decimalSeparator: ',',
    decimalDigits: 0, // 👈 phải là 0
    symbolPosition: CurrencySymbolPosition.after,
  );

  static const usd = MoneySettings(
    currencyCode: 'USD',
    symbol: '\$',
    symbolPosition: CurrencySymbolPosition.before,
    decimalDigits: 2,
    thousandSeparator: ',',
    decimalSeparator: '.',
  );
}
