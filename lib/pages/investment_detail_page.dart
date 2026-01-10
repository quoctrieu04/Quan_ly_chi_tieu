import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';

class InvestmentDetailPage extends StatelessWidget {
  final Investment investment;

  const InvestmentDetailPage({
    super.key,
    required this.investment,
  });

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');

    final profit = investment.profitLoss;
    final totalAmount = investment.totalInvested + profit;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết ${investment.name}'),
        actions: [
          /// ===== NÚT XÓA =====
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard('Vốn đầu tư',
              '${moneyFmt.format(investment.totalInvested)} VND'),
          _infoCard('Lãi suất',
              '${investment.interestRate?.toStringAsFixed(2) ?? 0}%'),
          _infoCard(
              'Kỳ hạn', '${investment.termMonths ?? 0} tháng'),
          _infoCard(
              'Ngày gửi',
              investment.startDate != null
                  ? dateFmt.format(investment.startDate!)
                  : '—'),
          _infoCard(
            'Lãi hiện tại',
            '${moneyFmt.format(profit)} VND',
            valueColor: profit >= 0 ? Colors.green : Colors.red,
          ),
          _infoCard(
            'Tổng (Vốn + Lãi)',
            '${moneyFmt.format(totalAmount)} VND',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ),
    );
  }

  /// ======================
  /// XÁC NHẬN + XÓA
  /// ======================
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa đầu tư'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa khoản đầu tư này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final prov = context.read<InvestmentProvider>();
              final ok = await prov.remove(investment.id!);


              if (ok && context.mounted) {
                Navigator.pop(context); // quay về list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa khoản đầu tư')),
                );
              }
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
