import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvestmentFormFields {
  const InvestmentFormFields._();

  static Widget textField({
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
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      decoration: decoration(
        label: label,
        icon: icon,
        cs: cs,
        isDark: isDark,
        suffixText: suffixText,
        errorText: errorText,
      ),
      validator: validator,
    );
  }

  static Widget dropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      decoration: decoration(
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
    );
  }

  static Widget dateField({
    required String label,
    required String value,
    required ColorScheme cs,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      key: ValueKey(value),
      initialValue: value,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
      decoration: decoration(
        label: label,
        icon: Icons.calendar_today_rounded,
        cs: cs,
        isDark: isDark,
      ).copyWith(
        suffixIcon: Icon(
          Icons.calendar_month_rounded,
          color: cs.onSurface.withValues(alpha: .48),
        ),
      ),
    );
  }

  static Future<DateTime?> pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String helpText = 'CHỌN NGÀY',
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? cs.surfaceContainerHigh : Colors.white;

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      cancelText: 'HỦY',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: cs.copyWith(
              primary: cs.primary,
              onPrimary: cs.onPrimary,
              surface: surface,
              onSurface: cs.onSurface,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: .16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: cs.primary,
              headerForegroundColor: cs.onPrimary,
              headerHeadlineStyle: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              headerHelpStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                color: cs.onPrimary.withValues(alpha: .78),
              ),
              dayStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              weekdayStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: .52),
              ),
              yearStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              todayBorder: BorderSide(color: cs.primary, width: 1.5),
              dividerColor: Colors.transparent,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  static InputDecoration decoration({
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
}
