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

  // ===== BANK =====
  String bankName = 'VCB';
  int termMonths = 12;
  final List<int> termOptions = const [1, 3, 6, 12];

  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  DateTime startDate = DateTime.now();

  // ===== STOCK =====
  final stockPriceCtrl = TextEditingController();
  final stockQtyCtrl = TextEditingController(text: '1');

  // ===== REAL ESTATE =====
  final reLocationCtrl = TextEditingController();
  final reNoteCtrl = TextEditingController();
  final reQtyCtrl = TextEditingController(text: '1');
  DateTime reBuyDate = DateTime.now();

  double _parseNumber(String input) {
    final cleaned = input.replaceAll('.', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0;
    return double.parse(cleaned);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankAccountProvider>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    rateCtrl.dispose();
    stockPriceCtrl.dispose();
    stockQtyCtrl.dispose();
    reLocationCtrl.dispose();
    reNoteCtrl.dispose();
    reQtyCtrl.dispose();
    super.dispose();
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
                  DropdownMenuItem(
                      value: 'real_estate', child: Text('Bất động sản')),
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

              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tên khoản đầu tư'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Không được để trống' : null,
              ),

              /// ================= BANK =================
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
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => bankName = v!),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Số tiền gửi'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: termMonths,
                  decoration: const InputDecoration(labelText: 'Kỳ hạn'),
                  items: termOptions
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text('$m tháng')))
                      .toList(),
                  onChanged: (v) => setState(() => termMonths = v!),
                ),
                TextFormField(
                  controller: rateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Lãi suất % / năm'),
                ),
              ],

              /// ================= STOCK =================
              if (type == 'stock') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: stockPriceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration:
                      const InputDecoration(labelText: 'Giá mua / cổ phiếu'),
                ),
                TextFormField(
                  controller: stockQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                ),
              ],

              /// ================= REAL ESTATE =================
              if (type == 'real_estate') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: reLocationCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Vị trí / Địa chỉ'),
                ),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Giá mua (VNĐ)'),
                ),
                TextFormField(
                  controller: reQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                ),
                TextFormField(
                  controller: reNoteCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
                ),
              ],

              const SizedBox(height: 16),
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

  /// ================= SAVE =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final investmentProv = context.read<InvestmentProvider>();
    final accountSourceId = int.parse(selectedAccount!);
    final amount = _parseNumber(amountCtrl.text);
    final rate =
        rateCtrl.text.trim().isEmpty ? 0 : double.parse(rateCtrl.text);

    if (type == 'bank') {
      await investmentProv.addRaw({
        'name': nameCtrl.text,
        'type': 'bank',
        'buy_price': amount,
        'accountSource': accountSourceId,
        'interest_rate': rate,
        'term_months': termMonths,
        'start_date': startDate.toIso8601String(),
        'bank_name': bankName,
      });
    }

    if (!mounted) return;
    _showMessage('✅ Thành công');
    Navigator.pop(context, true);
  }
}
