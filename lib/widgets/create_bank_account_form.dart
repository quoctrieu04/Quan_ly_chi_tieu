import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:intl/intl.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bgColor = isDark ? cs.surface : AppColors.background;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight - bottomInset - 12,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Handle bar ──
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Header ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary.withOpacity(.12),
                                  cs.primary.withOpacity(.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.primary.withOpacity(.1),
                              ),
                            ),
                            child: Icon(Icons.account_balance_rounded,
                                color: cs.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thêm tài khoản',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ngân hàng, ví điện tử, tiền mặt',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onSurface.withOpacity(.4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ── Tên tài khoản ──
                      _buildField(
                        controller: _titleCtrl,
                        label: 'Tên tài khoản',
                        cs: cs,
                        isDark: isDark,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập tên tài khoản'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ── Ngân hàng / ví ──
                      _buildField(
                        controller: _bankNameCtrl,
                        label: 'Tên ngân hàng / ví',
                        cs: cs,
                        isDark: isDark,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // ── Số tài khoản ──
                      _buildField(
                        controller: _bankNumberCtrl,
                        label: 'Số tài khoản',
                        cs: cs,
                        isDark: isDark,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // ── Số dư ban đầu ──
                      _buildField(
                        controller: _initAmountCtrl,
                        label: 'Số dư ban đầu',
                        cs: cs,
                        isDark: isDark,
                        suffixText: 'đ',
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_MoneyInputFormatter()],
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

                      // ── Loại tiền ──
                      DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: _underlineDecoration(
                          label: 'Loại tiền',
                          cs: cs,
                          isDark: isDark,
                        ),
                        icon: Icon(Icons.expand_more_rounded,
                            color: cs.onSurface.withOpacity(.55)),
                        borderRadius: BorderRadius.circular(14),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'VND', child: Text('VND')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'VND'),
                      ),
                      const SizedBox(height: 24),

                      // ── Save button ──
                      _buildSaveButton(cs),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  FIELD BUILDER
  // ═══════════════════════════
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required ColorScheme cs,
    required bool isDark,
    String? suffixText,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      decoration: _underlineDecoration(
        label: label,
        cs: cs,
        isDark: isDark,
        suffixText: suffixText,
      ),
      validator: validator,
    );
  }

  InputDecoration _underlineDecoration({
    required String label,
    required ColorScheme cs,
    required bool isDark,
    String? suffixText,
  }) {
    final lineColor =
        isDark ? cs.outlineVariant.withOpacity(.45) : const Color(0xFF98A2B3);

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(
        color: cs.onSurface.withOpacity(.55),
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      floatingLabelStyle: TextStyle(
        color: cs.onSurface.withOpacity(.55),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: cs.onSurface.withOpacity(.55),
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      filled: false,
      isDense: false,
      contentPadding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: lineColor, width: 1),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: lineColor, width: 1),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: cs.error, width: 1.2),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: cs.error, width: 1.4),
      ),
    );
  }

  // ═══════════════════════════
  //  SAVE BUTTON
  // ═══════════════════════════
  Widget _buildSaveButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _submitting
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, cs.tertiary, .3)!,
                  ],
                ),
          boxShadow: _submitting
              ? []
              : [
                  BoxShadow(
                    color: cs.primary.withOpacity(.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: _submitting
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final initAmount = _parseMoney(_initAmountCtrl.text);

                  setState(() => _submitting = true);

                  final success = await context
                      .read<BankAccountProvider>()
                      .createBankAccount(
                        title: _titleCtrl.text.trim(),
                        bankName: _bankNameCtrl.text.trim().isEmpty
                            ? null
                            : _bankNameCtrl.text.trim(),
                        bankNumber: _bankNumberCtrl.text.trim().isEmpty
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
                    showAppSnackBar(context, 'Tạo tài khoản không thành công', isError: true);
                  }
                },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _submitting
                ? const SizedBox(
                    key: ValueKey('spin'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                    key: ValueKey('icon'),
                    size: 20,
                  ),
          ),
          label: Text(
            _submitting ? 'Đang lưu...' : 'Lưu tài khoản',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: cs.primary.withOpacity(.3),
            disabledForegroundColor: Colors.white.withOpacity(.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
