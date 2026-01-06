import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';

class SavingGoalCard extends StatelessWidget {
  final num totalSaved;
  final VoidCallback onCreate;

  const SavingGoalCard({
    super.key,
    required this.totalSaved,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final moneySettings =
        context.watch<MoneySettingsProvider>().settings;

    final text =
        MoneyFormatter(moneySettings).format(totalSaved);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Colors.black12,
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: 0.6,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                ),
              ),
              const Icon(Icons.savings_rounded,
                  color: Colors.green),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mục tiêu tiết kiệm',
                  style: TextStyle(
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCreate,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
          )
        ],
      ),
    );
  }
}
