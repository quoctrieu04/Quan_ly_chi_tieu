import 'package:chitieu/api/investment/investment_model.dart';
import 'package:flutter/material.dart';


class InvestmentItemTile extends StatelessWidget {
  final Investment investment;

  const InvestmentItemTile({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final profit = investment.profitLoss;
    final isProfit = profit >= 0;

    return Card(
      child: ListTile(
        leading: Icon(
          investment.type == 'bank'
              ? Icons.account_balance
              : Icons.trending_up,
        ),
        title: Text(investment.name),
        subtitle: Text(
          "Vốn: ${investment.totalInvested.toStringAsFixed(0)}",
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              profit.toStringAsFixed(0),
              style: TextStyle(
                color: isProfit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${investment.profitPercent.toStringAsFixed(2)}%",
              style: TextStyle(
                fontSize: 12,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
