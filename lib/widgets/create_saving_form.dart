import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/saving/saving_provider.dart';
import 'package:intl/intl.dart';

class CreateSavingForm extends StatefulWidget {
  const CreateSavingForm({super.key});

  @override
  State<CreateSavingForm> createState() => _CreateSavingFormState();
}

class _CreateSavingFormState extends State<CreateSavingForm> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final monthlyCtrl = TextEditingController();
  DateTime startDate = DateTime.now();

  /// Formatter chỉ dùng dấu "."
  final formatter = NumberFormat.decimalPattern('vi_VN');

  /// Parse về double và bỏ toàn bộ dấu "."
  double parseMoney(String input) {
    return double.tryParse(input.replaceAll('.', '')) ?? 0;
  }

  /// Tự thêm dấu "." khi nhập
  void _formatMoney(TextEditingController controller, String value) {
    String digits = value.replaceAll('.', '');

    if (digits.isEmpty) {
      controller.value = TextEditingValue(text: '');
      return;
    }

    final number = int.parse(digits);

    // Format thành 1.234.567
    final newText = formatter.format(number);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tạo kế hoạch tiết kiệm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Tên kế hoạch'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Không được để trống' : null,
            ),

            TextFormField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền mục tiêu'),
              onChanged: (v) => _formatMoney(targetCtrl, v),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Không được để trống' : null,
            ),

            TextFormField(
              controller: monthlyCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Dự kiến gửi mỗi tháng'),
              onChanged: (v) => _formatMoney(monthlyCtrl, v),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final ok = await context.read<SavingProvider>().create({
                  'title': titleCtrl.text,
                  'target_amount': parseMoney(targetCtrl.text),
                  'monthly_amount': parseMoney(monthlyCtrl.text),
                  'start_date': startDate.toIso8601String().substring(0, 10),
                });

                if (!mounted) return;
                Navigator.pop(context, ok);
              },
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Tạo', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
