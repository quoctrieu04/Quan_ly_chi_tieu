import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/pages/investment_detail_page.dart';

class InvestmentItemTile extends StatelessWidget {
  final Investment investment;

  const InvestmentItemTile({
    super.key,
    required this.investment,
  });

  @override
  Widget build(BuildContext context) {
    // Khai báo moneyFmt để định dạng tiền
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    final profit = investment.profitLoss;

    return GestureDetector(
      onTap: () {
        // Khi người dùng bấm vào một khoản đầu tư, điều hướng đến trang chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvestmentDetailPage(investment: investment),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(
            investment.type == 'bank'
                ? Icons.account_balance
                : Icons.trending_up,
          ),
          title: Text(investment.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (investment.bankName != null && investment.bankName!.isNotEmpty)
                Text(
                  investment.bankName!,
                  style: const TextStyle(fontSize: 13),
                ),
              const SizedBox(height: 4),
              Text(
                'Vốn: ${moneyFmt.format(investment.totalInvested)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Hiển thị lãi hoặc thông báo nếu không có lãi
              Text(
                profit == 0
                    ? 'Chưa tính lãi' // Hiển thị thông báo nếu không có lãi
                    : moneyFmt.format(profit),
                style: TextStyle(
                  color: profit >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Hiển thị phần trăm lãi
              Text(
                profit == 0
                    ? '0%' // Nếu không có lãi, hiển thị 0%
                    : '${investment.profitPercent.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
