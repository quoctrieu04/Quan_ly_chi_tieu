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

class _CategoryDetailPageState extends State<CategoryDetailPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtl;
  late final TextEditingController _limitCtl;
  bool _busy = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.category.name);

    final nf = NumberFormat.decimalPattern('vi_VN');
    _limitCtl = TextEditingController(
      text: nf.format(widget.initialLimit.round()),
    );

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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtl.dispose();
    _limitCtl.dispose();
    super.dispose();
  }

  // Chuẩn hoá tiền: bỏ mọi ký tự không phải số
  double _parseMoney(String s) {
    final raw = s.trim().replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(raw) ?? 0;
  }

  // ── Icon map ──
  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
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
    if (n.contains('giáo dục') || n.contains('học') || n.contains('education'))
      return Icons.school_rounded;
    if (n.contains('tiết kiệm') || n.contains('saving'))
      return Icons.savings_rounded;
    if (n.contains('hoá đơn') || n.contains('tiện ích') || n.contains('bill'))
      return Icons.receipt_long_rounded;
    if (n.contains('nhà') || n.contains('thuê') || n.contains('rent'))
      return Icons.home_rounded;
    if (n.contains('lương') || n.contains('thu nhập') || n.contains('income'))
      return Icons.attach_money_rounded;
    return Icons.category_rounded;
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
    final cs = Theme.of(context).colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            Text(t.delete,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          t.areYouSureDelete,
          style: TextStyle(
            color: cs.onSurface.withOpacity(.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t.delete),
          ),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : const Color(0xFFFAFBFE);

    final monthLabel =
        'Tháng ${widget.month}/${widget.year}';

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
          t.categoryDetails,
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
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: cs.error.withOpacity(.7), size: 22),
              tooltip: t.delete,
              onPressed: _busy ? null : _delete,
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
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Hero Icon ──
                      _buildHeroSection(cs, isDark),
                      const SizedBox(height: 28),

                      // ── Name field ──
                      _buildField(
                        controller: _nameCtl,
                        labelText: t.categoryName,
                        prefixIcon: Icons.label_outline_rounded,
                        cs: cs,
                        isDark: isDark,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return t.fieldRequired;
                          if (v.trim().length > 60) return t.tooLong;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Limit field ──
                      _buildField(
                        controller: _limitCtl,
                        labelText: t.assignedMoney,
                        prefixIcon: Icons.account_balance_wallet_outlined,
                        suffixText: 'đ',
                        cs: cs,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        inputFormatters: [VNDThousandsFormatter()],
                        validator: (v) {
                          final n = _parseMoney(v ?? '');
                          if ((v ?? '').trim().isEmpty)
                            return t.fieldRequired;
                          if (n.isNaN) return t.numberInvalid;
                          if (n < 0) return t.mustBePositive;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Period pill ──
                      _buildInfoPill(
                        icon: Icons.calendar_month_rounded,
                        label: monthLabel,
                        cs: cs,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),

                      // ── Save button ──
                      _buildSaveButton(cs, t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme cs, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(
        scale: 0.5 + (0.5 * v),
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
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
              _iconForCategory(widget.category.name),
              size: 32,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.category.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required ColorScheme cs,
    required bool isDark,
    String? suffixText,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withOpacity(.08)
              : const Color(0xFFECEDF2),
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
      child: TextFormField(
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: cs.primary.withOpacity(.7),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: cs.onSurface.withOpacity(.5),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(prefixIcon, color: cs.primary, size: 22),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
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
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withOpacity(.08)
              : const Color(0xFFECEDF2),
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
              color: cs.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian áp dụng',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(.45),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme cs, AppLocalizations t) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _busy
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, cs.tertiary, .3)!,
                  ],
                ),
          boxShadow: _busy
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
          onPressed: _busy ? null : _save,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _busy
                ? const SizedBox(
                    key: ValueKey('spinner'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.save_rounded,
                    key: ValueKey('icon'),
                    size: 20,
                  ),
          ),
          label: Text(
            t.save,
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
