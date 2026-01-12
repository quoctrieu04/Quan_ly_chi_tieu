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
  final amountCtrl = TextEditingController(); // dùng cho bank và real_estate
  final rateCtrl = TextEditingController();

  DateTime startDate = DateTime.now(); // dùng cho bank

  // ===== STOCK =====
  final stockPriceCtrl = TextEditingController();
  final stockQtyCtrl = TextEditingController(text: '1');

  // ===== REAL ESTATE =====
  final reLocationCtrl = TextEditingController(); // địa chỉ / vị trí
  final reNoteCtrl = TextEditingController();     // mô tả
  final reQtyCtrl = TextEditingController(text: '1'); // số lượng (mặc định 1)
  DateTime reBuyDate = DateTime.now();

  // ===============================
  // PARSE SỐ VN
  // ===============================
  double _parseNumber(String input) {
    final cleaned = input.replaceAll('.', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0;
    return double.parse(cleaned);
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

  String? validateQty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Không được để trống';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Số lượng phải > 0';
    return null;
  }

  @override
  void initState() {
    super.initState();

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
                  DropdownMenuItem(value: 'real_estate', child: Text('Bất động sản')), // ✅ NEW
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => type = v);
                },
              ),

              const SizedBox(height: 8),

              /// ===== Tài khoản nguồn =====
              DropdownButtonFormField<String>(
                value: selectedAccount,
                decoration: const InputDecoration(labelText: 'Tài khoản nguồn tiền'),
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
                decoration: const InputDecoration(labelText: 'Tên khoản đầu tư'),
                validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
              ),

              /// =========================
              /// BANK FORM
              /// =========================
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
                  ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
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
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m tháng')))
                      .toList(),
                  onChanged: (v) => setState(() => termMonths = v!),
                ),
                TextFormField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Lãi suất % / năm'),
                  validator: validateRate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày gửi'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickBankDate,
                ),
              ],

              /// =========================
              /// STOCK FORM (tối thiểu)
              /// =========================
              if (type == 'stock') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: stockPriceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Giá mua / cổ phiếu'),
                  validator: validateAmount,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: stockQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                  validator: validateQty,
                ),
              ],

              /// =========================
              /// REAL ESTATE FORM ✅ NEW
              /// =========================
              if (type == 'real_estate') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: reLocationCtrl,
                  decoration: const InputDecoration(labelText: 'Vị trí / Địa chỉ'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Giá mua (VNĐ)'),
                  validator: validateAmount,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng (mặc định 1)'),
                  validator: validateQty,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reNoteCtrl,
                  decoration: const InputDecoration(labelText: 'Mô tả / Ghi chú (tuỳ chọn)'),
                  maxLines: 2,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày mua'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(reBuyDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickRealEstateDate,
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

    final investmentProv = context.read<InvestmentProvider>();

    // ✅ Common accountSource
    final accountSourceId = int.parse(selectedAccount!);

    // BANK
    if (type == 'bank') {
      final amount = _parseNumber(amountCtrl.text);
      final rate = rateCtrl.text.trim().isEmpty
          ? 0
          : double.parse(rateCtrl.text.replaceAll(',', '.'));

      final ok = await investmentProv.addRaw({
        'name': nameCtrl.text,
        'type': type,
        'buy_price': amount,
        'bank_id': accountSourceId, // (nếu backend bạn đang dùng vậy)
        'accountSource': accountSourceId,
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
      return;
    }

    // STOCK
    if (type == 'stock') {
      final price = _parseNumber(stockPriceCtrl.text);
      final qty = double.parse(stockQtyCtrl.text.trim());

      final ok = await investmentProv.addRaw({
        'name': nameCtrl.text,
        'type': type,
        'buy_price': price,       // giá mua
        'current_price': price,   // lúc tạo = giá mua
        'quantity': qty,
        'accountSource': accountSourceId,
      });

      if (ok) {
        Navigator.pop(context, true);
        _showMessage('✅ Đã lưu khoản đầu tư');
      } else {
        _showMessage('❌ Lưu không thành công');
      }
      return;
    }

    // REAL ESTATE ✅ NEW
    if (type == 'real_estate') {
      final buy = _parseNumber(amountCtrl.text);
      final qty = double.parse(reQtyCtrl.text.trim());

      final ok = await investmentProv.addRaw({
        'name': nameCtrl.text,
        'type': type,
        'buy_price': buy,
        'current_price': buy, // tạm để = buy (nếu backend cần)
        'quantity': qty,      // số lượng BĐS (thường 1)
        'accountSource': accountSourceId,

        // extra fields (backend có thể lưu hoặc ignore)
        'location': reLocationCtrl.text.trim(),
        'note': reNoteCtrl.text.trim(),
        'buy_date': reBuyDate.toIso8601String(),
      });

      if (ok) {
        Navigator.pop(context, true);
        _showMessage('✅ Đã lưu khoản đầu tư');
      } else {
        _showMessage('❌ Lưu không thành công');
      }
      return;
    }
  }

  Future<void> _pickBankDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickRealEstateDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: reBuyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => reBuyDate = picked);
  }
}
