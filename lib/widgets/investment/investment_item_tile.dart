import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/pages/investment_detail_page.dart';

class InvestmentItemTile extends StatelessWidget {
  final Investment investment;

  const InvestmentItemTile({
    super.key,
    required this.investment,
  });

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    final profit = investment.profitLoss;

    final bool isClosed = investment.closedAt != null;

    return Opacity(
      opacity: isClosed ? 0.45 : 1,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(
            investment.type == 'bank'
                ? Icons.account_balance
                : Icons.trending_up,
            color: isClosed ? Colors.grey : null,
          ),

          title: Text(
            investment.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isClosed ? Colors.grey : null,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (investment.bankName != null &&
                  investment.bankName!.isNotEmpty)
                Text(
                  investment.bankName!,
                  style: const TextStyle(fontSize: 13),
                ),
              const SizedBox(height: 4),
              Text(
                'Vốn: ${moneyFmt.format(investment.totalInvested)}',
                style: const TextStyle(fontSize: 13),
              ),

              if (isClosed)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Đã tất toán',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          trailing: _buildTrailing(context, profit, moneyFmt, isClosed),

          onTap: isClosed
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InvestmentDetailPage(investment: investment),
                    ),
                  );
                },
        ),
      ),
    );
  }

  // ==========================
  // TRAILING (LÃI / XÓA)
  // ==========================
  Widget _buildTrailing(
    BuildContext context,
    num profit,
    NumberFormat moneyFmt,
    bool isClosed,
  ) {
    if (isClosed) {
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _confirmDelete(context),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          profit == 0 ? 'Chưa tính lãi' : moneyFmt.format(profit),
          style: TextStyle(
            color: profit >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          profit == 0
              ? '0%'
              : '${investment.profitPercent.toStringAsFixed(2)}%',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // ==========================
  // CONFIRM DELETE
  // ==========================
  void _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa khoản đầu tư'),
        content: const Text(
          'Khoản đầu tư này đã tất toán.\n'
          'Bạn có chắc muốn xóa khỏi danh sách?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<InvestmentProvider>().remove(investment.id!);
      await context.read<InvestmentProvider>().fetch();
    }
  }
}
