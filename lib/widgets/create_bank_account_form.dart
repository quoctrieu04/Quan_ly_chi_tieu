import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

/// =======================
/// FORMAT NHẬP TIỀN
/// =======================
class _MoneyInputFormatter extends TextInputFormatter {
  final _fmt = NumberFormat('#,###', 'vi_VN');

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
    final newText = _fmt.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// =======================
/// FORM TẠO TÀI KHOẢN
/// =======================
class CreateBankAccountForm extends StatefulWidget {
  const CreateBankAccountForm({super.key});

  @override
  State<CreateBankAccountForm> createState() => _CreateBankAccountFormState();
}

class _CreateBankAccountFormState extends State<CreateBankAccountForm> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankNumberCtrl = TextEditingController();
  final _initAmountCtrl = TextEditingController();

  String _currency = 'VND';
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankNumberCtrl.dispose();
    _initAmountCtrl.dispose();
    super.dispose();
  }

  /// =======================
  /// PARSE TIỀN AN TOÀN
  /// =======================
  double _parseMoney(String text) {
    final raw = text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9\-]'), '');

    return double.tryParse(raw) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Thêm tài khoản ngân hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),

                /// Tên tài khoản
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên tài khoản',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên tài khoản'
                          : null,
                ),
                const SizedBox(height: 12),

                /// Ngân hàng / ví
                TextFormField(
                  controller: _bankNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên ngân hàng / ví',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                /// Số tài khoản
                TextFormField(
                  controller: _bankNumberCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                /// Số dư ban đầu
                TextFormField(
                  controller: _initAmountCtrl,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_MoneyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Số dư ban đầu',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập số dư ban đầu';
                    }
                    final parsed = _parseMoney(v);
                    if (parsed <= 0) {
                      return 'Số dư ban đầu phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                /// Loại tiền
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Loại tiền',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'VND', child: Text('VND')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (v) => setState(() => _currency = v ?? 'VND'),
                ),
                const SizedBox(height: 20),

                /// Nút lưu
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_submitting ? 'Đang lưu...' : 'Lưu tài khoản'),
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            final initAmount =
                                _parseMoney(_initAmountCtrl.text);

                            setState(() => _submitting = true);

                            final success = await context
                                .read<BankAccountProvider>()
                                .createBankAccount(
                                  title: _titleCtrl.text.trim(),
                                  bankName: _bankNameCtrl.text.trim().isEmpty
                                      ? null
                                      : _bankNameCtrl.text.trim(),
                                  bankNumber:
                                      _bankNumberCtrl.text.trim().isEmpty
                                          ? null
                                          : _bankNumberCtrl.text.trim(),
                                  initAmount: initAmount,
                                  currency: _currency,
                                );

                            if (!mounted) return;
                            setState(() => _submitting = false);

                            if (success) {
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Tạo tài khoản không thành công'),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
