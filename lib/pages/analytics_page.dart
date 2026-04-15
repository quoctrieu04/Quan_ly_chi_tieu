import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _ym = DateTime(DateTime.now().year, DateTime.now().month);

  double? _currentMonthPrediction;
  double? _snapshotPrediction;
  double? _nextMonthPrediction;
  double? _warningLimit;
  double? _spentMtd;
  int _progressPercent = 0;
  String? _predictionStatus;
  String? _statusMessage;
  String? _aiError;
  bool _loadingAI = false;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final b = context.read<BudgetsProvider>();
      final c = context.read<CategoryProvider>();

      final futures = <Future<void>>[
        b.loadForMonth(year: _ym.year, month: _ym.month),
      ];

      if (!c.loading && c.items.isEmpty) {
        futures.add(c.refresh());
      }

      await Future.wait(futures);
      await _fetchPrediction();
    });
  }

  Future<void> _fetchPrediction() async {
    try {
      _safeSetState(() {
        _loadingAI = true;
        _aiError = null;
      });

      final dio = context.read<Dio>();

      final res = await dio.get(
        'predict/status',
        queryParameters: {
          'year': _ym.year,
          'month': _ym.month,
        },
      );

      final root = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      final data = (root['data'] is Map<String, dynamic>)
          ? root['data'] as Map<String, dynamic>
          : root;

      double toDouble(dynamic v) {
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }

      _safeSetState(() {
        _currentMonthPrediction = toDouble(data['current_month_prediction']);
        _snapshotPrediction = toDouble(data['snapshot_prediction']);
        _nextMonthPrediction = toDouble(data['next_month_prediction']);
        _warningLimit = toDouble(data['warning_limit']);
        _spentMtd = toDouble(data['spent_mtd']);
        _progressPercent = (data['progress_percent'] as num?)?.round() ?? 0;
        _predictionStatus = (data['status'] ?? 'ok').toString();
        _statusMessage = (data['message'] ?? 'Không có cảnh báo').toString();
        _loadingAI = false;
      });
    } on DioException catch (e) {
      debugPrint(
        'predict/status FAILED: status=${e.response?.statusCode}, body=${e.response?.data}',
      );

      _safeSetState(() {
        final status = e.response?.statusCode;
        _aiError = status == 401
            ? 'Phiên đăng nhập đã hết hạn'
            : 'API lỗi ${status ?? ''}'.trim();
        _loadingAI = false;
      });
    } catch (e) {
      debugPrint('fetchPrediction FAILED: $e');

      _safeSetState(() {
        _aiError = 'Không đọc được dữ liệu dự báo';
        _loadingAI = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final budgetsProv = context.watch<BudgetsProvider>();
    final catsProv = context.watch<CategoryProvider>();
    final walletProv = context.watch<BankAccountProvider>();

    final items = budgetsProv.items;
    final categories = {for (final c in catsProv.items) c.id: c};

    final totalAssigned = budgetsProv.totalAssigned;
    num totalSpent = 0;
    for (final it in items) {
      try {
        final s = (it as dynamic).spent;
        if (s is num) totalSpent += s;
      } catch (_) {}
    }

    final num totalBalance =
        walletProv.items.fold<num>(0, (sum, w) => sum + w.balance);
    final num combinedRemaining = totalBalance - totalSpent;
    final num unallocated = budgetsProv.unallocated;
    final totalBudgetAmount = items
        .map((e) => e.amount)
        .where((v) => v > 0)
        .fold<num>(0, (a, b) => a + b);

    final nf = NumberFormat.decimalPattern(locale);
    final monthLabel = DateFormat.yMMMM(locale).format(_ym);

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFFAFBFE),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Column(
          children: [
            Text(
              t.analyticsTitle,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              monthLabel,
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.4)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? cs.outlineVariant.withOpacity(.1) : const Color(0xFFEEEFF3),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Icon(Icons.calendar_month_rounded, color: cs.primary, size: 22),
              tooltip: t.selectMonth,
              style: IconButton.styleFrom(
                backgroundColor: cs.primary.withOpacity(.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              onPressed: () async {
                final picked = await _pickMonth(context, initial: _ym);
                if (picked != null) {
                  setState(() => _ym = picked);
                  await budgetsProv.loadForMonth(year: _ym.year, month: _ym.month);
                  await _fetchPrediction();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async {
          await Future.wait([
            budgetsProv.loadForMonth(year: _ym.year, month: _ym.month),
            if (!catsProv.loading) catsProv.refresh(),
          ]);
          await _fetchPrediction();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: "Dự báo & Cảnh báo",
              child: _buildPredictionCard(nf),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t.analyticsBudgetSplit,
              child: totalBudgetAmount <= 0
                  ? const _Empty(text: 'Chưa có dữ liệu tháng này')
                  : _BudgetPieChart(items: items, categories: categories),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t.topCategories,
              child: totalBudgetAmount <= 0
                  ? const _Empty(text: 'Chưa có dữ liệu tháng này')
                  : _TopCategoriesList(
                      items: items,
                      categories: categories,
                      number: nf,
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t.summary,
              child: _SummaryBox(
                totalAssigned: totalAssigned,
                totalSpent: totalSpent,
                unallocated: unallocated,
                combinedRemaining: combinedRemaining,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(NumberFormat nf) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingAI) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5)),
      );
    }

    if (_aiError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.error.withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.error.withOpacity(.12)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(_aiError!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
      );
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final currentLabel = DateFormat('MM/yyyy', locale).format(_ym);
    final nextLabel = DateFormat('MM/yyyy', locale).format(DateTime(_ym.year, _ym.month + 1));

    final currentMonthPrediction = (_currentMonthPrediction ?? 0).toDouble();
    final snapshotPrediction = (_snapshotPrediction ?? 0).toDouble();
    final nextMonthPrediction = (_nextMonthPrediction ?? 0).toDouble();
    final warningLimit = (_warningLimit ?? 0).toDouble();
    final spentMtd = (_spentMtd ?? 0).toDouble();

    final mainPrediction = currentMonthPrediction > 0 ? currentMonthPrediction : snapshotPrediction;
    final progress = (_progressPercent.clamp(0, 100)) / 100.0;
    final percentLabel = mainPrediction > 0 ? '${_progressPercent.clamp(0, 100)}%' : '--';

    late Color barColor;
    late Color badgeBg;
    late Color badgeText;

    switch (_predictionStatus) {
      case 'over':
      case 'over_limit':
        barColor = cs.error;
        badgeBg = cs.error.withOpacity(.06);
        badgeText = cs.error;
        break;
      case 'near_limit':
      case 'warning':
        barColor = const Color(0xFFF59E0B);
        badgeBg = const Color(0xFFFFF7ED);
        badgeText = const Color(0xFFB45309);
        break;
      case 'watch':
        barColor = const Color(0xFF2563EB);
        badgeBg = const Color(0xFFEFF6FF);
        badgeText = const Color(0xFF1D4ED8);
        break;
      case 'no_prediction':
      case 'no_data':
        barColor = cs.onSurface.withOpacity(.3);
        badgeBg = isDark ? cs.surfaceContainerHighest.withOpacity(.3) : const Color(0xFFF3F4F6);
        badgeText = cs.onSurface.withOpacity(.6);
        break;
      default:
        barColor = const Color(0xFF2E7D32);
        badgeBg = const Color(0xFFE8F5E9);
        badgeText = const Color(0xFF2E7D32);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Next month prediction
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest.withOpacity(.3) : const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? cs.outlineVariant.withOpacity(.08) : const Color(0xFFECEDF2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cs.primary.withOpacity(.08), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.auto_graph_rounded, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dự báo $nextLabel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(.5))),
                    const SizedBox(height: 2),
                    Text('${nf.format(nextMonthPrediction.round())} đ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: cs.primary.withOpacity(.06), borderRadius: BorderRadius.circular(8)),
                child: Text('Tháng $currentLabel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Warning section
        Text('Cảnh báo $currentLabel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(.6))),
        const SizedBox(height: 4),
        Text(warningLimit > 0 ? 'Mốc: ${nf.format(warningLimit.round())} đ' : 'Mốc: --',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(.35))),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress, minHeight: 10,
            backgroundColor: isDark ? cs.surfaceContainerHighest : const Color(0xFFEEEFF3),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text('Đã chi: ${nf.format(spentMtd.round())} đ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(.4)))),
            Text(percentLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: barColor)),
          ],
        ),
        const SizedBox(height: 12),
        // Status message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeText.withOpacity(.1)),
          ),
          child: Row(
            children: [
              Icon(
                _predictionStatus == 'over' || _predictionStatus == 'over_limit'
                    ? Icons.warning_amber_rounded
                    : _predictionStatus == 'near_limit' || _predictionStatus == 'warning'
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                color: badgeText, size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_statusMessage ?? 'Không có cảnh báo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: badgeText))),
            ],
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickMonth(
    BuildContext context, {
    required DateTime initial,
  }) async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2035, 12),
      headerTitle: const Text(
        'Chọn tháng',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE5E7EB),
        ),
      ),
      monthPickerDialogSettings: const MonthPickerDialogSettings(
        dialogSettings: PickerDialogSettings(
          locale: Locale('vi'),
          dialogRoundedCornersRadius: 24,
          dialogBackgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
        headerSettings: PickerHeaderSettings(
          headerBackgroundColor: Color(0xFF0F766E),
          headerCurrentPageTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFCCFBF1),
          ),
          headerSelectedIntervalTextStyle: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          headerIconsColor: Colors.white,
          previousIcon: Icons.chevron_left_rounded,
          nextIcon: Icons.chevron_right_rounded,
        ),
        dateButtonsSettings: PickerDateButtonsSettings(
          buttonBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          selectedMonthBackgroundColor: Color(0xFF0F766E),
          selectedMonthTextColor: Colors.white,
          unselectedMonthsTextColor: Color(0xFF374151),
          currentMonthTextColor: Color(0xFF0F766E),
          monthTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          yearTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionBarSettings: PickerActionBarSettings(
          actionBarPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          cancelWidget: Text(
            'Huỷ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          confirmWidget: Text(
            'OK',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F766E),
            ),
          ),
        ),
      ),
    );

    if (picked == null) return null;
    return DateTime(picked.year, picked.month);
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.title, required this.child, this.collapsible = true, this.initiallyExpanded = true});
  final String title;
  final Widget child;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        border: Border.all(color: isDark ? cs.outlineVariant.withOpacity(.08) : const Color(0xFFECEDF2)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.collapsible ? () => setState(() => _expanded = !_expanded) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 18,
                    decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  ),
                  if (widget.collapsible)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      turns: _expanded ? 0.0 : 0.5,
                      child: Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: cs.onSurface.withOpacity(.3)),
                    ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(text, style: TextStyle(color: cs.onSurface.withOpacity(.4), fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _BudgetPieChart extends StatelessWidget {
  const _BudgetPieChart({required this.items, required this.categories});
  final List<BudgetItem> items;
  final Map<int, Category> categories;

  static const List<Color> _palette = [
    Color(0xFF2EC4B6), // Mint
    Color(0xFF14B8A6), // Teal
    Color(0xFF0EA5E9), // Light sky
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Orange
    Color(0xFFF43F5E), // Rose
    Color(0xFF10B981), // Emerald
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = items.where((e) => e.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = data.fold<num>(0, (a, b) => a + b.amount);

    int idx = 0;
    final sections = data.map((e) {
      final color = _palette[idx % _palette.length];
      idx++;
      return PieChartSectionData(
        value: e.amount.toDouble(),
        color: color,
        title: '${((e.amount / total) * 100).toStringAsFixed(0)}%',
        radius: 75,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
        borderSide: BorderSide(color: isDark ? cs.surfaceContainerHigh : Colors.white, width: 2),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PieChart(PieChartData(
            sections: sections, sectionsSpace: 0,
            centerSpaceRadius: 40, centerSpaceColor: Colors.transparent,
          )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: data.take(8).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final color = _palette[i % _palette.length];
            final name = categories[e.categoryId]?.name ?? '#${e.categoryId}';
            final pct = total == 0 ? 0 : (e.amount / total) * 100;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('$name (${pct.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? color : cs.onSurface.withOpacity(.8))),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TopCategoriesList extends StatelessWidget {
  const _TopCategoriesList({required this.items, required this.categories, required this.number});
  final List<BudgetItem> items;
  final Map<int, Category> categories;
  final NumberFormat number;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = items.where((e) => e.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      children: data.asMap().entries.map((entry) {
        final idx = entry.key;
        final it = entry.value;
        final color = _BudgetPieChart._palette[idx % _BudgetPieChart._palette.length];
        final name = categories[it.categoryId]?.name ?? 'Danh mục ${it.categoryId}';
        final first = (name.isNotEmpty ? name[0] : '#').toUpperCase();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest.withOpacity(.3) : const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? cs.outlineVariant.withOpacity(.08) : const Color(0xFFECEDF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(first, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface)),
              ),
              Text('${number.format(it.amount)} đ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.totalAssigned, required this.totalSpent, required this.unallocated, required this.combinedRemaining});
  final num totalAssigned;
  final num totalSpent;
  final num unallocated;
  final num combinedRemaining;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nf = NumberFormat.decimalPattern(locale);
    final isOver = combinedRemaining < 0;

    return Row(
      children: [
        Expanded(child: _SummaryTile(label: 'Phân bổ', value: '${nf.format(totalAssigned.round())} đ', icon: Icons.pie_chart_rounded, color: const Color(0xFF2EC4B6))),
        const SizedBox(width: 8),
        Expanded(child: _SummaryTile(label: 'Đã tiêu', value: '${nf.format(totalSpent.round())} đ', icon: Icons.payments_rounded, color: const Color(0xFFF59E0B))),
        const SizedBox(width: 8),
        Expanded(child: _SummaryTile(label: isOver ? 'Vượt' : 'Còn dư', value: '${nf.format(combinedRemaining.abs().round())} đ',
          icon: isOver ? Icons.report_gmailerrorred_rounded : Icons.savings_rounded,
          color: isOver ? cs.error : const Color(0xFF10B981))),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? .1 : .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: cs.onSurface), maxLines: 1),
          ),
        ],
      ),
    );
  }
}
