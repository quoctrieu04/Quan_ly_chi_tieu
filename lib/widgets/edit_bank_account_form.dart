import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class EditBankAccountForm extends StatefulWidget {
  final int accountId;
  final String initialName;
  final String? initialBankName;
  final String? initialBankNumber;
  final double initialBalance;
  final String initialCurrency;

  const EditBankAccountForm({
    super.key,
    required this.accountId,
    required this.initialName,
    this.initialBankName,
    this.initialBankNumber,
    required this.initialBalance,
    this.initialCurrency = 'VND',
  });

  @override
  State<EditBankAccountForm> createState() => _EditBankAccountFormState();
}

class _EditBankAccountFormState extends State<EditBankAccountForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtl;
  late final TextEditingController _bankNameCtl;
  late final TextEditingController _bankNumberCtl;
  late final TextEditingController _balanceCtl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.initialName);
    _bankNameCtl = TextEditingController(text: widget.initialBankName ?? '');
    _bankNumberCtl =
        TextEditingController(text: widget.initialBankNumber ?? '');
    _balanceCtl = TextEditingController(text: widget.initialBalance.toString());
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _bankNameCtl.dispose();
    _bankNumberCtl.dispose();
    _balanceCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final body = {
        'name': _nameCtl.text.trim(),
        'bankname': _bankNameCtl.text.trim(),
        'banknumber': _bankNumberCtl.text.trim(),
        'balance': double.tryParse(_balanceCtl.text.trim()) ?? 0,
        'currency': widget.initialCurrency,
      };

      final ok = await context
          .read<BankAccountProvider>()
          .updateAccount(widget.accountId, body);

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã cập nhật tài khoản')),
        );
      } else {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Cập nhật thất bại')),
        );
      }
    } catch (e) {
      if (mounted) {
        safeShowSnackBar(
          context,
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _saving = true);

    try {
      await context.read<BankAccountProvider>().deleteAccount(widget.accountId);
      await context.read<BankAccountProvider>().fetchAccounts();
      if (!mounted) return;
      Navigator.pop(context, true);
      safeShowSnackBar(
        context,
        const SnackBar(content: Text('Đã xóa tài khoản')),
      );
    } catch (e) {
      if (mounted) {
        safeShowSnackBar(
          context,
          SnackBar(content: Text('Lỗi xóa tài khoản: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chỉnh sửa tài khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Tên tài khoản'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tên tài khoản' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bankNameCtl,
              decoration: const InputDecoration(labelText: 'Tên ngân hàng'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bankNumberCtl,
              decoration: const InputDecoration(labelText: 'Số tài khoản'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _balanceCtl,
              decoration: const InputDecoration(
                labelText: 'Số dư hiện tại',
                helperText: 'Không thể chỉnh sửa số dư',
              ),
              keyboardType: TextInputType.number,
              readOnly: true,
              enabled: false, // làm mờ + không focus
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa tài khoản'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
