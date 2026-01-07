import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class InvestmentSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();
    final profit = provider.totalProfit;
    final isProfit = profit >= 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tổng đầu tư",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              provider.totalInvested.toStringAsFixed(0),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              "${isProfit ? "Lãi" : "Lỗ"}: ${profit.toStringAsFixed(0)} "
              "(${provider.totalProfitPercent.toStringAsFixed(2)}%)",
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
