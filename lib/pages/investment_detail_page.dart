import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:chitieu/widgets/investment/bank/bank_renew_form.dart';
import 'package:chitieu/widgets/models/create_investment_mode.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_model.dart';

class InvestmentDetailPage extends StatefulWidget {
  final Investment investment;

  const InvestmentDetailPage({
    super.key,
    required this.investment,
  });

  @override
  State<InvestmentDetailPage> createState() => _InvestmentDetailPageState();
}

class _InvestmentDetailPageState extends State<InvestmentDetailPage> {
  late Investment investment;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    investment = widget.investment;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankAccountProvider>().fetchAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');

    final profit = investment.profitLoss;
    final totalAmount = investment.totalInvested + profit;

    final maturityDate =
        _maturityDate(investment.startDate, investment.termMonths);

    /// ✅ CHỐT NGHIỆP VỤ
    final bool isClosed = investment.closedAt != null;

    /// ✅ FIX QUAN TRỌNG: KHÔNG CHO RÚT NẾU ĐÃ TẤT TOÁN
    final bool canWithdraw = investment.type == 'bank' &&
        !isClosed &&
        investment.totalInvested > 0 &&
        maturityDate != null &&
        !DateTime.now().isBefore(_dateOnly(maturityDate));

    String moneyText(num v) => moneyFmt.format(v).replaceAll(',', '.');

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết ${investment.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(
            'Vốn đầu tư',
            '${moneyText(investment.totalInvested)} VND',
          ),

          if (investment.type == 'bank')
            _infoCard(
              'Lãi suất',
              '${investment.interestRate?.toStringAsFixed(2) ?? 0}%',
            ),

          if (investment.startDate != null)
            _infoCard(
              'Ngày bắt đầu',
              dateFmt.format(investment.startDate!),
            ),

          if (investment.type == 'bank')
            _infoCard(
              'Ngày đáo hạn',
              maturityDate != null ? dateFmt.format(maturityDate) : '—',
              valueColor: canWithdraw ? Colors.green : Colors.orange,
            ),

          if (isClosed)
            _infoCard(
              'Trạng thái',
              'Đã tất toán',
              valueColor: Colors.red,
              bold: true,
            ),

          _infoCard(
            'Lãi hiện tại',
            '${moneyText(profit)} VND',
            valueColor: profit >= 0 ? Colors.green : Colors.red,
          ),

          _infoCard(
            'Tổng giá trị',
            '${moneyText(totalAmount)} VND',
            bold: true,
          ),

          const SizedBox(height: 20),

          /// ✅ SAU TẤT TOÁN → KHÔNG HIỆN NÚT NÀO
          if (canWithdraw)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _openWithdrawSheet,
                    icon: const Icon(Icons.payments),
                    label: const Text('Rút toàn bộ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _openRenewDialog,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Gia hạn'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ======================
  // INFO CARD
  // ======================
  Widget _infoCard(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Card(
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

  // ======================
  // ACCOUNT DROPDOWN
  // ======================
  Widget _accountDropdown(
    List<BankAccount> accounts,
    int? selectedId,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      value: selectedId,
      decoration: const InputDecoration(labelText: 'Tài khoản nhận tiền'),
      items: accounts
          .where((a) => !a.isDeleted)
          .map(
            (a) => DropdownMenuItem<int>(
              value: a.id,
              child: Text(
                a.bankname != null && a.bankname!.isNotEmpty
                    ? '${a.name} • ${a.bankname}'
                    : a.name,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  // ======================
  // RÚT TOÀN BỘ
  // ======================
  void _openWithdrawSheet() {
    final accounts = context.read<BankAccountProvider>().items;
    int? receiveAccountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rút toàn bộ tiền gửi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _accountDropdown(
                  accounts,
                  receiveAccountId,
                  (v) => setModalState(() {
                    receiveAccountId = v;
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: receiveAccountId == null || _busy
                        ? null
                        : () async {
                            Navigator.pop(context);
                            setState(() => _busy = true);

                            try {
                              await context
                                  .read<InvestmentProvider>()
                                  .withdrawBank(
                                    investment.id!,
                                    receiveAccountId!,
                                    withdrawType: WithdrawType.all,
                                  );

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rút tiền thành công'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _busy = false);
                              }
                            }
                          },
                    child: const Text('Xác nhận rút toàn bộ'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======================
  // GIA HẠN
  // ======================
  void _openRenewDialog() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BankRenewForm(
        baseInvestment: investment,
      ),
    );

    if (created == true && mounted) {
      // chỉ cần fetch
      await context.read<InvestmentProvider>().fetch();

      // QUAY VỀ LIST
      Navigator.pop(context, true);
    }
  }

  // ======================
  // DATE HELPERS
  // ======================
  DateTime? _maturityDate(DateTime? start, int? termMonths) {
    if (start == null || termMonths == null) return null;
    return DateTime(start.year, start.month + termMonths, start.day);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
