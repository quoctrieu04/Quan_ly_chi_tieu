import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:chitieu/widgets/investment/investment_form_fields.dart';
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

  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final rateCtrl = TextEditingController();

  String bankName = 'VCB';
  int termMonths = 12;
  final List<int> termOptions = const [1, 3, 6, 12];
  DateTime startDate = DateTime.now();

  String? selectedAccount;
  String? _amountError;

  @override
  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    rateCtrl.dispose();
    super.dispose();
  }

  double _parseNumber(String input) {
    final cleaned = input.replaceAll('.', '').replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    return double.parse(cleaned);
  }

  BankAccount? _getSelectedAccount(BuildContext context) {
    if (selectedAccount == null) return null;

    final accounts = context.read<BankAccountProvider>().items;
    try {
      return accounts.firstWhere((a) => a.id.toString() == selectedAccount);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bankProv = context.watch<BankAccountProvider>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildDropdownField<String>(
            value: selectedAccount,
            label: 'Tài khoản nguồn tiền',
            icon: Icons.account_balance_wallet_outlined,
            cs: cs,
            isDark: isDark,
            validator: (v) => v == null ? 'Vui lòng chọn tài khoản' : null,
            items: bankProv.items
                .map(
                  (acc) => DropdownMenuItem(
                    value: acc.id.toString(),
                    child: Text('${acc.name} - ${acc.bankname ?? ''}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedAccount = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: nameCtrl,
            label: 'Tên khoản đầu tư',
            icon: Icons.label_outline_rounded,
            cs: cs,
            isDark: isDark,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Không được để trống' : null,
          ),
          const SizedBox(height: 12),
          _buildDropdownField<String>(
            value: bankName,
            label: 'Ngân hàng',
            icon: Icons.account_balance_outlined,
            cs: cs,
            isDark: isDark,
            items: const [
              'VCB',
              'BIDV',
              'VietinBank',
              'MB',
              'ACB',
              'Techcombank',
            ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => bankName = v ?? 'VCB'),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: amountCtrl,
            label: 'Số tiền gửi',
            icon: Icons.savings_outlined,
            cs: cs,
            isDark: isDark,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            suffixText: 'd',
            errorText: _amountError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _buildDropdownField<int>(
            value: termMonths,
            label: 'Kỳ hạn',
            icon: Icons.event_repeat_rounded,
            cs: cs,
            isDark: isDark,
            items: termOptions
                .map((m) => DropdownMenuItem(value: m, child: Text('$m tháng')))
                .toList(),
            onChanged: (v) => setState(() => termMonths = v ?? 12),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: rateCtrl,
            label: 'Lãi suất % / năm',
            icon: Icons.percent_rounded,
            cs: cs,
            isDark: isDark,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          _buildDateField(cs: cs, isDark: isDark),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldShell({
    required Widget child,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return child;
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    String? suffixText,
    String? errorText,
  }) {
    final borderColor = isDark
        ? cs.outlineVariant.withValues(alpha: .08)
        : const Color(0xFFECEDF2);

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(
        color: cs.primary.withValues(alpha: .7),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      suffixText: suffixText,
      errorText: errorText,
      filled: true,
      fillColor: isDark ? cs.surfaceContainerHigh : Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: cs.primary, size: 22),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
    String? errorText,
    String? Function(String?)? validator,
  }) {
    return _fieldShell(
      cs: cs,
      isDark: isDark,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: _fieldDecoration(
          label: label,
          icon: icon,
          cs: cs,
          isDark: isDark,
          suffixText: suffixText,
          errorText: errorText,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return _fieldShell(
      cs: cs,
      isDark: isDark,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: _fieldDecoration(
          label: label,
          icon: icon,
          cs: cs,
          isDark: isDark,
        ),
        icon: Icon(
          Icons.expand_more_rounded,
          color: cs.onSurface.withValues(alpha: .4),
        ),
        borderRadius: BorderRadius.circular(14),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildDateField({
    required ColorScheme cs,
    required bool isDark,
  }) {
    return InvestmentFormFields.dateField(
      label: 'Ngày gửi',
      value: DateFormat('dd/MM/yyyy').format(startDate),
      cs: cs,
      isDark: isDark,
      onTap: _pickDate,
    );
  }

  Future<void> _save() async {
    setState(() => _amountError = null);

    if (!_formKey.currentState!.validate()) return;

    final account = _getSelectedAccount(context);
    if (account == null) return;

    final amount = _parseNumber(amountCtrl.text);

    if (amount > account.balance) {
      setState(() {
        _amountError = 'Số dư tài khoản không đủ';
      });
      return;
    }

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

  Future<void> _pickDate() async {
    final picked = await InvestmentFormFields.pickDate(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'CHỌN NGÀY',
    );
    if (picked != null) setState(() => startDate = picked);
  }
}
