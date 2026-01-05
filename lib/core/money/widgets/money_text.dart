// lib/core/money/widgets/money_text.dart
import 'package:flutter/material.dart';
import '../money_formatter.dart';
import '../money_settings_provider.dart';
import 'package:provider/provider.dart';

class MoneyText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final TextAlign? textAlign;
  const MoneyText(this.value, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<MoneySettingsProvider>().settings;
    final str = MoneyFormatter(settings).format(value);
    return Text(str, style: style, textAlign: textAlign);
  }
}
