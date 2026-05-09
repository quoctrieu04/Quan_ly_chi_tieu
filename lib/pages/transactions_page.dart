import 'dart:async';

import 'package:flutter/material.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:chitieu/api/out_invoice/out_invoice_provider.dart';
import 'package:chitieu/api/in_invoice/in_invoice_provider.dart';

import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';
import 'package:chitieu/core/money/money_settings.dart';
import 'package:chitieu/core/theme/app_colors.dart';

import 'package:chitieu/financial_transaction/financial_transaction_model.dart';
import 'package:chitieu/financial_transaction/financial_transaction_provider.dart';

enum HistoryTab { transaction, investment }

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late int _year;
  late int _month;
  late int _baseYear;
  late int _baseMonth;
  int? _day;
  bool _inited = false;
  final TextEditingController _dateFilterCtl = TextEditingController();
  Timer? _dateFilterDebounce;

  HistoryTab _tab = HistoryTab.transaction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;

    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _day = now.day;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _year = (args['year'] as int?) ?? _year;
      _month = (args['month'] as int?) ?? _month;
      if (args.containsKey('day')) {
        _day = args['day'] as int?;
      }
    }
    _baseYear = _year;
    _baseMonth = _month;
    _syncDateFilterText();

    _inited = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentTab();
    });
  }

  Future<void> _fetchCurrentTab() async {
    if (_tab == HistoryTab.transaction) {
      await Future.wait([
        context.read<OutInvoiceProvider>().fetch(
              year: _year,
              month: _month,
              day: _day,
            ),
        context.read<InInvoiceProvider>().fetch(
              year: _year,
              month: _month,
              day: _day,
            ),
      ]);
    } else {
      await context.read<FinancialTransactionProvider>().fetchByMonth(
            year: _year,
            month: _month,
            day: _day,
            category: 'investment',
          );
    }
  }

  Future<void> _pickMonthDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, _day ?? 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      _year = picked.year;
      _month = picked.month;
      _day = picked.day;
      _syncDateFilterText();
    });

    await _fetchCurrentTab();
  }

  void _syncDateFilterText() {
    _dateFilterCtl.text = _day == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(DateTime(_year, _month, _day!));
  }

  DateTime? _parseDateFilter(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final parts = text
        .split(RegExp(r'[/.\-\s]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    final day = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final month = parts.length >= 2 ? int.tryParse(parts[1]) : _baseMonth;
    final year = parts.length >= 3 ? int.tryParse(parts[2]) : _baseYear;

    if (day == null || month == null || year == null) return null;
    if (year < 1000 || month < 1 || month > 12 || day < 1) return null;

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  bool _isIncompleteDateInput(String text) {
    return RegExp(r'[/.\-\s]$').hasMatch(text.trim());
  }

  void _onDateFilterChanged(String value) {
    setState(() {});
    _dateFilterDebounce?.cancel();
    _dateFilterDebounce = Timer(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      _applyDateFilter(showError: false, normalizeInput: false);
    });
  }

  Future<void> _applyDateFilter({
    bool showError = true,
    bool normalizeInput = true,
  }) async {
    final text = _dateFilterCtl.text.trim();
    if (text.isEmpty) {
      if (_year == _baseYear && _month == _baseMonth && _day == null) return;
      setState(() {
        _year = _baseYear;
        _month = _baseMonth;
        _day = null;
      });
      await _fetchCurrentTab();
      return;
    }

    if (!showError && _isIncompleteDateInput(text)) return;

    final date = _parseDateFilter(text);
    if (date == null) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar('Nhập ngày theo dạng 28, 28/04 hoặc 28/04/2026', isError: true),
        );
      }
      return;
    }

    if (_year == date.year && _month == date.month && _day == date.day) {
      if (normalizeInput) {
        setState(_syncDateFilterText);
      }
      return;
    }

    setState(() {
      _year = date.year;
      _month = date.month;
      _day = date.day;
      if (normalizeInput) _syncDateFilterText();
    });
    await _fetchCurrentTab();
  }

  Future<void> _clearDateFilter() async {
    _dateFilterDebounce?.cancel();
    setState(() {
      _year = _baseYear;
      _month = _baseMonth;
      _day = null;
      _dateFilterCtl.clear();
    });
    await _fetchCurrentTab();
  }

  @override
  void dispose() {
    _dateFilterDebounce?.cancel();
    _dateFilterCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : AppColors.background;
    final MoneySettings settings =
        context.watch<MoneySettingsProvider>().settings;

    final monthLabel = '${_month.toString().padLeft(2, '0')}/$_year';
    final dayLabel = (_day != null)
        ? DateFormat('dd/MM/yyyy').format(DateTime(_year, _month, _day!))
        : null;

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
          _day == null ? 'Lịch sử $monthLabel' : 'Lịch sử $dayLabel',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
              icon: Icon(Icons.calendar_month_rounded,
                  color: cs.primary, size: 22),
              onPressed: _pickMonthDay,
              tooltip: 'Chọn ngày',
              style: IconButton.styleFrom(
                backgroundColor: cs.primary.withOpacity(.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildDateFilterBar(cs, isDark),
          _buildTabSwitcher(cs, isDark),
          Expanded(
            child: RefreshIndicator(
              color: cs.primary,
              onRefresh: _fetchCurrentTab,
              child: _tab == HistoryTab.transaction
                  ? _buildTransactionList(settings, cs, isDark)
                  : _buildInvestmentList(settings, cs, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _dateFilterCtl,
        keyboardType: TextInputType.datetime,
        textInputAction: TextInputAction.search,
        onChanged: _onDateFilterChanged,
        onSubmitted: (_) => _applyDateFilter(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Lọc theo ngày: 28/04/2026',
          hintStyle: TextStyle(
            color: cs.onSurface.withOpacity(.38),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: cs.onSurface.withOpacity(.45), size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_day != null || _dateFilterCtl.text.trim().isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: cs.onSurface.withOpacity(.45), size: 20),
                  onPressed: _clearDateFilter,
                  tooltip: 'Bỏ lọc ngày',
                ),
            ],
          ),
          filled: true,
          fillColor: isDark ? cs.surfaceContainerHigh : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? cs.outlineVariant.withOpacity(.08)
                  : const Color(0xFFECEDF2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? cs.outlineVariant.withOpacity(.08)
                  : const Color(0xFFECEDF2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary.withOpacity(.45)),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  TAB SWITCHER
  // ═══════════════════════════
  Widget _buildTabSwitcher(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? cs.outlineVariant.withOpacity(.08)
                : const Color(0xFFECEDF2),
          ),
        ),
        child: Row(
          children: [
            _tabBtn('Giao dịch', HistoryTab.transaction,
                Icons.receipt_long_rounded, cs, isDark),
            const SizedBox(width: 4),
            _tabBtn('Đầu tư', HistoryTab.investment, Icons.trending_up_rounded,
                cs, isDark),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, HistoryTab tab, IconData icon, ColorScheme cs,
      bool isDark) {
    final active = _tab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tab == tab) return;
          setState(() => _tab = tab);
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _fetchCurrentTab());
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: active ? cs.primary.withOpacity(.1) : Colors.transparent,
            border: Border.all(
              color: active ? cs.primary.withOpacity(.2) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? cs.primary : cs.onSurface.withOpacity(.35),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.5,
                  color: active ? cs.primary : cs.onSurface.withOpacity(.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  TRANSACTION LIST
  // ═══════════════════════════
  Widget _buildTransactionList(
      MoneySettings settings, ColorScheme cs, bool isDark) {
    final outProv = context.watch<OutInvoiceProvider>();
    final inProv = context.watch<InInvoiceProvider>();

    if (outProv.loading || inProv.loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    final rows = [
      ...outProv.items.map(
        (e) => _TxnRow(
          amount: e.amount,
          type: 'out',
          date: e.occurredAt ?? e.createdAt ?? DateTime.now(),
          label: e.categoryName ?? 'Chi',
          content: e.content,
          photoUrl: e.photoUrl,
          photoPath: e.photoPath,
        ),
      ),
      ...inProv.items.map(
        (e) => _TxnRow(
          amount: e.amount,
          type: 'in',
          date: e.occurredAt ?? e.createdAt ?? DateTime.now(),
          label: e.categoryName ?? 'Thu',
          content: e.content,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (rows.isEmpty) return _emptyState('Chưa có giao dịch', cs);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: rows.length,
      itemBuilder: (_, i) => _transactionTile(rows[i], settings, cs, isDark, i),
    );
  }

  Widget _transactionTile(_TxnRow tx, MoneySettings settings, ColorScheme cs,
      bool isDark, int index) {
    final isOut = tx.type == 'out';
    final color = isOut ? cs.error : const Color(0xFF2E7D32);

    final hasPhoto = (tx.photoUrl != null && tx.photoUrl!.trim().isNotEmpty);
    final amountText = MoneyFormatter(settings).format(tx.amount);

    final noteText = (tx.content != null && tx.content!.trim().isNotEmpty)
        ? tx.content!.trim()
        : DateFormat('dd/MM/yyyy HH:mm').format(tx.date);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 30)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? cs.outlineVariant.withOpacity(.08)
                : const Color(0xFFECEDF2),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isOut
                    ? Icons.arrow_outward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amountText,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    noteText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Photo or date
            if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: tx.photoUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  memCacheWidth: 160,
                  maxWidthDiskCache: 320,
                  fadeInDuration: Duration.zero,
                  placeholder: (_, __) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHighest
                          : const Color(0xFFF0F1F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  errorWidget: (_, error, __) {
                    debugPrint('IMAGE LOAD ERROR: $error');
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surfaceContainerHighest
                            : const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 18, color: cs.onSurface.withOpacity(.3)),
                    );
                  },
                ),
              )
            else
              Text(
                DateFormat('dd/MM').format(tx.date),
                style: TextStyle(
                  color: cs.onSurface.withOpacity(.35),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  INVESTMENT LIST
  // ═══════════════════════════
  Widget _buildInvestmentList(
      MoneySettings settings, ColorScheme cs, bool isDark) {
    final prov = context.watch<FinancialTransactionProvider>();

    if (prov.loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (prov.items.isEmpty) {
      return _emptyState('Chưa có lịch sử đầu tư', cs);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: prov.items.length,
      itemBuilder: (_, i) =>
          _investmentTile(prov.items[i], settings, cs, isDark, i),
    );
  }

  Widget _investmentTile(FinancialTransaction tx, MoneySettings settings,
      ColorScheme cs, bool isDark, int index) {
    final isOut = tx.direction == 'out';
    final color = isOut ? cs.error : const Color(0xFF2E7D32);

    final subtitle =
        (tx.description != null && tx.description!.trim().isNotEmpty)
            ? tx.description!
            : DateFormat('dd/MM/yyyy HH:mm').format(tx.occurredAt);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 30)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? cs.outlineVariant.withOpacity(.08)
                : const Color(0xFFECEDF2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isOut
                    ? Icons.arrow_outward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title.isNotEmpty ? tx.title : 'Giao dịch',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                MoneyFormatter(settings).format(tx.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════
  Widget _emptyState(String text, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 36, color: cs.primary.withOpacity(.4)),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnRow {
  final num amount;
  final String type;
  final DateTime date;
  final String label;
  final String? content;
  final String? photoUrl;
  final String? photoPath;

  _TxnRow({
    required this.amount,
    required this.type,
    required this.date,
    required this.label,
    this.content,
    this.photoUrl,
    this.photoPath,
  });
}
