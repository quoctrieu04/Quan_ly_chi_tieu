// lib/core/money/money_settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'money_settings.dart';

class MoneySettingsService {
  static const _key = 'money_settings_v1';

  Future<MoneySettings> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return MoneySettings.vnd;

    try {
      var s = MoneySettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      // 🔧 Migration: ép chuẩn VND luôn là 0 chữ số thập phân
      if (s.currencyCode.toUpperCase() == 'VND' && s.decimalDigits != 0) {
        s = s.copyWith(decimalDigits: 0);
        // ghi lại để sửa cache cũ
        await sp.setString(_key, jsonEncode(s.toJson()));
      }
      return s;
    } catch (_) {
      return MoneySettings.vnd;
    }
  }

  Future<void> save(MoneySettings s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(s.toJson()));
  }
}
