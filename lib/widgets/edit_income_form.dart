import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/core/date/year_month_provider.dart'; // ⚙️ thêm dòng này

class EditIncomeForm extends StatefulWidget {
  final int incomeId;
  final String initialTitle;
  final String initialCurrency;

  const EditIncomeForm({
    super.key,
    required this.incomeId,
    required this.initialTitle,
    this.initialCurrency = 'VND',
  });

  @override
  State<EditIncomeForm> createState() => _EditIncomeFormState();
}

class _EditIncomeFormState extends State<EditIncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    super.dispose();
  }

  /// 🧩 Cập nhật khoản thu
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final ym = context.read<YearMonthProvider>().ym; // 🧭 Lấy tháng/năm hiện tại

      final ok = await context.read<IncomeProvider>().updateIncomeCategory(
            widget.incomeId,
            title: _titleCtl.text.trim(),
            currency: widget.initialCurrency,
            // nếu backend cần, bạn có thể thêm year/month ở đây
            // year: ym.year,
            // month: ym.month,
          );

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        safeShowSnackBar(
          context,
          SnackBar(
            content: Text('Đã cập nhật khoản thu tháng ${ym.month}/${ym.year}'),
          ),
        );
      } else {
        final err = context.read<IncomeProvider>().error ?? 'Cập nhật không thành công';
        safeShowSnackBar(context, SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (mounted) {
        safeShowSnackBar(
          context,
          SnackBar(content: Text('Lỗi cập nhật khoản thu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 🗑️ Xóa khoản thu
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa khoản thu này không?'),
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
      final ok =
          await context.read<IncomeProvider>().deleteIncomeCategory(widget.incomeId);
      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã xóa khoản thu')),
        );
      } else {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Xóa khoản thu thất bại')),
        );
      }
    } catch (e) {
      if (mounted) {
        safeShowSnackBar(
          context,
          SnackBar(content: Text('Lỗi xóa khoản thu: $e')),
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
              'Chỉnh sửa khoản thu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // 📝 Tên khoản thu
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Tên khoản thu'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tên khoản thu' : null,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),

            // 💾 Nút lưu thay đổi
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

            // ❌ Nút xóa
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
                label: const Text('Xóa khoản thu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
