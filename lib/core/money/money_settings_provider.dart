// lib/core/money/money_settings_provider.dart
import 'package:flutter/foundation.dart';
import 'money_settings.dart';
import 'money_settings_service.dart';

class MoneySettingsProvider extends ChangeNotifier {
  final MoneySettingsService _svc;
  MoneySettingsProvider(this._svc);

  MoneySettings _settings = MoneySettings.vnd;
  MoneySettings get settings => _settings;

  MoneySettings _normalize(MoneySettings s) {
    if (s.currencyCode.toUpperCase() == 'VND') {
      return s.copyWith(
        decimalDigits: 0,
        symbol: s.symbol.isEmpty ? 'đ' : s.symbol,
        symbolPosition: CurrencySymbolPosition.after,
      );
    }
    if (s.currencyCode.toUpperCase() == 'USD') {
      return s.copyWith(decimalDigits: 2, symbol: s.symbol.isEmpty ? '\$' : s.symbol);
    }
    return s;
  }

  Future<void> init() async {
    final loaded = await _svc.load();
    _settings = _normalize(loaded);
    if (loaded.decimalDigits != _settings.decimalDigits ||
        loaded.symbol != _settings.symbol ||
        loaded.symbolPosition != _settings.symbolPosition) {
      await _svc.save(_settings); // ghi đè cache cũ
    }
    notifyListeners();
  }

  Future<void> update(MoneySettings s) async {
    final normalized = _normalize(s);
    _settings = normalized;
    notifyListeners();
    await _svc.save(normalized);
  }
}
