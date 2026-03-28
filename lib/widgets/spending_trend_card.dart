import 'package:flutter/material.dart';
import 'models/monthly_cashflow.dart';

class SpendingTrendCard extends StatelessWidget {
  final List<MonthlyCashFlow> data;
  const SpendingTrendCard({super.key, required this.data});

  num _maxValue() {
    return data
        .map((e) => e.income > e.expense ? e.income : e.expense)
        .fold<num>(0, (a, b) => a > b ? a : b);
  }

  num _changePercent() {
    if (data.length < 2) return 0;

    final prev = data[data.length - 2].expense.toDouble().abs();
    final curr = data.last.expense.toDouble().abs();

    if (prev == 0 && curr == 0) return 0;

    final base = prev > curr ? prev : curr;
    if (base == 0) return 0;

    final percent = ((curr - prev) / base) * 100;
    return percent.clamp(-100.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = _maxValue();
    final percent = _changePercent();
    final isDown = percent < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Biến động thu/chi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Icon(
                isDown ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDown ? Colors.green : Colors.red,
                size: 18,
              ),
              Text(
                '${percent.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDown ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.map((m) {
                final double incomeH =
                    maxVal == 0 ? 0 : ((m.income / maxVal) * 100).toDouble();

                final double expenseH =
                    maxVal == 0 ? 0 : ((m.expense / maxVal) * 100).toDouble();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 14,
                          height: incomeH,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B8CFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          width: 14,
                          height: expenseH,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FE3A1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('T${m.month}', style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _Legend(color: Color(0xFF9B8CFF), label: 'Thu'),
              SizedBox(width: 12),
              _Legend(color: Color(0xFF6FE3A1), label: 'Chi'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}