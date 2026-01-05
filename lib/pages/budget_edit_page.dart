import 'dart:convert';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';

class BudgetEditPage extends StatefulWidget {
  /// null = tạo mới, khác null = sửa
  final Category? category;
  final String type; // “out” = chi, “in” = thu

  const BudgetEditPage({super.key, this.category, required this.type});

  @override
  State<BudgetEditPage> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends State<BudgetEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _nameFocus = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _controller.text = widget.category!.name;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;

    if (_saving) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      safeShowSnackBar(
        context,
        SnackBar(content: Text(t.loginRequiredMessage)),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);
    try {
      final name = _controller.text.trim();
      final catProv = context.read<CategoryProvider>();
      final budProv = context.read<BudgetsProvider>();

      if (widget.category == null) {
        // === TẠO MỚI ===
        await catProv.create(name, type: widget.type);

        // backend tự tạo luôn Budget → reload danh sách để hiển thị ngay
        await catProv.refresh();
        await budProv.loadForMonth(
          year: DateTime.now().year,
          month: DateTime.now().month,
        );
      } else {
        // === CẬP NHẬT ===
        await catProv.update(id: widget.category!.id, name: name, type: widget.type);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      try {
        final jsonStart = msg.indexOf('{');
        if (jsonStart != -1) {
          final map =
              jsonDecode(msg.substring(jsonStart)) as Map<String, dynamic>;
          msg = (map['message'] as String?) ??
              (map['errors']?.toString() ?? e.toString());
        }
      } catch (_) {}
      safeShowSnackBar(
        context,
        SnackBar(content: Text('${t.genericFailedMessage}: $msg')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    if (widget.category == null) return;
    final cat = widget.category!;
    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.confirmTitle),
        content: Text(t.confirmDeleteMessage(cat.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.deleteCta),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await context.read<CategoryProvider>().delete(id: cat.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      safeShowSnackBar(
        context,
        SnackBar(content: Text('${t.genericFailedMessage}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? t.editCategoryTitle : t.createCategoryTitleForm),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: t.deleteCta,
              onPressed: _saving ? null : _confirmAndDelete,
            ),
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            tooltip: t.saveCta,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                TextFormField(
                  controller: _controller,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: t.categoryNameLabel,
                    hintText: t.categoryNameHint,
                    filled: true,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  maxLength: 50,
                  enabled: !_saving,
                  validator: (value) {
                    final name = (value ?? '').trim();
                    if (name.isEmpty) return t.categoryNameRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _saving
                          ? const SizedBox(
                              key: ValueKey('spinner'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEdit ? t.updateCta : t.saveCta,
                              key: const ValueKey('label'),
                            ),
                    ),
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
