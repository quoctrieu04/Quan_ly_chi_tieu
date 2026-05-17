import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/utils/safe_ui.dart';

class SellRealEstateSheet extends StatefulWidget {
  final int realEstateId;
  final String realEstateName;

  const SellRealEstateSheet({
    super.key,
    required this.realEstateId,
    required this.realEstateName,
  });

  @override
  State<SellRealEstateSheet> createState() => _SellRealEstateSheetState();
}

class _SellRealEstateSheetState extends State<SellRealEstateSheet> {
  final _priceCtl = TextEditingController();
  DateTime _sellDate = DateTime.now();
  int? _accountTargetId;
  bool _submitting = false;

  String _money(num v) =>
      NumberFormat('#,###', 'vi').format(v).replaceAll(',', '.');

  int _parseMoney(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }

  String _formatMoneyInput(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return _money(int.parse(digits));
  }

  @override
  void dispose() {
    _priceCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sellDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _sellDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bankProv = context.watch<BankAccountProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // đảm bảo có dữ liệu tài khoản
    if (!bankProv.loading && bankProv.items.isEmpty && bankProv.error == null) {
      // gọi 1 lần khi mở sheet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bankProv.fetchAccounts();
      });
    }

    // auto chọn defaultAccount nếu có
    if (_accountTargetId == null && bankProv.items.isNotEmpty) {
      _accountTargetId = (bankProv.defaultAccount ?? bankProv.items.first).id;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.sell, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bán BĐS • ${widget.realEstateName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Giá bán
            TextField(
              controller: _priceCtl,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                label: 'Giá bán',
                icon: Icons.payments_outlined,
                cs: cs,
                isDark: isDark,
              ),
              onChanged: (v) {
                final f = _formatMoneyInput(v);
                if (f != v) {
                  _priceCtl.value = TextEditingValue(
                    text: f,
                    selection: TextSelection.collapsed(offset: f.length),
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // Ngày bán
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _fieldDecoration(
                  label: 'Ngày bán',
                  icon: Icons.calendar_month_outlined,
                  cs: cs,
                  isDark: isDark,
                  suffixIcon: Icons.calendar_month_rounded,
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_sellDate),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tài khoản nhận tiền
            if (bankProv.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 3),
              )
            else if (bankProv.items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bankProv.error ?? 'Chưa có tài khoản nào để nhận tiền.',
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            else
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: _accountTargetId,
                borderRadius: BorderRadius.circular(14),
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: cs.onSurface.withOpacity(.45),
                ),
                decoration: _fieldDecoration(
                  label: 'Tài khoản nhận tiền',
                  icon: Icons.account_balance_wallet_outlined,
                  cs: cs,
                  isDark: isDark,
                ),
                items: bankProv.items.map((b) {
                  final bankName = (b.bankname ?? '').trim();
                  final label =
                      bankName.isEmpty ? b.name : '${b.name} • $bankName';

                  return DropdownMenuItem<int>(
                    value: b.id,
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _accountTargetId = v),
              ),

            const SizedBox(height: 14),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitting || bankProv.items.isEmpty
                    ? null
                    : () async {
                        final sellPrice = _parseMoney(_priceCtl.text);
                        if (sellPrice <= 0) {
                          showAppSnackBar(context, 'Nhập giá bán hợp lệ', isError: true);
                          return;
                        }
                        final accountId = _accountTargetId ?? 0;
                        if (accountId <= 0) {
                          showAppSnackBar(context, 'Chọn tài khoản nhận tiền', isError: true);
                          return;
                        }

                        setState(() => _submitting = true);
                        try {
                          Navigator.pop(context, {
                            'sell_price': sellPrice.toDouble(),
                            'sell_date': _sellDate,
                            'account_target_id': accountId,
                          });
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                child: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text(
                        'Xác nhận',
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

