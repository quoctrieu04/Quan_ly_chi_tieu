import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/investment/investment_model.dart';

class CreateInvestmentForm extends StatefulWidget {
  const CreateInvestmentForm({super.key});

  @override
  State<CreateInvestmentForm> createState() => _CreateInvestmentFormState();
}

class _CreateInvestmentFormState extends State<CreateInvestmentForm> {
  final _formKey = GlobalKey<FormState>();

  String type = 'bank';

  /// ===== BANK =====
  String bankName = 'VCB';

  /// Lãi suất gợi ý (tham khảo)
  final Map<String, double> bankRates = const {
    'VCB': 5.5,
    'BIDV': 5.3,
    'VietinBank': 5.4,
    'MB': 5.8,
    'ACB': 6.0,
    'Techcombank': 5.7,
  };

  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController(); // bank
  final rateCtrl = TextEditingController();   // bank
  final priceCtrl = TextEditingController();  // stock
  final qtyCtrl = TextEditingController();    // stock

  DateTime startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // set lãi suất mặc định theo ngân hàng đầu tiên
    rateCtrl.text = bankRates[bankName]!.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thêm đầu tư',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // =========================
              // TYPE
              // =========================
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Loại đầu tư'),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Ngân hàng')),
                  DropdownMenuItem(value: 'stock', child: Text('Cổ phiếu')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),

              const SizedBox(height: 8),

              // =========================
              // NAME
              // =========================
              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tên khoản đầu tư'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Không được để trống' : null,
              ),

              // =========================
              // BANK FORM
              // =========================
              if (type == 'bank') ...[
                const SizedBox(height: 8),

                /// BANK NAME
                DropdownButtonFormField<String>(
                  value: bankName,
                  decoration: const InputDecoration(labelText: 'Ngân hàng'),
                  items: bankRates.keys
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(b),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      bankName = v!;
                      rateCtrl.text = bankRates[bankName]!.toString();
                    });
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Số tiền gửi'),
                  validator: _validateNumber,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Lãi suất % / năm'),
                  validator: _validateNumber,
                ),

                const SizedBox(height: 8),

                // START DATE
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày gửi'),
                  subtitle:
                      Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ],

              // =========================
              // STOCK FORM
              // =========================
              if (type == 'stock') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá mua'),
                  validator: _validateNumber,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                  validator: _validateNumber,
                ),
              ],

              const SizedBox(height: 20),

              // =========================
              // SAVE
              // =========================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // HELPERS
  // =========================

  String? _validateNumber(String? v) {
    if (v == null || v.isEmpty) return 'Không được để trống';
    if (double.tryParse(v) == null) return 'Giá trị không hợp lệ';
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<InvestmentProvider>();

    if (type == 'bank') {
      await prov.add(
        Investment(
          name: nameCtrl.text,
          type: 'bank',
          bankName: bankName,
          buyPrice: double.parse(amountCtrl.text),
          currentPrice: double.parse(amountCtrl.text),
          quantity: 1,
          interestRate: double.parse(rateCtrl.text),
          startDate: startDate,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await prov.add(
        Investment(
          name: nameCtrl.text,
          type: 'stock',
          buyPrice: double.parse(priceCtrl.text),
          currentPrice: double.parse(priceCtrl.text),
          quantity: double.parse(qtyCtrl.text),
          createdAt: DateTime.now(),
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }
}
