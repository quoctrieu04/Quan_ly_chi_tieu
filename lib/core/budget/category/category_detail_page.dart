import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';
import 'package:chitieu/l10n/app_localizations.dart';

/// Formatter để format số tiền theo kiểu 1.000.000
class VNDThousandsFormatter extends TextInputFormatter {
  final NumberFormat _nf = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.trim().isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final normalized = digits.replaceFirst(RegExp(r'^0+'), '');
    final value = normalized.isEmpty ? '0' : normalized;

    final formatted = _nf.format(int.parse(value));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CategoryDetailPage extends StatefulWidget {
  final Category category;
  final int year;
  final int month;
  final double initialLimit;

  const CategoryDetailPage({
    super.key,
    required this.category,
    required this.year,
    required this.month,
    required this.initialLimit,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtl;
  late final TextEditingController _limitCtl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.category.name);

    final nf = NumberFormat.decimalPattern('vi_VN');
    _limitCtl = TextEditingController(
      text: nf.format(widget.initialLimit.round()),
    );
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _limitCtl.dispose();
    super.dispose();
  }

  // Chuẩn hoá tiền: bỏ mọi ký tự không phải số
  double _parseMoney(String s) {
    final raw = s.trim().replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context)!;

    setState(() => _busy = true);
    try {
      final newName = _nameCtl.text.trim();

      if (newName != widget.category.name) {
        await context.read<CategoryProvider>().update(
              id: widget.category.id.toInt(),
              name: newName,
            );
      }

      final limit = _parseMoney(_limitCtl.text);

      await context.read<BudgetsProvider>().assignMany(
        year: widget.year,
        month: widget.month,
        allocations: {widget.category.id.toInt(): limit.toDouble()},
      );

      await context.read<BudgetsProvider>().loadForMonth(
            year: widget.year,
            month: widget.month,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.saved)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.errorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.areYouSureDelete),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await context
          .read<CategoryProvider>()
          .delete(id: widget.category.id.toInt());

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.errorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.categoryDetails),
        actions: [
          IconButton(
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline),
            tooltip: t.delete,
          )
        ],
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameCtl,
                    decoration: InputDecoration(
                      labelText: t.categoryName,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return t.fieldRequired;
                      if (v.trim().length > 60) return t.tooLong;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _limitCtl,
                    decoration: InputDecoration(
                      labelText: t.assignedMoney,
                      suffixText: 'đ',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [VNDThousandsFormatter()],
                    validator: (v) {
                      final n = _parseMoney(v ?? '');
                      if ((v ?? '').trim().isEmpty) return t.fieldRequired;
                      if (n.isNaN) return t.numberInvalid;
                      if (n < 0) return t.mustBePositive;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(t.save),
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
