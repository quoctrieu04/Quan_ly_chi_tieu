import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/saving/saving_provider.dart';
import 'package:intl/intl.dart';

class CreateSavingForm extends StatefulWidget {
  const CreateSavingForm({super.key});

  @override
  State<CreateSavingForm> createState() => _CreateSavingFormState();
}

class _CreateSavingFormState extends State<CreateSavingForm> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final monthlyCtrl = TextEditingController();
  DateTime startDate = DateTime.now();
  bool _saving = false;

  final formatter = NumberFormat.decimalPattern('vi_VN');

  double parseMoney(String input) {
    return double.tryParse(input.replaceAll('.', '')) ?? 0;
  }

  void _formatMoney(TextEditingController controller, String value) {
    String digits = value.replaceAll('.', '');

    if (digits.isEmpty) {
      controller.value = const TextEditingValue(text: '');
      return;
    }

    final number = int.parse(digits);
    final newText = formatter.format(number);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    targetCtrl.dispose();
    monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : const Color(0xFFFAFBFE);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
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
                          child: Icon(Icons.savings_rounded,
                              color: cs.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kế hoạch tiết kiệm',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tạo mục tiêu tiết kiệm mới',
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

                    // ── Tên kế hoạch ──
                    _buildField(
                      controller: titleCtrl,
                      label: 'Tên kế hoạch',
                      hint: 'VD: Du lịch, Quỹ khẩn cấp...',
                      icon: Icons.flag_rounded,
                      cs: cs,
                      isDark: isDark,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Số tiền mục tiêu ──
                    _buildField(
                      controller: targetCtrl,
                      label: 'Số tiền mục tiêu',
                      hint: '10.000.000',
                      icon: Icons.emoji_events_rounded,
                      cs: cs,
                      isDark: isDark,
                      suffixText: 'đ',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _formatMoney(targetCtrl, v),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Dự kiến gửi mỗi tháng ──
                    _buildField(
                      controller: monthlyCtrl,
                      label: 'Dự kiến gửi mỗi tháng',
                      hint: '1.000.000',
                      icon: Icons.calendar_today_rounded,
                      cs: cs,
                      isDark: isDark,
                      suffixText: 'đ',
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _formatMoney(monthlyCtrl, v),
                    ),
                    const SizedBox(height: 24),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _saving
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primary,
                                    Color.lerp(
                                        cs.primary, cs.tertiary, .3)!,
                                  ],
                                ),
                          boxShadow: _saving
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
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;

                                  setState(() => _saving = true);

                                  final ok = await context
                                      .read<SavingProvider>()
                                      .create({
                                    'title': titleCtrl.text,
                                    'target_amount':
                                        parseMoney(targetCtrl.text),
                                    'monthly_amount':
                                        parseMoney(monthlyCtrl.text),
                                    'start_date': startDate
                                        .toIso8601String()
                                        .substring(0, 10),
                                  });

                                  if (!mounted) return;
                                  setState(() => _saving = false);
                                  Navigator.pop(context, ok);
                                },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(
                                    opacity: anim, child: child),
                            child: _saving
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
                            _saving ? 'Đang tạo...' : 'Tạo kế hoạch',
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
                            disabledBackgroundColor:
                                cs.primary.withOpacity(.3),
                            disabledForegroundColor:
                                Colors.white.withOpacity(.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
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
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    String? hint,
    String? suffixText,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withOpacity(.08)
              : const Color(0xFFECEDF2),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: cs.primary.withOpacity(.7),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: cs.onSurface.withOpacity(.25),
            fontWeight: FontWeight.w400,
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: cs.onSurface.withOpacity(.5),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: cs.primary, size: 22),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
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
        ),
        validator: validator,
      ),
    );
  }
}
