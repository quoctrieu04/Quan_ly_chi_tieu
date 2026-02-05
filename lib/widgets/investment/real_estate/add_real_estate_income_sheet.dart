import 'package:chitieu/api/real_estate/real_estate_income_plan_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            startDate: DateTime(
              _startMonth.year,
              _startMonth.month,
              1,
            ),
          );

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankAccounts = context.watch<BankAccountProvider>().items;

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
              decoration: const InputDecoration(
                labelText: 'Số tiền mỗi tháng',
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nhập số tiền' : null,
            ),

            const SizedBox(height: 12),

            // ===== THÁNG BẮT ĐẦU =====
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tháng bắt đầu'),
              subtitle: Text('${_startMonth.month}/${_startMonth.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startMonth,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  setState(() {
                    _startMonth = DateTime(picked.year, picked.month);
                  });
                }
              },
            ),

            const SizedBox(height: 8),

            // ===== TÀI KHOẢN NHẬN =====
            DropdownButtonFormField<int>(
              value: _accountId,
              items: bankAccounts
                  .map(
                    (a) => DropdownMenuItem<int>(
                      value: a.id,
                      child: Text(
                        a.bankname != null && a.bankname!.isNotEmpty
                            ? '${a.name} • ${a.bankname}'
                            : a.name,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              decoration: const InputDecoration(
                labelText: 'Tài khoản nhận tiền',
              ),
              validator: (v) => v == null ? 'Chọn tài khoản' : null,
            ),

            const SizedBox(height: 16),

            // ===== SUBMIT =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Tạo khoản thu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
