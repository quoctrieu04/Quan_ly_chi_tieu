import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

/// ===============================
/// FORMAT TIỀN: 1.000.000
/// ===============================
class MoneyInputFormatter extends TextInputFormatter {
  final _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.parse(digits);
    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CreateInvestmentForm extends StatefulWidget {
  const CreateInvestmentForm({super.key});

  @override
  State<CreateInvestmentForm> createState() => _CreateInvestmentFormState();
}

class _CreateInvestmentFormState extends State<CreateInvestmentForm> {
  final _formKey = GlobalKey<FormState>();

  String type = 'bank';
  String? selectedAccount;

  String bankName = 'VCB';
  int termMonths = 12;
  final List<int> termOptions = const [1, 3, 6, 12];

  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final rateCtrl = TextEditingController();

  DateTime startDate = DateTime.now();

  // ===============================
  // PARSE SỐ VN
  // ===============================
  double _parseNumber(String input) {
    return double.parse(input.replaceAll('.', ''));
  }

  // ===============================
  // VALIDATORS
  // ===============================
  String? validateAmount(String? v) {
    if (v == null || v.trim().isEmpty) return 'Không được để trống';
    final n = _parseNumber(v);
    if (n <= 0) return 'Số tiền phải > 0';
    return null;
  }

  String? validateRate(String? v) {
    if (v == null || v.trim().isEmpty) return null;

    final cleaned = v.replaceAll(',', '.').trim();
    final n = double.tryParse(cleaned);

    if (n == null) return 'Lãi suất không hợp lệ';
    if (n < 0) return 'Lãi suất phải ≥ 0';

    return null;
  }

  @override
  void initState() {
    super.initState();

    // ⚠️ KHÔNG gọi fetch trong build → gọi ở initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankAccountProvider>().fetchAccounts();
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bankAccountProvider = context.watch<BankAccountProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Thêm đầu tư',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              /// ===== Loại đầu tư =====
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Loại đầu tư'),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Ngân hàng')),
                  DropdownMenuItem(value: 'stock', child: Text('Cổ phiếu')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),

              const SizedBox(height: 8),

              /// ===== Tài khoản nguồn =====
              DropdownButtonFormField<String>(
                value: selectedAccount,
                decoration:
                    const InputDecoration(labelText: 'Tài khoản nguồn tiền'),
                validator: (v) => v == null ? 'Vui lòng chọn tài khoản' : null,
                items: bankAccountProvider.items
                    .map(
                      (acc) => DropdownMenuItem(
                        value: acc.id.toString(),
                        child: Text('${acc.name} - ${acc.bankname ?? ''}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedAccount = v),
              ),

              /// ===== Tên đầu tư =====
              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tên khoản đầu tư'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Không được để trống' : null,
              ),

              /// ===== BANK FORM =====
              if (type == 'bank') ...[
                const SizedBox(height: 8),
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
                  ]
                      .map(
                        (b) => DropdownMenuItem(value: b, child: Text(b)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => bankName = v!),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Số tiền gửi'),
                  validator: validateAmount,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: termMonths,
                  decoration: const InputDecoration(labelText: 'Kỳ hạn'),
                  items: termOptions
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m, child: Text('$m tháng')),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => termMonths = v!),
                ),
                TextFormField(
                  controller: rateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Lãi suất % / năm'),
                  validator: validateRate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày gửi'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ],

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // SAVE
  // ===============================
  Future<void> _save() async {
    debugPrint('💾 SAVE CLICKED');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ FORM INVALID');
      return;
    }

    final amount = _parseNumber(amountCtrl.text);
    final rate = rateCtrl.text.trim().isEmpty
        ? 0
        : double.parse(rateCtrl.text.replaceAll(',', '.'));

    final ok = await context.read<InvestmentProvider>().addRaw({
      'name': nameCtrl.text,
      'type': type,
      'buy_price': amount,
      'bank_id': int.parse(selectedAccount!), // tài khoản đầu tư
      'accountSource': int.parse(selectedAccount!), // ✅ TÀI KHOẢN NGUỒN
      'interest_rate': rate,
      'term_months': termMonths,
      'start_date': startDate.toIso8601String(),
      'bank_name': bankName,
    });

    if (ok) {
      Navigator.pop(context, true);
      _showMessage('✅ Đã lưu khoản đầu tư');
    } else {
      _showMessage('❌ Lưu không thành công');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }
}
