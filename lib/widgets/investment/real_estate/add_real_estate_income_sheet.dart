import 'package:chitieu/api/real_estate/real_estate_income_plan_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/utils/money_input_formatter.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class AddRealEstateIncomePlanSheet extends StatefulWidget {
  final int realEstateId;

  const AddRealEstateIncomePlanSheet({
    super.key,
    required this.realEstateId,
  });

  @override
  State<AddRealEstateIncomePlanSheet> createState() =>
      _AddRealEstateIncomePlanSheetState();
}

class _AddRealEstateIncomePlanSheetState
    extends State<AddRealEstateIncomePlanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  DateTime _startMonth = DateTime.now();
  int? _accountId;
  bool _loading = false;

  int _parseMoney(String v) =>
      int.parse(v.replaceAll('.', '').replaceAll(',', ''));

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await context.read<RealEstateIncomePlanProvider>().createPlan(
            realEstateId: widget.realEstateId,
            bankAccountId: _accountId!, // 🔥 BẮT BUỘC
            monthlyAmount: _parseMoney(_amountCtrl.text).toDouble(),
            startDate: _startMonth, // TRUYỀN ĐÚNG NGÀY TRONG THÁNG
          );

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankAccounts = context.watch<BankAccountProvider>().items;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tạo khoản thu cho thuê',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // ===== SỐ TIỀN =====
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [MoneyInputFormatter()],
              decoration: _fieldDecoration(
                label: 'Số tiền mỗi tháng',
                icon: Icons.payments_outlined,
                cs: cs,
                isDark: isDark,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nhập số tiền' : null,
            ),

            const SizedBox(height: 12),

            // ===== NGÀY BẮT ĐẦU =====
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startMonth,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  setState(() {
                    _startMonth = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: _fieldDecoration(
                  label: 'Ngày bắt đầu kỳ thu',
                  icon: Icons.calendar_month_outlined,
                  cs: cs,
                  isDark: isDark,
                  suffixIcon: Icons.calendar_month_rounded,
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_startMonth),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== TÀI KHOẢN NHẬN =====
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _accountId,
              borderRadius: BorderRadius.circular(14),
              icon: Icon(
                Icons.expand_more_rounded,
                color: cs.onSurface.withOpacity(.45),
              ),
              items: bankAccounts
                  .map(
                    (a) => DropdownMenuItem<int>(
                      value: a.id,
                      child: Text(
                        a.bankname != null && a.bankname!.isNotEmpty
                            ? '${a.name} • ${a.bankname}'
                            : a.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              decoration: _fieldDecoration(
                label: 'Tài khoản nhận tiền',
                icon: Icons.account_balance_wallet_outlined,
                cs: cs,
                isDark: isDark,
              ),
              validator: (v) => v == null ? 'Chọn tài khoản' : null,
            ),

            const SizedBox(height: 18),

            // ===== SUBMIT =====
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text(
                        'Tạo khoản thu',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    IconData? suffixIcon,
  }) {
    final borderColor =
        isDark ? cs.outlineVariant.withOpacity(.12) : const Color(0xFFE5E7EB);

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(
        color: cs.primary.withOpacity(.65),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: isDark ? cs.surfaceContainerHigh : Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: cs.primary, size: 22),
      ),
      suffixIcon:
          suffixIcon == null ? null : Icon(suffixIcon, color: cs.primary),
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
