import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';

class MonthSummaryCard extends StatelessWidget {
  final num totalIncome;
  final num totalExpense;
  final bool hideBalance;

  const MonthSummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.hideBalance,
  });

  @override
  Widget build(BuildContext context) {
    final moneySettings =
        context.watch<MoneySettingsProvider>().settings;

    String fmt(num v) =>
        hideBalance ? '•••' : MoneyFormatter(moneySettings).format(v);

    return Row(
      children: [
        Expanded(
          child: _SummaryBox(
            title: 'Tổng thu',
            value: fmt(totalIncome),
            color: const Color(0xFF2EC4B6),
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryBox(
            title: 'Tổng chi',
            value: fmt(totalExpense),
            color: const Color(0xFFF87171),
            icon: Icons.arrow_upward_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(.25),
            color.withOpacity(.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withOpacity(.3),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
