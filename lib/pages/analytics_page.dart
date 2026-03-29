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
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          children: [
            Text(
              t.analyticsTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              monthLabel,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: t.selectMonth,
            onPressed: () async {
              final picked = await _pickMonth(context, initial: _ym);
              if (picked != null) {
                setState(() => _ym = picked);
                await budgetsProv.loadForMonth(
                  year: _ym.year,
                  month: _ym.month,
                );
                await _fetchPrediction();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
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
    if (_loadingAI) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_aiError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _aiError!,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final currentLabel = DateFormat('MM/yyyy', locale).format(_ym);
    final nextLabel =
        DateFormat('MM/yyyy', locale).format(DateTime(_ym.year, _ym.month + 1));

    final currentMonthPrediction = (_currentMonthPrediction ?? 0).toDouble();
    final snapshotPrediction = (_snapshotPrediction ?? 0).toDouble();
    final nextMonthPrediction = (_nextMonthPrediction ?? 0).toDouble();
    final warningLimit = (_warningLimit ?? 0).toDouble();
    final spentMtd = (_spentMtd ?? 0).toDouble();

    final mainPrediction = currentMonthPrediction > 0
        ? currentMonthPrediction
        : snapshotPrediction;

    final progress = (_progressPercent.clamp(0, 100)) / 100.0;
    final percentLabel =
        mainPrediction > 0 ? '${_progressPercent.clamp(0, 100)}%' : '--';

    late Color barColor;
    late Color badgeBg;
    late Color badgeText;

    switch (_predictionStatus) {
      case 'over':
      case 'over_limit':
        barColor = const Color(0xFFEF4444);
        badgeBg = const Color(0xFFFDECEC);
        badgeText = const Color(0xFFD93025);
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
        barColor = const Color(0xFF9CA3AF);
        badgeBg = const Color(0xFFF3F4F6);
        badgeText = const Color(0xFF4B5563);
        break;
      default:
        barColor = const Color(0xFF16A34A);
        badgeBg = const Color(0xFFECFDF5);
        badgeText = const Color(0xFF047857);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dự báo & Cảnh báo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Tháng $currentLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Dự báo $nextLabel',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              Text(
                'đ ${nf.format(nextMonthPrediction.round())}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cảnh báo $currentLabel',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              Text(
                warningLimit > 0
                    ? 'Mốc: đ ${nf.format(warningLimit.round())}'
                    : 'Mốc: --',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đã chi hiện tại: đ ${nf.format(spentMtd.round())}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Text(
                percentLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _statusMessage ?? 'Không có cảnh báo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
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
  const _SectionCard({
    required this.title,
    required this.child,
    this.collapsible = true,
    this.initiallyExpanded = true,
  });

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F6FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.collapsible
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.collapsible)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      turns: _expanded ? 0.0 : 0.5,
                      child: const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(text)),
    );
  }
}

class _BudgetPieChart extends StatelessWidget {
  const _BudgetPieChart({
    required this.items,
    required this.categories,
  });

  final List<BudgetItem> items;
  final Map<int, Category> categories;

  @override
  Widget build(BuildContext context) {
    final data = items.where((e) => e.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final total = data.fold<num>(0, (a, b) => a + b.amount);

    final sections = data
        .map(
          (e) => PieChartSectionData(
            value: e.amount.toDouble(),
            title: '${((e.amount / total) * 100).toStringAsFixed(0)}%',
            radius: 70,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
        .toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              centerSpaceColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: data.take(8).map((e) {
            final name = categories[e.categoryId]?.name ?? '#${e.categoryId}';
            final pct = total == 0 ? 0 : (e.amount / total) * 100;

            return Chip(
              label: Text('$name (${pct.toStringAsFixed(0)}%)'),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.indigo.withOpacity(.06),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TopCategoriesList extends StatelessWidget {
  const _TopCategoriesList({
    required this.items,
    required this.categories,
    required this.number,
  });

  final List<BudgetItem> items;
  final Map<int, Category> categories;
  final NumberFormat number;

  @override
  Widget build(BuildContext context) {
    final data = items.where((e) => e.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      children: data
          .map(
            (it) => ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.withOpacity(.08),
                child: Text(
                  (categories[it.categoryId]?.name ?? '#')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              title: Text(
                categories[it.categoryId]?.name ?? 'Danh mục ${it.categoryId}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                'đ ${number.format(it.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.totalAssigned,
    required this.totalSpent,
    required this.unallocated,
    required this.combinedRemaining,
  });

  final num totalAssigned;
  final num totalSpent;
  final num unallocated;
  final num combinedRemaining;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nf = NumberFormat.decimalPattern(locale);
    final isOver = combinedRemaining < 0;
    final color = isOver ? Colors.red : Colors.green;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _SummaryTile(
            label: "Đã phân bổ",
            value: 'đ ${nf.format(totalAssigned)}',
            icon: Icons.pie_chart_rounded,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: "Đã tiêu",
            value: 'đ ${nf.format(totalSpent)}',
            icon: Icons.payments_rounded,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: isOver ? "Vượt" : "Còn dư",
            value: 'đ ${nf.format(combinedRemaining.abs())}',
            icon: isOver
                ? Icons.report_gmailerrorred_rounded
                : Icons.savings_rounded,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
