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

class _RealEstateInvestmentFormState
    extends State<RealEstateInvestmentForm> {
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

  @override
  Widget build(BuildContext context) {
    final bankProv = context.watch<BankAccountProvider>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration:
                const InputDecoration(labelText: 'Tên tài sản'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Không được để trống' : null,
          ),

          DropdownButtonFormField<String>(
            value: propertyType,
            decoration: const InputDecoration(labelText: 'Loại BĐS'),
            items: const [
              DropdownMenuItem(value: 'land', child: Text('Đất')),
              DropdownMenuItem(value: 'house', child: Text('Nhà')),
              DropdownMenuItem(
                  value: 'apartment', child: Text('Chung cư')),
            ],
            onChanged: (v) => setState(() => propertyType = v!),
          ),

          TextFormField(
            controller: locationCtrl,
            decoration:
                const InputDecoration(labelText: 'Vị trí / Địa chỉ'),
          ),

          TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration:
                const InputDecoration(labelText: 'Giá mua (VNĐ)'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nhập giá mua' : null,
          ),

          DropdownButtonFormField<String>(
            value: selectedAccount,
            decoration:
                const InputDecoration(labelText: 'Tài khoản nguồn tiền'),
            validator: (v) =>
                v == null ? 'Chọn tài khoản' : null,
            items: bankProv.items
                .map(
                  (acc) => DropdownMenuItem(
                    value: acc.id.toString(),
                    child: Text(acc.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedAccount = v),
          ),

          ListTile(
            title: const Text('Ngày mua'),
            subtitle:
                Text(DateFormat('dd/MM/yyyy').format(buyDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),

          TextFormField(
            controller: noteCtrl,
            decoration:
                const InputDecoration(labelText: 'Ghi chú'),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Lưu'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<RealEstateProvider>();

    await prov.create(
      name: nameCtrl.text,
      propertyType: propertyType,
      address: locationCtrl.text,
      purchasePrice: _parseMoney(priceCtrl.text),
      purchaseDate: buyDate,
      accountSourceId: int.parse(selectedAccount!),
      notes: noteCtrl.text,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

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
