import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class CreateBankAccountForm extends StatefulWidget {
  const CreateBankAccountForm({super.key});

  @override
  State<CreateBankAccountForm> createState() => _CreateBankAccountFormState();
}

class _CreateBankAccountFormState extends State<CreateBankAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankNumberCtrl = TextEditingController();
  final _initAmountCtrl = TextEditingController();
  String _currency = 'VND';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankNumberCtrl.dispose();
    _initAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bankAccProv = context.read<BankAccountProvider>(); // ✅ rename
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thêm tài khoản ngân hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên tài khoản',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên ngân hàng / ví',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankNumberCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _initAmountCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Số dư ban đầu',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Loại tiền',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'VND', child: Text('VND')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (v) => setState(() => _currency = v ?? 'VND'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Lưu tài khoản'),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final bankAccProv = context.read<BankAccountProvider>();
                      debugPrint('[UI] Bắt đầu tạo tài khoản mới...');
                      final success = await bankAccProv.createBankAccount(
                        title: _titleCtrl.text.trim(),
                        bankName: _bankNameCtrl.text.trim(),
                        bankNumber: _bankNumberCtrl.text.trim(),
                        initAmount:
                            double.tryParse(_initAmountCtrl.text.trim()) ?? 0,
                        currency: _currency,
                      );
                      debugPrint('[UI] Kết quả tạo tài khoản: $success');

                      if (success && context.mounted) {
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tạo tài khoản thất bại')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
