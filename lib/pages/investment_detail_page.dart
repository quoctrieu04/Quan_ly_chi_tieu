import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_model.dart';

/// ===============================
/// FORMAT TIỀN: 1.000.000
/// ===============================
class _VnMoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll('.', '').replaceAll(',', '').trim();
    if (raw.isEmpty) return const TextEditingValue(text: '');

    final v = int.tryParse(raw);
    if (v == null) return oldValue;

    final formatted =
        NumberFormat('#,###', 'vi_VN').format(v).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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

    /// 🔴 QUAN TRỌNG: xác định đã tất toán
    final bool isClosed = investment.closedAt != null;

    final canWithdraw = investment.type == 'bank' &&
        !isClosed &&
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
          _infoCard('Vốn đầu tư', '${moneyText(investment.totalInvested)} VND'),

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

          const SizedBox(height: 18),

          /// ===== ACTION BUTTONS =====
          /// ===== ACTION BUTTONS =====
          Row(
            children: [
              /// 🏦 NGÂN HÀNG: CHỈ CHO RÚT
              if (investment.type == 'bank' && !isClosed)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (!_busy && canWithdraw) ? _openWithdrawSheet : null,
                    icon: const Icon(Icons.payments),
                    label: Text(canWithdraw ? 'Rút tiền' : 'Chưa tới hạn'),
                  ),
                ),

              /// 🏗️ BẤT ĐỘNG SẢN: THÊM CHI PHÍ / GÓP VỐN
              if (investment.type == 'real_estate')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _busy ? null : () => _openRealEstateCostSheet(context),
                    icon: const Icon(Icons.construction),
                    label: const Text('Thêm chi phí'),
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
      decoration: const InputDecoration(labelText: 'Tài khoản'),
      items: accounts
          .where((a) => !a.isDeleted)
          .map(
            (a) => DropdownMenuItem<int>(
              value: a.id,
              child: Text(
                a.bankname != null && a.bankname!.isNotEmpty
                    ? '${a.name} • ${a.bankname}'
                    : '${a.name} • —',
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  // ======================
  // TOP UP
  // ======================
  void _openTopUpSheet(BuildContext context) {
    final accounts = context.read<BankAccountProvider>().items;
    final amountCtl = TextEditingController();
    int? selectedAccountId;

    _openMoneySheet(
      context,
      title: 'Đầu tư thêm',
      accounts: accounts,
      amountCtl: amountCtl,
      onAccountChanged: (v) => selectedAccountId = v,
      onSubmit: (amount) async {
        await context.read<InvestmentProvider>().topUpBank(
              investment.id!,
              amount,
              selectedAccountId!,
            );
      },
    );
  }

  // ======================
  // REAL ESTATE COST
  // ======================
  void _openRealEstateCostSheet(BuildContext context) {
    final accounts = context.read<BankAccountProvider>().items;
    final amountCtl = TextEditingController();
    final noteCtl = TextEditingController();
    int? selectedAccountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thêm chi phí BĐS',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _accountDropdown(
                accounts, selectedAccountId, (v) => selectedAccountId = v),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtl,
              inputFormatters: [_VnMoneyInputFormatter()],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền chi'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtl,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final raw = amountCtl.text.replaceAll('.', '');
                if (raw.isEmpty || selectedAccountId == null) return;

                final amount = double.parse(raw);
                Navigator.pop(context);

                await context.read<InvestmentProvider>().addRealEstateCost(
                      investment.id!,
                      amount,
                      selectedAccountId!,
                      noteCtl.text,
                    );
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  // ======================
  // WITHDRAW
  // ======================
  void _openWithdrawSheet() {
    final accounts = context.read<BankAccountProvider>().items;

    int? receiveAccountId;
    WithdrawType withdrawType = WithdrawType.interest;

    final amountCtl = TextEditingController();
    final moneyFmt = NumberFormat('#,###', 'vi_VN');

    // lãi còn lại (backend phải trả đúng field này)
    final double maxInterest = investment.profitLoss; // CHỈ LÃI CHƯA RÚT

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bool isInterest = withdrawType == WithdrawType.interest;

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
                  'Rút tiền về tài khoản',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ===== CHỌN TÀI KHOẢN =====
                _accountDropdown(
                  accounts,
                  receiveAccountId,
                  (v) => setModalState(() => receiveAccountId = v),
                ),

                const SizedBox(height: 16),

                // ===== LOẠI RÚT =====
                RadioListTile(
                  title: const Text('Rút lãi'),
                  value: WithdrawType.interest,
                  groupValue: withdrawType,
                  onChanged: (v) {
                    setModalState(() {
                      withdrawType = v!;
                      amountCtl.clear();
                    });
                  },
                ),
                RadioListTile(
                  title: const Text('Rút toàn bộ (vốn + lãi)'),
                  value: WithdrawType.all,
                  groupValue: withdrawType,
                  onChanged: (v) {
                    setModalState(() {
                      withdrawType = v!;
                      amountCtl.clear();
                    });
                  },
                ),

                // ===== NHẬP SỐ TIỀN (CHỈ KHI RÚT LÃI) =====
                if (isInterest) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_VnMoneyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Số tiền rút',
                      helperText:
                          'Lãi còn lại: ${moneyFmt.format(maxInterest)} đ',
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ===== XÁC NHẬN =====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: receiveAccountId == null
                        ? null
                        : () async {
                            double? amount;

                            if (isInterest) {
                              final raw =
                                  amountCtl.text.replaceAll('.', '').trim();
                              if (raw.isEmpty) return;

                              amount = double.parse(raw);

                              if (amount <= 0 || amount > maxInterest) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Số tiền rút không hợp lệ',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            Navigator.pop(context);

                            await context
                                .read<InvestmentProvider>()
                                .withdrawBank(
                                  investment.id!,
                                  receiveAccountId!,
                                  withdrawType: withdrawType,
                                  amount: amount,
                                );

                            if (context.mounted) {
                              final provider =
                                  context.read<InvestmentProvider>();
                              await provider.fetch();

                              // 🔥 LẤY LẠI INVESTMENT MỚI
                              final updated = provider.items.firstWhere(
                                (e) => e.id == investment.id,
                                orElse: () => investment,
                              );

                              setState(() {
                                investment = updated;
                              });
                            }
                          },
                    child: const Text('Xác nhận'),
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
  // MONEY SHEET
  // ======================
  void _openMoneySheet(
    BuildContext context, {
    required String title,
    required List<BankAccount> accounts,
    required TextEditingController amountCtl,
    required ValueChanged<int?> onAccountChanged,
    required Future<void> Function(double amount) onSubmit,
  }) {
    int? selectedAccountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _accountDropdown(accounts, selectedAccountId, (v) {
              selectedAccountId = v;
              onAccountChanged(v);
            }),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtl,
              inputFormatters: [_VnMoneyInputFormatter()],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final raw = amountCtl.text.replaceAll('.', '');
                if (raw.isEmpty || selectedAccountId == null) return;

                final amount = double.parse(raw);
                Navigator.pop(context);
                await onSubmit(amount);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
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
