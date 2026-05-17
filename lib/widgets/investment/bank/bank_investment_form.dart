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
  final otherBankNameCtrl = TextEditingController();
  final customTermCtrl = TextEditingController();
  final otherBankNameFocus = FocusNode();
  final customTermFocus = FocusNode();

  String bankName = 'VCB';
  int termMonths = 12;
  static const int customTermOption = -1;
  int selectedTermOption = 12;
  final List<int> termOptions = const [1, 3, 5, 12];
  DateTime startDate = DateTime.now();

  String interestPaymentMethod = 'Trả lãi cuối kỳ';
  final List<String> interestPaymentOptions = const [
    'Trả lãi cuối kỳ',
    'Trả lãi hàng tháng',
    'Trả lãi trước'
  ];

  String rolloverMethod = 'Tất toán vào tài khoản';
  final List<String> rolloverOptions = const [
    'Tất toán vào tài khoản',
    'Tự động quay vòng gốc',
    'Tự động quay vòng gốc và lãi',
  ];

  String? selectedAccount;
  String? _amountError;

  @override
  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    rateCtrl.dispose();
    otherBankNameCtrl.dispose();
    customTermCtrl.dispose();
    otherBankNameFocus.dispose();
    customTermFocus.dispose();
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
                    child: Text('${acc.name} - ${acc.bankname ?? ''}', overflow: TextOverflow.ellipsis),
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
          _switchableField(
            bankName == 'Khác'
                ? _buildTextField(
                    controller: otherBankNameCtrl,
                    focusNode: otherBankNameFocus,
                    autofocus: true,
                    label: 'Tên ngân hàng',
                    icon: Icons.account_balance_outlined,
                    cs: cs,
                    isDark: isDark,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nhập tên ngân hàng';
                      }
                      return null;
                    },
                  )
                : _buildDropdownField<String>(
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
                      'Khác',
                    ]
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => bankName = v ?? 'VCB');
                      if (v == 'Khác') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) otherBankNameFocus.requestFocus();
                        });
                      }
                    },
                  ),
            key: ValueKey(bankName == 'Khác' ? 'bank-other' : 'bank-preset'),
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
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập số tiền';
              final amount = _parseNumber(v);
              if (amount <= 0) return 'Số tiền không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _switchableField(
            selectedTermOption == customTermOption
                ? _buildTextField(
                    controller: customTermCtrl,
                    focusNode: customTermFocus,
                    autofocus: true,
                    label: 'Kỳ hạn (tháng)',
                    icon: Icons.event_repeat_rounded,
                    cs: cs,
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final months = int.tryParse(v?.trim() ?? '');
                      if (months == null || months <= 0) {
                        return 'Nhập kỳ hạn hợp lệ';
                      }
                      return null;
                    },
                  )
                : _buildDropdownField<int>(
                    value: selectedTermOption,
                    label: 'Kỳ hạn',
                    icon: Icons.event_repeat_rounded,
                    cs: cs,
                    isDark: isDark,
                    items: termOptions
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text('$m tháng', overflow: TextOverflow.ellipsis)))
                        .followedBy([
                      const DropdownMenuItem<int>(
                        value: customTermOption,
                        child: Text('Khác', overflow: TextOverflow.ellipsis),
                      ),
                    ]).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedTermOption = v ?? 12;
                        if (selectedTermOption != customTermOption) {
                          termMonths = selectedTermOption;
                        }
                      });
                      if (v == customTermOption) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) customTermFocus.requestFocus();
                        });
                      }
                    },
                  ),
            key: ValueKey(selectedTermOption == customTermOption
                ? 'term-custom'
                : 'term-preset'),
          ),
          const SizedBox(height: 12),
          _buildInterestMethodSelector(cs, isDark),

          const SizedBox(height: 12),
          _buildTextField(
            controller: rateCtrl,
            label: 'Lãi suất % / năm',
            icon: Icons.percent_rounded,
            cs: cs,
            isDark: isDark,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập lãi suất' : null,
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

  Widget _switchableField(Widget child, {required Key key}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: KeyedSubtree(key: key, child: child),
    );
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
    FocusNode? focusNode,
    bool autofocus = false,
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
        focusNode: focusNode,
        autofocus: autofocus,
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
        isExpanded: true,
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

  Widget _buildInterestMethodSelector(ColorScheme cs, bool isDark) {
    return Material(
      color: isDark ? cs.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? cs.outlineVariant.withOpacity(0.08) : const Color(0xFFECEDF2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              'Chọn phương thức trả lãi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ...interestPaymentOptions.asMap().entries.map((entry) {
            final int index = entry.key;
            final String option = entry.value;
            final bool isLast = index == interestPaymentOptions.length - 1;
            
            return Column(
              children: [
                _buildRadioRow(option, cs, isDark),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: isDark ? cs.outlineVariant.withOpacity(0.1) : const Color(0xFFF0F0F0),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRadioRow(String value, ColorScheme cs, bool isDark) {
    final isSelected = interestPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => interestPaymentMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? cs.onSurface : cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _amountError = null);

    if (!_formKey.currentState!.validate()) return;

    final account = _getSelectedAccount(context);
    if (account == null) return;

    final amount = _parseNumber(amountCtrl.text);
    final resolvedBankName =
        bankName == 'Khác' ? otherBankNameCtrl.text.trim() : bankName;
    final resolvedTermMonths = selectedTermOption == customTermOption
        ? int.parse(customTermCtrl.text.trim())
        : selectedTermOption;

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
      'term_months': resolvedTermMonths,
      'start_date': startDate.toIso8601String(),
      'bank_name': resolvedBankName,
      'interest_payment_method': interestPaymentMethod,
      'rollover_method': rolloverMethod,
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
