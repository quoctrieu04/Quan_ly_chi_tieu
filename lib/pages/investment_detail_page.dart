import 'package:chitieu/api/bankaccount/bank_account_model.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/widgets/investment/bank/bank_renew_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

    final bool isClosed = investment.closedAt != null;
    final bool canWithdraw = investment.type == 'bank' &&
        !isClosed &&
        investment.totalInvested > 0 &&
        maturityDate != null &&
        !DateTime.now().isBefore(_dateOnly(maturityDate));
    final bool canWithdrawInterestAndRenew = canWithdraw && profit > 0;

    String moneyText(num value) => moneyFmt.format(value).replaceAll(',', '.');

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
          if (canWithdraw)
            Column(
              children: [
                if (canWithdrawInterestAndRenew)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : _openWithdrawInterestAndRenewSheet,
                      icon: const Icon(Icons.sync_alt),
                      label: const Text('Rút lãi & gia hạn gốc'),
                    ),
                  ),
                if (canWithdrawInterestAndRenew) const SizedBox(height: 12),
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

  Widget _accountDropdown(
    List<BankAccount> accounts,
    int? selectedId,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      value: selectedId,
      decoration: const InputDecoration(labelText: 'Tài khoản nhận tiền'),
      items: accounts
          .where((account) => !account.isDeleted)
          .map(
            (account) => DropdownMenuItem<int>(
              value: account.id,
              child: Text(
                account.bankname != null && account.bankname!.isNotEmpty
                    ? '${account.name} • ${account.bankname}'
                    : account.name,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

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
                  (value) => setModalState(() {
                    receiveAccountId = value;
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: receiveAccountId == null || _busy
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _busy = true);

                            try {
                              await context.read<InvestmentProvider>().withdrawBank(
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

  void _openWithdrawInterestAndRenewSheet() {
    final accounts = context.read<BankAccountProvider>().items;
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    int? receiveAccountId;

    String moneyText(num value) => moneyFmt.format(value).replaceAll(',', '.');

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
                  'Rút lãi và gia hạn gốc',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lãi chuyển về tài khoản'),
                  subtitle: Text(
                    '${moneyText(investment.profitLoss)} VND',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Số gốc tiếp tục gia hạn'),
                  subtitle: Text(
                    '${moneyText(investment.totalInvested)} VND',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (investment.termMonths != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kỳ hạn mới'),
                    subtitle: Text('${investment.termMonths} tháng'),
                  ),
                _accountDropdown(
                  accounts,
                  receiveAccountId,
                  (value) => setModalState(() {
                    receiveAccountId = value;
                  }),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lãi hiện tại sẽ được rút về tài khoản nhận tiền, '
                  'phần gốc sẽ được gia hạn sang kỳ mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: receiveAccountId == null || _busy
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _busy = true);

                            try {
                              await context.read<InvestmentProvider>().withdrawBank(
                                    investment.id!,
                                    receiveAccountId!,
                                    withdrawType:
                                        WithdrawType.interestAndRenew,
                                  );

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Rút lãi và gia hạn gốc thành công',
                                  ),
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
                    child: const Text('Xác nhận rút lãi và gia hạn gốc'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
      await context.read<InvestmentProvider>().fetch();
      Navigator.pop(context, true);
    }
  }

  DateTime? _maturityDate(DateTime? start, int? termMonths) {
    if (start == null || termMonths == null) return null;
    return DateTime(start.year, start.month + termMonths, start.day);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}