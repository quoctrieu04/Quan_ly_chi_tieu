import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:chitieu/widgets/investment/investment_form_fields.dart';

class StockInvestmentForm extends StatefulWidget {
  const StockInvestmentForm({super.key});

  @override
  State<StockInvestmentForm> createState() => _StockInvestmentFormState();
}

class _StockInvestmentFormState extends State<StockInvestmentForm> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');

  String? selectedAccount;

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  double _parseMoney(String input) {
    final cleaned = input.replaceAll('.', '').replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    return double.parse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bankProv = context.watch<BankAccountProvider>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          InvestmentFormFields.textField(
            controller: nameCtrl,
            label: 'Tên cổ phiếu',
            icon: Icons.candlestick_chart_rounded,
            cs: cs,
            isDark: isDark,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Không được để trống' : null,
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.textField(
            controller: priceCtrl,
            label: 'Giá mua / cổ phiếu',
            icon: Icons.payments_outlined,
            cs: cs,
            isDark: isDark,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            suffixText: 'đ',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập giá mua' : null,
          ),
          const SizedBox(height: 12),
          InvestmentFormFields.textField(
            controller: qtyCtrl,
            label: 'Số lượng',
            icon: Icons.confirmation_number_outlined,
            cs: cs,
            isDark: isDark,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final qty = int.tryParse(v ?? '');
              if (qty == null || qty <= 0) {
                return 'Số lượng không hợp lệ';
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
            validator: (v) => v == null ? 'Vui lòng chọn tài khoản' : null,
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
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
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

    final price = _parseMoney(priceCtrl.text);
    final qty = int.parse(qtyCtrl.text);

    await context.read<InvestmentProvider>().addRaw({
      'name': nameCtrl.text,
      'type': 'stock',
      'buy_price': price * qty,
      'unit_price': price,
      'quantity': qty,
      'accountSource': int.parse(selectedAccount!),
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
