import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/core/date/year_month_provider.dart'; // ⚙️ Thêm import này

class CreateIncomeForm extends StatefulWidget {
  const CreateIncomeForm({super.key});

  @override
  State<CreateIncomeForm> createState() => _CreateIncomeFormState();
}

class _CreateIncomeFormState extends State<CreateIncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);

    final incomeProv = context.read<IncomeProvider>();
    final ym = context.read<YearMonthProvider>().ym; // 🧭 Lấy tháng/năm hiện tại

    final ok = await incomeProv.createIncomeCategory(
      _nameController.text.trim(),
      year: ym.year,
      month: ym.month,
    );

    setState(() => _saving = false);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true); // chỉ cần pop, không fetchAll()
      messenger.hideCurrentMaterialBanner();
      messenger.showMaterialBanner(
        MaterialBanner(
          content: Text('✅ ${t.walletCreated.isNotEmpty ? t.walletCreated : 'Đã tạo khoản thu tháng ${ym.month}/${ym.year}!'}'),
          leading: const Icon(Icons.check_circle, color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
          contentTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: Text(
                'OK',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      );
      Future.delayed(const Duration(seconds: 2), messenger.hideCurrentMaterialBanner);
    } else {
      final err = incomeProv.error ?? t.somethingWrong;
      messenger.showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  const Text(
                    'Tạo khoản thu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Tên khoản thu',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên khoản thu' : null,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Lưu',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
