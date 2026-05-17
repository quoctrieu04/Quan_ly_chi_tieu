import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/utils/money_input_formatter.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class AddRealEstateCostSheet extends StatefulWidget {
  final int realEstateId;

  const AddRealEstateCostSheet({
    super.key,
    required this.realEstateId,
  });

  @override
  State<AddRealEstateCostSheet> createState() => _AddRealEstateCostSheetState();
}

class _AddRealEstateCostSheetState extends State<AddRealEstateCostSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  int? _accountId;

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Thêm chi phí phát sinh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              MoneyInputFormatter(),
            ],
            decoration: _fieldDecoration(
              label: 'Số tiền',
              icon: Icons.payments_outlined,
              cs: cs,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: _fieldDecoration(
              label: 'Ghi chú',
              icon: Icons.note_outlined,
              cs: cs,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _accountId,
            borderRadius: BorderRadius.circular(14),
            icon: Icon(
              Icons.expand_more_rounded,
              color: cs.onSurface.withOpacity(.45),
            ),
            items: context.watch<BankAccountProvider>().items
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
              label: 'Tài khoản nguồn',
              icon: Icons.account_balance_wallet_outlined,
              cs: cs,
              isDark: isDark,
            ),
            validator: (v) => v == null ? 'Chọn tài khoản' : null,
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: _fieldDecoration(
                label: 'Ngày phát sinh',
                icon: Icons.calendar_today_outlined,
                cs: cs,
                isDark: isDark,
                suffixIcon: Icons.calendar_month_rounded,
              ),
              child: Text(
                '${_date.day.toString().padLeft(2, '0')}/'
                '${_date.month.toString().padLeft(2, '0')}/'
                '${_date.year}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Text(
                      'Lưu chi phí',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
  final raw = _amountCtrl.text.replaceAll('.', '');
  final amount = double.tryParse(raw);

  if (amount == null || amount <= 0) {
    _toast('Số tiền không hợp lệ');
    return;
  }

  if (_accountId == null) {
    _toast('Vui lòng chọn tài khoản nguồn');
    return;
  }

  setState(() => _saving = true);

  try {
    await context.read<RealEstateProvider>().addCost(
      realEstateId: widget.realEstateId,
      amount: amount,
      accountSourceId: _accountId!,
      note: _noteCtrl.text,
      costDate: _date,
    );

    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    _toast(e.toString());
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _toast(String msg) {
    showAppSnackBar(context, msg, isError: true);
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
