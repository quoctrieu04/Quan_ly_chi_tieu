// lib/pages/setting/money_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/money/money_settings.dart';
import '../../core/money/money_settings_provider.dart';
import '../../core/money/money_formatter.dart';
import 'package:chitieu/l10n/app_localizations.dart';

class MoneySettingsPage extends StatelessWidget {
  const MoneySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final prov = context.watch<MoneySettingsProvider>();
    final s = prov.settings;

    String sample(MoneySettings x) => MoneyFormatter(x).format(1234567.89);

    return Scaffold(
      appBar: AppBar(title: Text(t.budgetSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: t.currency,
            child: ListTile(
              title: Text(_currencyName(s)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final pick = await _pickCurrency(context, s);
                if (pick != null) prov.update(pick);
              },
            ),
          ),
          _Section(
            title: t.numberFormat,
            child: ListTile(
              title: Text(sample(s)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final pick = await _pickNumberFormat(context, s);
                if (pick != null) prov.update(pick);
              },
            ),
          ),
          _Section(
            title: t.currencySymbolPosition,
            child: ListTile(
              title: Text(
                s.symbolPosition == CurrencySymbolPosition.after
                    ? t.symbolAfter
                    : t.symbolBefore,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final pick = await _pickSymbolPosition(context, s);
                if (pick != null) prov.update(pick);
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  String _currencyName(MoneySettings s) =>
      '${s.currencyCode} - ${s.currencyCode == "VND" ? "Vietnamese Dong" : s.currencyCode} (${s.symbol})';

  Future<MoneySettings?> _pickCurrency(BuildContext ctx, MoneySettings s) async {
    final opts = [MoneySettings.vnd, MoneySettings.usd];
    return showModalBottomSheet<MoneySettings>(
      context: ctx,
      builder: (_) => SafeArea(
        child: ListView(
          children: opts
              .map((o) => ListTile(
                    title: Text(_currencyName(o)),
                    trailing: o.currencyCode == s.currencyCode
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.pop(ctx, o),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<MoneySettings?> _pickNumberFormat(BuildContext ctx, MoneySettings s) {
    final vnd = s.currencyCode == 'VND';
    final variants = [
      s.copyWith(
          thousandSeparator: '.',
          decimalSeparator: ',',
          decimalDigits: vnd ? 0 : 2),
      s.copyWith(
          thousandSeparator: ',',
          decimalSeparator: '.',
          decimalDigits: vnd ? 0 : 2),
      s.copyWith(
          thousandSeparator: ' ',
          decimalSeparator: ',',
          decimalDigits: vnd ? 0 : 2),
    ];
    return showModalBottomSheet<MoneySettings>(
      context: ctx,
      builder: (_) => SafeArea(
        child: ListView(
          children: variants
              .map((o) => ListTile(
                    title: Text(MoneyFormatter(o).format(1234567.89)),
                    trailing: (o.thousandSeparator == s.thousandSeparator &&
                            o.decimalSeparator == s.decimalSeparator)
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.pop(ctx, o),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<MoneySettings?> _pickSymbolPosition(
      BuildContext ctx, MoneySettings s) {
    final after = s.copyWith(symbolPosition: CurrencySymbolPosition.after);
    final before = s.copyWith(symbolPosition: CurrencySymbolPosition.before);
    final t = AppLocalizations.of(ctx)!;

    return showModalBottomSheet<MoneySettings>(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(t.symbolBefore),
              subtitle: Text(MoneyFormatter(before).format(1234567.89)),
              trailing: s.symbolPosition == CurrencySymbolPosition.before
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(ctx, before),
            ),
            ListTile(
              title: Text(t.symbolAfter),
              subtitle: Text(MoneyFormatter(after).format(1234567.89)),
              trailing: s.symbolPosition == CurrencySymbolPosition.after
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(ctx, after),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              child,
            ]),
      ),
    );
  }
}
