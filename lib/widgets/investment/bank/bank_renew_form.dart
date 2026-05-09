import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/utils/safe_ui.dart';

class BankRenewForm extends StatefulWidget {
  final Investment baseInvestment;

  const BankRenewForm({
    super.key,
    required this.baseInvestment,
  });

  @override
  State<BankRenewForm> createState() => _BankRenewFormState();
}

class _BankRenewFormState extends State<BankRenewForm> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.baseInvestment;
    final moneyFmt = NumberFormat('#,###', 'vi_VN');

    final totalAmount = inv.totalInvested + inv.profitLoss;
    

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gia hạn tiền gửi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          /// ===== THÔNG TIN =====
          ListTile(
            title: const Text('Khoản hiện tại'),
            subtitle: Text(inv.name),
          ),
          ListTile(
            title: const Text('Số tiền gia hạn'),
            subtitle: Text(
              '${moneyFmt.format(totalAmount)} VND',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Kỳ hạn'),
            subtitle: Text('${inv.termMonths ?? 0} tháng'),
          ),
          ListTile(
            title: const Text('Lãi suất'),
            subtitle:
                Text('${inv.interestRate?.toStringAsFixed(2) ?? 0}% / năm'),
          ),

          const SizedBox(height: 12),

          const Text(
            'Toàn bộ vốn và lãi sẽ được gia hạn sang kỳ mới.\n'
            'Khoản cũ sẽ được tất toán và ẩn khỏi danh sách.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          /// ===== ACTION =====
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Huỷ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _confirmRenew,
                  child: const Text('Xác nhận gia hạn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRenew() async {
    setState(() => _busy = true);

    try {
      await context
          .read<InvestmentProvider>()
          .renewBankInvestment(widget.baseInvestment.id!);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
