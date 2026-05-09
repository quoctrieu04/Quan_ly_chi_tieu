// lib/pages/allocate_money_page.dart
import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/core/money/widgets/money_text.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/pages/budget_edit_page.dart';

// Thêm provider để gọi BudgetsProvider
import 'package:provider/provider.dart';
import '../core/budget/budgets_provider.dart';

class AllocateMoneyPage extends StatefulWidget {
  final double available; // Số tiền "Đang có"
  final List<Category> categories; // Danh mục đã tạo
  final Map<dynamic, num> initialAssigned;

  const AllocateMoneyPage({
    super.key,
    required this.available,
    required this.categories,
    this.initialAssigned = const {},
  });

  @override
  State<AllocateMoneyPage> createState() => _AllocateMoneyPageState();
}

class _AllocateMoneyPageState extends State<AllocateMoneyPage> {
  /// categoryId -> amount (int)
  late List<Category> _categories;
  late Map<int, int> _assigned;
  late final int _initialTotalAssigned;

  num get _totalAssigned => _assigned.values.fold<num>(0, (p, e) => p + e);

  num get _planningPool => widget.available + _initialTotalAssigned;

  num get _remaining =>
      (_planningPool - _totalAssigned) < 0 ? 0 : _planningPool - _totalAssigned;

  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('ăn') || n.contains('uong') || n.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (n.contains('nhà') || n.contains('nha') || n.contains('home')) {
      return Icons.home_outlined;
    }
    if (n.contains('sam') || n.contains('pet')) {
      return Icons.person_outline_rounded;
    }
    if (n.contains('xe') ||
        n.contains('đi') ||
        n.contains('di') ||
        n.contains('transport')) {
      return Icons.directions_car_filled_outlined;
    }
    if (n.contains('mua') || n.contains('shopping')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.category_outlined;
  }

  @override
  void initState() {
    super.initState();
    _categories = List<Category>.from(widget.categories);
    // Khởi tạo từ initialAssigned, ép về int
    _assigned = {
      for (final c in _categories)
        c.id: (widget.initialAssigned[c.id] ?? 0).round(),
    };
    _initialTotalAssigned = _assigned.values.fold<int>(0, (p, e) => p + e);
  }

  Future<void> _createCategoryInsidePlan() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const BudgetEditPage(type: ''),
      ),
    );

    if (!mounted || created != true) return;

    final catProv = context.read<CategoryProvider>();
    await catProv.refresh();
    if (!mounted) return;

    setState(() {
      _categories = List<Category>.from(catProv.items);
      for (final category in _categories) {
        _assigned.putIfAbsent(category.id, () => 0);
      }
    });
  }

  /// Mở form chỉnh sửa kế hoạch và lưu giá trị mới cho danh mục.
  Future<void> _editAmount(dynamic categoryId) async {
    final localeName = Localizations.localeOf(context).toString();
    final t = AppLocalizations.of(context)!;

    final int catId = int.parse(categoryId.toString());
    final current = _assigned[catId] ?? 0;
    var categoryName = '';
    for (final c in _categories) {
      if (c.id == catId) {
        categoryName = c.name;
        break;
      }
    }

    final formatter =
        LocalizedThousandsInputFormatter(localeName, allowDecimal: false);
    final controller =
        TextEditingController(text: formatter.formatNumber(current));

    final amount = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        const primary = Color(0xFF008B83);
        const primaryDark = Color(0xFF006C66);
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        void submit() {
          final v = formatter.parseToNumber(controller.text) ?? current;
          Navigator.pop(sheetContext, v);
        }

        void setQuickAmount(num value) {
          final text = formatter.formatNumber(value);
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }

        Widget quickChip(num value) {
          return OutlinedButton(
            onPressed: () => setQuickAmount(value),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryDark,
              side: BorderSide(color: primary.withOpacity(.55)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(formatter.formatNumber(value)),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E7E5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    categoryName.isEmpty
                        ? 'Kế hoạch'
                        : 'Kế hoạch cho $categoryName',
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhập số tiền muốn lên kế hoạch',
                    style: TextStyle(
                      color: Colors.black.withOpacity(.48),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      formatter,
                    ],
                    style: const TextStyle(
                      color: primaryDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'đ',
                      suffixStyle: TextStyle(
                        color: Colors.black.withOpacity(.48),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      hintText: t.hintAmountExample,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      quickChip(500000),
                      quickChip(1000000),
                      quickChip(2000000),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF172033),
                            side: BorderSide(
                              color: Colors.black.withOpacity(.22),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(t.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Lưu'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (amount == null) return;
    if (!mounted) return;

    try {
      final provider = context.read<BudgetsProvider>();
      final now = DateTime.now();
      final year = provider.currentYear ?? now.year;
      final month = provider.currentMonth ?? now.month;

      if (amount == current) return;

      // Form này là chỉnh sửa kế hoạch, nên gửi mode=set để backend lưu
      // amount là giá trị cuối cùng thay vì cộng thêm.
      await provider.service.setOne(
        year: year,
        month: month,
        categoryId: catId,
        amount: amount,
        mode: 'set',
      );

      if (!mounted) return;

      // Cập nhật UI cục bộ + refetch để đồng bộ tổng đã phân bổ
      setState(() => _assigned[catId] = amount.round());
      await provider.loadForMonth(year: year, month: month);

      if (mounted) {
        showAppSnackBar(context, 'Đã lưu phân bổ', icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Lưu phân bổ thất bại: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    const primary = Color(0xFF008B83);
    const primaryDark = Color(0xFF006C66);
    const iconBg = Color(0xFFE4F3F0);
    const chipBg = Color(0xFFEAF8F5);
    final textMuted = Colors.black.withOpacity(.58);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          t.allocateTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: primaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Header “Đang có”
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF009B8E), Color(0xFF007A73)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(.14),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Còn lại',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.86),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                MoneyText(
                  _remaining,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // Danh mục
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: _createCategoryInsidePlan,
                    icon: const Icon(Icons.add_chart_rounded, size: 18),
                    label: const Text('Tạo danh mục'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryDark,
                      side: BorderSide(color: primary.withOpacity(.45)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                ..._categories.map((c) {
                  final assigned = _assigned[c.id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 0,
                      shadowColor: Colors.black.withOpacity(.05),
                      child: InkWell(
                        onTap: () => _editAmount(c.id),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                  textScaler: const TextScaler.linear(1.0)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      _categoryIcon(c.name),
                                      color: primaryDark,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF172033),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              'Kế hoạch: ',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Flexible(
                                              child: MoneyText(
                                                assigned,
                                                style: TextStyle(
                                                  color: textMuted,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Nút +… tiền (sửa/lưu ngay)
                                  SizedBox(
                                    width: 98,
                                    height: 34,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: TextButton(
                                          onPressed: () => _editAmount(c.id),
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(0, 34),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 7),
                                            backgroundColor: chipBg,
                                            foregroundColor: primaryDark,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              MoneyText(
                                                assigned,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Footer: hiển thị “Còn lại chưa phân bổ”
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.remainingUnallocated,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        MoneyText(
                          _remaining,
                          style: const TextStyle(
                            color: primaryDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// InputFormatter nhóm nghìn theo đúng locale
class LocalizedThousandsInputFormatter extends TextInputFormatter {
  LocalizedThousandsInputFormatter(this.localeName, {this.allowDecimal = false})
      : _format = NumberFormat.decimalPattern(localeName);

  final String localeName;
  final bool allowDecimal;
  final NumberFormat _format;

  String get _groupSep => _format.symbols.GROUP_SEP;
  String get _decSep => _format.symbols.DECIMAL_SEP;

  String _keepValidChars(String s) {
    final pattern = allowDecimal ? RegExp('[0-9$_decSep]') : RegExp(r'[0-9]');
    return s.split('').where((c) => pattern.hasMatch(c)).join();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = _keepValidChars(newValue.text);
    if (raw.isEmpty) {
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }

    String integerPart = raw;
    String decimalPart = '';
    if (allowDecimal && raw.contains(_decSep)) {
      final idx = raw.indexOf(_decSep);
      integerPart = raw.substring(0, idx);
      decimalPart = raw.substring(idx + 1);
    }

    integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (integerPart.isEmpty) integerPart = '0';

    final intVal = int.parse(integerPart);
    String formatted = _format.format(intVal);
    if (allowDecimal && decimalPart.isNotEmpty) {
      formatted = '$formatted$_decSep$decimalPart';
    }

    final right = newValue.text.length - newValue.selection.extentOffset;
    final newOffset = (formatted.length - right).clamp(0, formatted.length);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  num? parseToNumber(String text) {
    var cleaned = text.replaceAll(_groupSep, '');
    if (allowDecimal) {
      cleaned = cleaned.replaceAll(_decSep, '.');
    } else {
      cleaned = cleaned.split(_decSep).first;
    }
    return num.tryParse(cleaned.trim());
  }

  String formatNumber(num value) {
    if (!allowDecimal) return _format.format(value.round());
    final parts = value.toString().split('.');
    final intPart = int.tryParse(parts.first) ?? 0;
    final base = _format.format(intPart);
    if (parts.length > 1 && parts.last != '0') {
      return '$base$_decSep${parts.last}';
    }
    return base;
  }
}
