import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';
import 'package:chitieu/core/date/year_month_provider.dart';

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
    final ym = context.watch<YearMonthProvider>().ym;
    
    // Bạn có thể tính toán phần trăm thực tế dựa vào totalSaved sau.
    // Tạm thời fix cứng hiển thị như thiết kế hoặc 0%.
    final String percentText = totalSaved > 0 ? '10%' : '0%';
    final double percentVal = totalSaved > 0 ? 0.1 : 0.0;
    
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
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
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: percentVal,
                  strokeWidth: 6,
                  backgroundColor: cs.outlineVariant.withOpacity(0.3),
                  color: const Color(0xFF1B8756), // Green color matching
                ),
              ),
              const Icon(
                Icons.adjust_rounded,
                color: Color(0xFF1B8756),
                size: 28,
              ),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tháng ${ym.month.toString().padLeft(2, '0')} / ${ym.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            percentText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
