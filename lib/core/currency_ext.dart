// lib/core/currency_ext.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';

extension CurrencyX on num {
  String formatCurrency(BuildContext context, {bool withSign = false}) {
    final settings = context.read<MoneySettingsProvider>().settings;
    final s = MoneyFormatter(settings).format(this.abs());
    if (!withSign) return s;
    final sign = this >= 0 ? '+' : '-';
    return '$sign$s';
  }
}
