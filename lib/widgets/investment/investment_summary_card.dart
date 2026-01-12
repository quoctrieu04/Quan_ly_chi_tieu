import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/investment/investment_provider.dart';

class InvestmentSummaryCard extends StatelessWidget {
  const InvestmentSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();

    final totalInvested = provider.totalInvested;
    final profit = provider.totalProfit;
    final percent = totalInvested == 0
        ? 0
        : provider.totalProfitPercent;

    final isProfit = profit >= 0;

    final moneyFmt = NumberFormat('#,###', 'vi_VN');

    String money(num v) =>
        '${moneyFmt.format(v).replaceAll(',', '.')} VND';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng đầu tư',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),

            /// Tổng vốn
            Text(
              money(totalInvested),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            /// Lãi / Lỗ
            Row(
              children: [
                Icon(
                  isProfit
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: isProfit ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${isProfit ? "Lãi" : "Lỗ"}: '
                  '${money(profit)} '
                  '(${percent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
