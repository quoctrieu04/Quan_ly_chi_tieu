import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/investment/investment_provider.dart';

class InvestmentSummaryCard extends StatelessWidget {
  const InvestmentSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();
    final profit = provider.totalProfit;
    final isProfit = profit >= 0;

    final moneyFmt = NumberFormat('#,###', 'vi_VN');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng đầu tư',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              moneyFmt.format(provider.totalInvested),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              '${isProfit ? "Lãi" : "Lỗ"}: '
              '${moneyFmt.format(profit)} '
              '(${provider.totalProfitPercent.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: isProfit ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
