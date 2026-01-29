import 'package:flutter/material.dart';

import 'bank/bank_investment_form.dart';
import 'stock/stock_investment_form.dart';  
import 'real_estate/real_estate_investment_form.dart';
class CreateInvestmentSheet extends StatefulWidget {
  const CreateInvestmentSheet({super.key});

  @override
  State<CreateInvestmentSheet> createState() =>
      _CreateInvestmentSheetState();
}

class _CreateInvestmentSheetState extends State<CreateInvestmentSheet> {
  String type = 'bank';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Thêm đầu tư',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Loại đầu tư'),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Ngân hàng')),
                DropdownMenuItem(value: 'stock', child: Text('Cổ phiếu')),
                DropdownMenuItem(
                    value: 'real_estate', child: Text('Bất động sản')),
              ],
              onChanged: (v) => setState(() => type = v!),
            ),

            const SizedBox(height: 16),

            if (type == 'bank') const BankInvestmentForm(),
            if (type == 'stock') const StockInvestmentForm(),
            if (type == 'real_estate') const RealEstateInvestmentForm(),
          ],
        ),
      ),
    );
  }
}
