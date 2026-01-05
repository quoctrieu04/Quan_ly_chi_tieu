// lib/pages/allocate_money_page.dart
import 'package:chitieu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/core/money/widgets/money_text.dart';
import 'package:chitieu/api/category/category_model.dart';

// Thêm provider để gọi BudgetsProvider
import 'package:provider/provider.dart';
import '../core/budget/budgets_provider.dart';

class AllocateMoneyPage extends StatefulWidget {
  final double available;                // Số tiền "Đang có"
  final List<Category> categories;       // Danh mục đã tạo
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
  late Map<int, int> _assigned;

  num get _totalAssigned => _assigned.values.fold<num>(0, (p, e) => p + e);

  num get _remaining =>
      (widget.available - _totalAssigned) < 0 ? 0 : widget.available - _totalAssigned;

  @override
  void initState() {
    super.initState();
    // Khởi tạo từ initialAssigned, ép về int
    _assigned = {
      for (final c in widget.categories)
        c.id: (widget.initialAssigned[c.id] ?? 0).round(),
    };
  }

  /// Mở dialog nhập tiền và LƯU NGAY 1 danh mục bằng API /budgets/set
  Future<void> _editAmount(dynamic categoryId) async {
    final localeName = Localizations.localeOf(context).toString();
    final t = AppLocalizations.of(context)!;

    final int catId = int.parse(categoryId.toString());
    final current = _assigned[catId] ?? 0;

    final formatter = LocalizedThousandsInputFormatter(localeName, allowDecimal: false);
    final controller = TextEditingController(text: formatter.formatNumber(current));

    final amount = await showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.enterAmountTitle), // "Nhập số tiền muốn phân bổ"
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            formatter,
          ],
          decoration: InputDecoration(hintText: t.hintAmountExample), // "Ví dụ: 30.000"
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(
            onPressed: () {
              final v = formatter.parseToNumber(controller.text) ?? current;
              Navigator.pop(ctx, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    try {
      final provider = context.read<BudgetsProvider>();
      final now = DateTime.now();
      final year  = provider.currentYear  ?? now.year;
      final month = provider.currentMonth ?? now.month;

      // LƯU NGAY 1 danh mục
      await provider.service.setOne( 
        year: year,
        month: month,
        categoryId: catId,
        amount: amount, // service sẽ tự sanitize "80.000" -> 80000
      );

      // Cập nhật UI cục bộ + refetch để đồng bộ tổng đã phân bổ
      setState(() => _assigned[catId] = amount.round());
      await provider.loadForMonth(year: year, month: month);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu phân bổ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu phân bổ thất bại: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E9),
      appBar: AppBar(
        title: Text(t.allocateTitle), // "Phân chia tiền vào ngân sách"
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Header “Đang có”
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF66C08A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white),
                const SizedBox(width: 12),
                Text(t.available, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const Spacer(),
                MoneyText(
                  widget.available,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Danh mục
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: widget.categories.length,
              itemBuilder: (ctx, i) {
                final c = widget.categories[i];
                final assigned = _assigned[c.id] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFFF4CE),
                            child: Icon(Icons.category, color: Colors.orange),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    Text(t.allocated), // "Đã phân bổ"
                                    MoneyText(assigned),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    Text('${t.spentLabel}'), // "Đã tiêu:"
                                    const MoneyText(0),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Nút +… tiền (sửa/lưu ngay)
                          SizedBox(
                            width: 112,
                            height: 36,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: TextButton(
                                  onPressed: () => _editAmount(c.id),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    backgroundColor: const Color(0xFFFFCF53),
                                    foregroundColor: const Color(0xFF1F4C2F),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('+', style: TextStyle(fontWeight: FontWeight.w700)),
                                      MoneyText(assigned, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                );
              },
            ),
          ),

          // Footer: hiển thị “Còn lại chưa phân bổ” + nút Tải lại (tuỳ chọn)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.remainingUnallocated, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        MoneyText(_remaining),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () async {
                      // Chỉ tải lại dữ liệu tháng hiện tại
                      final p = context.read<BudgetsProvider>();
                      final now = DateTime.now();
                      await p.loadForMonth(
                        year: p.currentYear ?? now.year,
                        month: p.currentMonth ?? now.month,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCF53),
                      foregroundColor: const Color(0xFF1F4C2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tải lại'),
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = _keepValidChars(newValue.text);
    if (raw.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
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
