import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/utils/money_input_formatter.dart';
import 'package:chitieu/utils/safe_ui.dart';

class AddRealEstateCostSheet extends StatefulWidget {
  final int realEstateId;

  const AddRealEstateCostSheet({
    super.key,
    required this.realEstateId,
  });

  @override
  State<AddRealEstateCostSheet> createState() => _AddRealEstateCostSheetState();
}

class _AddRealEstateCostSheetState extends State<AddRealEstateCostSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  int? _accountId;

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Thêm chi phí phát sinh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              MoneyInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Số tiền',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 20),
            title: const Text('Ngày phát sinh'),
            subtitle: Text(
              '${_date.day.toString().padLeft(2, '0')}/'
              '${_date.month.toString().padLeft(2, '0')}/'
              '${_date.year}',
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu chi phí'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
  final raw = _amountCtrl.text.replaceAll('.', '');
  final amount = double.tryParse(raw);

  if (amount == null || amount <= 0) {
    _toast('Số tiền không hợp lệ');
    return;
  }

  setState(() => _saving = true);

  try {
    await context.read<RealEstateProvider>().addCost(
      realEstateId: widget.realEstateId,
      amount: amount,
      accountSourceId: _accountId ?? 1,
      note: _noteCtrl.text,
      costDate: _date,
    );

    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    _toast(e.toString());
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _toast(String msg) {
    showAppSnackBar(context, msg, isError: true);
  }
}
