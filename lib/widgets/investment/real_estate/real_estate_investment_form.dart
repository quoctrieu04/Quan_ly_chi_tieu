import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

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
    final bankProv = context.watch<BankAccountProvider>();
    final reProv = context.watch<RealEstateProvider>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // =====================
          // TÊN TÀI SẢN
          // =====================
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Tên tài sản'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Không được để trống' : null,
          ),

          // =====================
          // LOẠI BĐS
          // =====================
          DropdownButtonFormField<String>(
            value: propertyType,
            decoration: const InputDecoration(labelText: 'Loại BĐS'),
            items: const [
              DropdownMenuItem(value: 'land', child: Text('Đất')),
              DropdownMenuItem(value: 'house', child: Text('Nhà')),
              DropdownMenuItem(value: 'apartment', child: Text('Chung cư')),
            ],
            onChanged: (v) => setState(() => propertyType = v!),
          ),

          // =====================
          // ĐỊA CHỈ (METADATA)
          // =====================
          TextFormField(
            controller: locationCtrl,
            decoration: const InputDecoration(labelText: 'Vị trí / Địa chỉ'),
          ),

          // =====================
          // GIÁ MUA
          // =====================
          TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration: const InputDecoration(labelText: 'Giá mua (VNĐ)'),
            onChanged: (_) {
              if (selectedAccount != null) {
                _formKey.currentState?.validate();
              }
            },
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Nhập giá mua';
              }

              final price = _parseMoney(v);

              if (price <= 0) {
                return 'Giá mua không hợp lệ';
              }

              if (selectedAccount == null) {
                return null; // chưa chọn tài khoản → chưa check số dư
              }

              final balance = _getSelectedAccountBalance(bankProv);

              if (price > balance) {
                return 'Số tiền vượt quá số dư tài khoản';
              }

              return null;
            },
          ),

          // =====================
          // TÀI KHOẢN NGUỒN
          // =====================
          DropdownButtonFormField<String>(
            value: selectedAccount,
            decoration:
                const InputDecoration(labelText: 'Tài khoản nguồn tiền'),
            validator: (v) => v == null ? 'Chọn tài khoản' : null,
            items: bankProv.items
                .map(
                  (acc) => DropdownMenuItem(
                    value: acc.id.toString(),
                    child: Text('${acc.name} – ${acc.bankname}'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() => selectedAccount = v);
              _formKey.currentState?.validate();
            },
          ),

          // =====================
          // NGÀY MUA
          // =====================
          ListTile(
            title: const Text('Ngày mua'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(buyDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),

          // =====================
          // GHI CHÚ
          // =====================
          TextFormField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Ghi chú'),
          ),

          const SizedBox(height: 16),

          // =====================
          // SUBMIT
          // =====================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: reProv.loading ? null : _save,
              child: reProv.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // SAVE
  // =====================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<RealEstateProvider>();

    await prov.create(
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

  // =====================
  // DATE PICKER
  // =====================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: buyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => buyDate = picked);
  }
}
