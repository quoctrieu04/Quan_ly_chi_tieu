import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class StockInvestmentForm extends StatefulWidget {
  const StockInvestmentForm({super.key});

  @override
  State<StockInvestmentForm> createState() =>
      _StockInvestmentFormState();
}

class _StockInvestmentFormState extends State<StockInvestmentForm> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');

  String? selectedAccount;

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
          /// ===== Tên mã / khoản đầu tư =====
          TextFormField(
            controller: nameCtrl,
            decoration:
                const InputDecoration(labelText: 'Tên cổ phiếu'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Không được để trống' : null,
          ),

          /// ===== Giá mua =====
          TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration: const InputDecoration(
                labelText: 'Giá mua / cổ phiếu (VNĐ)'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nhập giá mua' : null,
          ),

          /// ===== Số lượng =====
          TextFormField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Số lượng'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nhập số lượng';
              if (int.tryParse(v) == null || int.parse(v) <= 0) {
                return 'Số lượng không hợp lệ';
              }
              return null;
            },
          ),

          /// ===== Tài khoản nguồn =====
          DropdownButtonFormField<String>(
            value: selectedAccount,
            decoration:
                const InputDecoration(labelText: 'Tài khoản nguồn tiền'),
            validator: (v) =>
                v == null ? 'Vui lòng chọn tài khoản' : null,
            items: bankProv.items
                .map(
                  (acc) => DropdownMenuItem(
                    value: acc.id.toString(),
                    child: Text('${acc.name} - ${acc.bankname ?? ''}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedAccount = v),
          ),

          const SizedBox(height: 12),

          /// ===== LƯU =====
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

    final investmentProv = context.read<InvestmentProvider>();

    final price = _parseMoney(priceCtrl.text);
    final qty = int.parse(qtyCtrl.text);
    final total = price * qty;

    await investmentProv.addRaw({
      'name': nameCtrl.text,
      'type': 'stock',
      'buy_price': total, // tổng tiền mua
      'unit_price': price,
      'quantity': qty,
      'accountSource': int.parse(selectedAccount!),
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
