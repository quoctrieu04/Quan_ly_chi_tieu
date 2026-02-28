import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
              decoration: const InputDecoration(
                labelText: 'Giá bán',
                hintText: 'VD: 500.000.000',
                border: OutlineInputBorder(),
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ngày bán: ${DateFormat('dd/MM/yyyy').format(_sellDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
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
                value: _accountTargetId,
                decoration: const InputDecoration(
                  labelText: 'Tài khoản nhận tiền',
                  border: OutlineInputBorder(),
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
              height: 46,
              child: ElevatedButton(
                onPressed: _submitting || bankProv.items.isEmpty
                    ? null
                    : () async {
                        final sellPrice = _parseMoney(_priceCtl.text);
                        if (sellPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Nhập giá bán hợp lệ')),
                          );
                          return;
                        }
                        final accountId = _accountTargetId ?? 0;
                        if (accountId <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Chọn tài khoản nhận tiền')),
                          );
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
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xác nhận'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
