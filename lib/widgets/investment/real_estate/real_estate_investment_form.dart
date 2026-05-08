import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:chitieu/widgets/investment/investment_form_fields.dart';

class RealEstateInvestmentForm extends StatefulWidget {
  const RealEstateInvestmentForm({super.key});

  @override
  State<RealEstateInvestmentForm> createState() =>
      _RealEstateInvestmentFormState();
}

class _RealEstateInvestmentFormState extends State<RealEstateInvestmentForm> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String propertyType = 'land';
  String? selectedAccount;
  DateTime buyDate = DateTime.now();

  @override
  void dispose() {
    nameCtrl.dispose();
    locationCtrl.dispose();
    priceCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  double _parseMoney(String input) {
    final cleaned = input.replaceAll('.', '').replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    return double.parse(cleaned);
  }

  double _getSelectedAccountBalance(BankAccountProvider bankProv) {
    if (selectedAccount == null) return 0;
    final acc = bankProv.items.firstWhere(
      (e) => e.id.toString() == selectedAccount,
    );
    return acc.balance;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bankProv = context.watch<BankAccountProvider>();
    final reProv = context.watch<RealEstateProvider>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          InvestmentFormFields.textField(
            controller: nameCtrl,
            label: 'Tên tài sản',
            icon: Icons.home_work_outlined,
            cs: cs,
            isDark: isDark,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Không được để trống' : null,
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.dropdown<String>(
            value: propertyType,
            label: 'Loại BĐS',
            icon: Icons.category_outlined,
            cs: cs,
            isDark: isDark,
            items: const [
              DropdownMenuItem(value: 'land', child: Text('Đất')),
              DropdownMenuItem(value: 'house', child: Text('Nhà')),
              DropdownMenuItem(value: 'apartment', child: Text('Chung cư')),
            ],
            onChanged: (v) => setState(() => propertyType = v ?? 'land'),
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.textField(
            controller: locationCtrl,
            label: 'Vị trí / Địa chỉ',
            icon: Icons.location_on_outlined,
            cs: cs,
            isDark: isDark,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.textField(
            controller: priceCtrl,
            label: 'Giá mua',
            icon: Icons.payments_outlined,
            cs: cs,
            isDark: isDark,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            suffixText: 'đ',
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (selectedAccount != null) {
                _formKey.currentState?.validate();
              }
            },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nhập giá mua';
              final price = _parseMoney(v);
              if (price <= 0) return 'Giá mua không hợp lệ';
              if (selectedAccount == null) return null;
              if (price > _getSelectedAccountBalance(bankProv)) {
                return 'Số tiền vượt quá số dư tài khoản';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.dropdown<String>(
            value: selectedAccount,
            label: 'Tài khoản nguồn tiền',
            icon: Icons.account_balance_wallet_outlined,
            cs: cs,
            isDark: isDark,
            validator: (v) => v == null ? 'Chọn tài khoản' : null,
            items: bankProv.items
                .map(
                  (acc) => DropdownMenuItem(
                    value: acc.id.toString(),
                    child: Text('${acc.name} - ${acc.bankname ?? ''}'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() => selectedAccount = v);
              _formKey.currentState?.validate();
            },
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.dateField(
            label: 'Ngày mua',
            value: DateFormat('dd/MM/yyyy').format(buyDate),
            cs: cs,
            isDark: isDark,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.textField(
            controller: noteCtrl,
            label: 'Ghi chú',
            icon: Icons.notes_outlined,
            cs: cs,
            isDark: isDark,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: reProv.loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: reProv.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Lưu',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<RealEstateProvider>().create(
          name: nameCtrl.text.trim(),
          propertyType: propertyType,
          address: locationCtrl.text.trim(),
          purchasePrice: _parseMoney(priceCtrl.text),
          purchaseDate: buyDate,
          accountSourceId: int.parse(selectedAccount!),
          notes: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final picked = await InvestmentFormFields.pickDate(
      context: context,
      initialDate: buyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'CHỌN NGÀY',
    );
    if (picked != null) setState(() => buyDate = picked);
  }
}
