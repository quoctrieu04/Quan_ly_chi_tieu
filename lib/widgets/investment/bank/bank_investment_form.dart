import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_model.dart';

class BankInvestmentForm extends StatefulWidget {
  const BankInvestmentForm({super.key});

  @override
  State<BankInvestmentForm> createState() => _BankInvestmentFormState();
}

class _BankInvestmentFormState extends State<BankInvestmentForm> {
  final _formKey = GlobalKey<FormState>();

  String bankName = 'VCB';
  int termMonths = 12;
  final List<int> termOptions = const [1, 3, 6, 12];

  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  DateTime startDate = DateTime.now();

  String? selectedAccount;
  String? _amountError;

  // ===============================
  // PARSE MONEY
  // ===============================
  double _parseNumber(String input) {
    final cleaned = input.replaceAll('.', '').replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    return double.parse(cleaned);
  }

  // ===============================
  // GET SELECTED ACCOUNT
  // ===============================
  BankAccount? _getSelectedAccount(BuildContext context) {
    if (selectedAccount == null) return null;

    final accounts = context.read<BankAccountProvider>().items;
    try {
      return accounts.firstWhere(
        (a) => a.id.toString() == selectedAccount,
      );
    } catch (_) {
      return null;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final bankProv = context.watch<BankAccountProvider>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          /// ===== TÀI KHOẢN NGUỒN =====
          DropdownButtonFormField<String>(
            value: selectedAccount,
            decoration:
                const InputDecoration(labelText: 'Tài khoản nguồn tiền'),
            validator: (v) => v == null ? 'Vui lòng chọn tài khoản' : null,
            items: bankProv.items
                .map(
                  (acc) => DropdownMenuItem(
                    value: acc.id.toString(),
                    child: Text(
                      '${acc.name} - ${acc.bankname ?? ''} '
                      //'(Số dư: ${NumberFormat('#,###', 'vi_VN').format(acc.balance)} VND)',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedAccount = v),
          ),

          /// ===== TÊN =====
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Tên khoản đầu tư'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Không được để trống' : null,
          ),

          /// ===== NGÂN HÀNG =====
          DropdownButtonFormField<String>(
            value: bankName,
            decoration: const InputDecoration(labelText: 'Ngân hàng'),
            items: const [
              'VCB',
              'BIDV',
              'VietinBank',
              'MB',
              'ACB',
              'Techcombank',
            ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => bankName = v!),
          ),

          /// ===== SỐ TIỀN =====
          TextFormField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Số tiền gửi',
              errorText: _amountError,
            ),
          ),

          /// ===== KỲ HẠN =====
          DropdownButtonFormField<int>(
            value: termMonths,
            decoration: const InputDecoration(labelText: 'Kỳ hạn'),
            items: termOptions
                .map((m) => DropdownMenuItem(value: m, child: Text('$m tháng')))
                .toList(),
            onChanged: (v) => setState(() => termMonths = v!),
          ),

          /// ===== LÃI SUẤT =====
          TextFormField(
            controller: rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Lãi suất % / năm'),
          ),

          /// ===== NGÀY GỬI =====
          ListTile(
            title: const Text('Ngày gửi'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),

          const SizedBox(height: 12),

          /// ===== SAVE =====
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Lưu'),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // SAVE
  // ===============================
  Future<void> _save() async {
    setState(() => _amountError = null);

    if (!_formKey.currentState!.validate()) return;

    final account = _getSelectedAccount(context);
    if (account == null) return;

    final amount = _parseNumber(amountCtrl.text);

    if (amount > account.balance) {
      setState(() {
        _amountError = '❌ Số dư tài khoản không đủ';
      });
      return;
    }

    // ✅ OK → mới cho lưu
    await context.read<InvestmentProvider>().addRaw({
      'name': nameCtrl.text,
      'type': 'bank',
      'buy_price': amount,
      'accountSource': account.id,
      'interest_rate': double.tryParse(rateCtrl.text) ?? 0,
      'term_months': termMonths,
      'start_date': startDate.toIso8601String(),
      'bank_name': bankName,
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // ===============================
  // PICK DATE
  // ===============================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => startDate = picked);
  }
}
