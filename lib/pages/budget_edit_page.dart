import 'dart:convert';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/utils/error_handler.dart';

class BudgetEditPage extends StatefulWidget {
  /// null = tạo mới, khác null = sửa
  final Category? category;
  final String type; // "out" = chi, "in" = thu

  const BudgetEditPage({super.key, this.category, required this.type});

  @override
  State<BudgetEditPage> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends State<BudgetEditPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _nameFocus = FocusNode();
  bool _saving = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _controller.text = widget.category!.name;
    }
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;

    if (_saving) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAppSnackBar(context, t.loginRequiredMessage, isError: true);
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
        await catProv.update(
            id: widget.category!.id, name: name, type: widget.type);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      String msg = getFriendlyError(e);
      try {
        final jsonStart = msg.indexOf('{');
        if (jsonStart != -1) {
          final map =
              jsonDecode(msg.substring(jsonStart)) as Map<String, dynamic>;
          msg = (map['message'] as String?) ??
              (map['errors']?.toString() ?? e.toString());
        }
      } catch (_) {} // Đã xử lý ở getFriendlyError
      showAppSnackBar(context, '${t.genericFailedMessage}: $msg', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    if (widget.category == null) return;
    final cat = widget.category!;
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: cs.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(t.confirmTitle,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          t.confirmDeleteMessage(cat.name),
          style: TextStyle(
            color: cs.onSurface.withOpacity(.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
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
      showAppSnackBar(context, '${t.genericFailedMessage}: ${getFriendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Icon map ──
  IconData _iconForType() {
    if (widget.category != null) {
      final n = widget.category!.name.toLowerCase();
      if (n.contains('ăn') || n.contains('uống') || n.contains('food'))
        return Icons.restaurant_rounded;
      if (n.contains('di chuyển') ||
          n.contains('xăng') ||
          n.contains('transport')) return Icons.directions_car_rounded;
      if (n.contains('giải trí') || n.contains('entertainment'))
        return Icons.sports_esports_rounded;
      if (n.contains('mua sắm') || n.contains('shopping'))
        return Icons.shopping_bag_rounded;
      if (n.contains('sức khỏe') || n.contains('health'))
        return Icons.favorite_rounded;
      if (n.contains('giáo dục') ||
          n.contains('học') ||
          n.contains('education')) return Icons.school_rounded;
      if (n.contains('tiết kiệm') || n.contains('saving'))
        return Icons.savings_rounded;
      if (n.contains('nhà') || n.contains('thuê') || n.contains('rent'))
        return Icons.home_rounded;
    }
    return Icons.add_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.category != null;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          isEdit ? t.editCategoryTitle : t.createCategoryTitleForm,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? cs.outlineVariant.withOpacity(.1)
                : const Color(0xFFEEEFF3),
          ),
        ),
        actions: [
          if (isEdit)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: cs.error.withOpacity(.7), size: 22),
                tooltip: t.deleteCta,
                onPressed: _saving ? null : _confirmAndDelete,
                style: IconButton.styleFrom(
                  backgroundColor: cs.error.withOpacity(.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                constraints:
                    const BoxConstraints(minWidth: 38, minHeight: 38),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : Icon(Icons.check_rounded, color: cs.primary, size: 22),
                tooltip: t.saveCta,
                onPressed: _saving ? null : _save,
                constraints:
                    const BoxConstraints(minWidth: 38, minHeight: 38),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    // ── Hero Icon ──
                    _buildHeroIcon(cs, isDark, isEdit),
                    const SizedBox(height: 28),

                    // ── Name field ──
                    _buildNameField(cs, isDark, t),
                    const SizedBox(height: 24),

                    // ── Type indicator ──
                    if (widget.type.isNotEmpty) ...[
                      _buildTypeIndicator(cs, isDark),
                      const SizedBox(height: 28),
                    ],

                    // ── Save button ──
                    _buildSaveButton(cs, t, isEdit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon(ColorScheme cs, bool isDark, bool isEdit) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(
        scale: 0.5 + (0.5 * v),
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(.12),
              cs.primary.withOpacity(.04),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.primary.withOpacity(.15),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          _iconForType(),
          size: 36,
          color: cs.primary,
        ),
      ),
    );
  }

  Widget _buildNameField(ColorScheme cs, bool isDark, AppLocalizations t) {
    return TextFormField(
      controller: _controller,
      focusNode: _nameFocus,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _save(),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      decoration: InputDecoration(
        labelText: t.categoryNameLabel,
        hintText: t.categoryNameHint,
        labelStyle: TextStyle(
          color: cs.primary.withOpacity(.7),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: cs.onSurface.withOpacity(.3),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child:
              Icon(Icons.label_outline_rounded, color: cs.primary, size: 22),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? cs.outlineVariant.withOpacity(.08)
                : const Color(0xFFECEDF2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? cs.outlineVariant.withOpacity(.08)
                : const Color(0xFFECEDF2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        errorStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.error,
          height: 1.3,
        ),
        counterText: '',
      ),
      maxLength: 50,
      enabled: !_saving,
      validator: (value) {
        final name = (value ?? '').trim();
        if (name.isEmpty) return t.categoryNameRequired;
        return null;
      },
    );
  }

  Widget _buildTypeIndicator(ColorScheme cs, bool isDark) {
    final isIncome = widget.type == 'in';
    final typeColor =
        isIncome ? const Color(0xFF2E7D32) : cs.primary;
    final typeLabel = isIncome ? 'Thu nhập' : 'Chi tiêu';
    final typeIcon =
        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withOpacity(.12),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loại danh mục',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(.45),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isIncome ? 'IN' : 'OUT',
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme cs, AppLocalizations t, bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _saving
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, cs.tertiary, .3)!,
                  ],
                ),
          boxShadow: _saving
              ? []
              : [
                  BoxShadow(
                    color: cs.primary.withOpacity(.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _saving
                ? const SizedBox(
                    key: ValueKey('spinner'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isEdit ? Icons.save_rounded : Icons.add_rounded,
                    key: const ValueKey('icon'),
                    size: 20,
                  ),
          ),
          label: Text(
            isEdit ? t.updateCta : t.saveCta,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: cs.primary.withOpacity(.3),
            disabledForegroundColor: Colors.white.withOpacity(.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
