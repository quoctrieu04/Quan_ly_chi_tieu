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
import 'package:chitieu/financial_transaction/financial_transaction_provider.dart';
import 'package:chitieu/pages/setting/settings_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/widgets/app_page_header.dart';
import 'package:chitieu/widgets/app_month_picker_sheet.dart';
import 'package:chitieu/pages/note_page.dart';
import 'package:chitieu/utils/error_handler.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

enum _PredictionViewMode { week, month }

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _ym = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedWeekStart = _startOfWeek(DateTime.now());
  _PredictionViewMode _predictionViewMode = _PredictionViewMode.week;

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

  bool _weeklyLoaded = false;
  bool _loadingWeekly = false;
  double? _currentWeekPrediction;
  double? _nextWeekPrediction;
  double? _weeklyWarningLimit;
  double? _spentWtd;
  int _weeklyProgressPercent = 0;
  String? _weeklyStatus;
  String? _weeklyMessage;
  String? _weeklyTargetLabel;
  String? _weeklyNextStart;
  String? _weeklyNextEnd;
  Map<int, num> _previousMonthSpentByCategory = {};
  Map<int, num> _previousWeekSpentByCategory = {};

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
      final ft = context.read<FinancialTransactionProvider>();

      final futures = <Future<void>>[
        b.loadForMonth(year: _ym.year, month: _ym.month),
        ft.fetchByMonth(year: _ym.year, month: _ym.month),
      ];

      if (!c.loading && c.items.isEmpty) {
        futures.add(c.refresh());
      }

      await Future.wait(futures);
      await _fetchPreviousMonthCategorySpending();
      await _fetchPreviousWeekCategorySpending();
      await _fetchPrediction();
      await _fetchWeeklyPrediction();
    });
  }

  Future<void> _fetchPreviousMonthCategorySpending() async {
    try {
      final previous = DateTime(_ym.year, _ym.month - 1);
      final service = context.read<BudgetsProvider>().service;
      final spent = await service.getSpentByCategory(
        year: previous.year,
        month: previous.month,
      );

      _safeSetState(() {
        _previousMonthSpentByCategory = spent;
      });
    } catch (e) {
      debugPrint('fetchPreviousMonthCategorySpending FAILED: $e');
      _safeSetState(() {
        _previousMonthSpentByCategory = {};
      });
    }
  }

  Future<void> _fetchPreviousWeekCategorySpending() async {
    try {
      final previousWeekStart =
          _selectedWeekStart.subtract(const Duration(days: 7));
      final service = context.read<BudgetsProvider>().service;
      final spent = await service.getSpentByCategory(
        year: previousWeekStart.year,
        month: previousWeekStart.month,
        weekStart: _formatApiDate(previousWeekStart),
      );

      _safeSetState(() {
        _previousWeekSpentByCategory = spent;
      });
    } catch (e) {
      debugPrint('fetchPreviousWeekCategorySpending FAILED: $e');
      _safeSetState(() {
        _previousWeekSpentByCategory = {};
      });
    }
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
            : getFriendlyError(e.response?.data ?? e);
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

  Future<void> _fetchWeeklyPrediction() async {
    try {
      _safeSetState(() {
        _loadingWeekly = true;
      });

      final dio = context.read<Dio>();

      final res = await dio.get(
        'predict/weekly-status',
        queryParameters: {
          'week_start': _formatApiDate(_selectedWeekStart),
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
        _weeklyLoaded = true;
        _currentWeekPrediction = toDouble(data['current_week_prediction']);
        _nextWeekPrediction = toDouble(data['next_week_prediction']);
        _weeklyWarningLimit = toDouble(data['warning_limit']);
        _spentWtd = toDouble(data['spent_wtd']);
        _weeklyProgressPercent =
            (data['progress_percent'] as num?)?.round() ?? 0;
        _weeklyStatus = (data['status'] ?? 'ok').toString();
        _weeklyMessage = (data['message'] ?? '').toString();
        _weeklyTargetLabel = (data['target_label'] ?? '').toString();
        _weeklyNextStart = (data['next_week_start'] ?? '').toString();
        _weeklyNextEnd = (data['next_week_end'] ?? '').toString();
        _loadingWeekly = false;
      });
    } catch (e) {
      debugPrint('predict/weekly-status FAILED: $e');
      _safeSetState(() {
        _weeklyLoaded = false;
        _loadingWeekly = false;
      });
    }
  }

  Future<void> _reloadSelectedPeriod({
    bool reloadMonthData = false,
  }) async {
    _safeSetState(() {
      _weeklyLoaded = false;
      _loadingWeekly = true;
    });

    if (reloadMonthData) {
      final budgetsProv = context.read<BudgetsProvider>();
      final ftProv = context.read<FinancialTransactionProvider>();

      await Future.wait([
        budgetsProv.loadForMonth(year: _ym.year, month: _ym.month),
        ftProv.fetchByMonth(year: _ym.year, month: _ym.month),
      ]);
      await _fetchPrediction();
      await _fetchPreviousMonthCategorySpending();
    }

    await _fetchPreviousWeekCategorySpending();
    await _fetchWeeklyPrediction();
  }

  Future<void> _setSelectedWeek(DateTime weekStart) async {
    final normalized = _startOfWeek(weekStart);
    final nextMonth = DateTime(normalized.year, normalized.month);
    final monthChanged = nextMonth.year != _ym.year || nextMonth.month != _ym.month;

    setState(() {
      _selectedWeekStart = normalized;
      if (monthChanged) {
        _ym = nextMonth;
      }
    });

    await _reloadSelectedPeriod(reloadMonthData: monthChanged);
  }

  Future<void> _shiftSelectedWeek(int delta) async {
    await _setSelectedWeek(_selectedWeekStart.add(Duration(days: delta * 7)));
  }

  @override
  Widget build(BuildContext context) {
    // Ép AnalyticsPage luôn build lại khi thay đổi màu chủ đạo ở SettingsProvider
    context.watch<SettingsProvider>();

    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final budgetsProv = context.watch<BudgetsProvider>();
    final catsProv = context.watch<CategoryProvider>();
    final ftProv = context.watch<FinancialTransactionProvider>();
    final items = budgetsProv.items;
    final categories = {for (final c in catsProv.items) c.id: c};

    final totalAssigned = budgetsProv.totalAssigned;
    final num totalIncome = ftProv.totalIncome;
    final num totalSpent = ftProv.totalExpense;
    final num totalBudgetSpent =
        items.fold<num>(0, (sum, item) => sum + item.spent);
    final num monthRemaining = totalIncome - totalSpent;
    final num budgetRemaining = totalAssigned - totalBudgetSpent;
    final totalBudgetAmount = items
        .map((e) => e.amount)
        .where((v) => v > 0)
        .fold<num>(0, (a, b) => a + b);
    final hasTransactions = totalIncome > 0 || totalSpent > 0;
    final hasBudgetPlan = totalAssigned > 0;

    final nf = NumberFormat.decimalPattern(locale);
    final monthLabel = DateFormat.yMMMM(locale).format(_ym);
    final selectedWeekLabel = _formatSelectedWeekRange();
    Future<void> openMonthPicker() async {
      final picked = await _pickMonth(context, initial: _ym);
      if (picked != null) {
        final nextWeek = _startOfWeek(picked);
        setState(() {
          _ym = picked;
          _selectedWeekStart = nextWeek;
        });
        await Future.wait([
          budgetsProv.loadForMonth(
            year: _ym.year,
            month: _ym.month,
          ),
          ftProv.fetchByMonth(year: _ym.year, month: _ym.month),
        ]);
        await _fetchPreviousMonthCategorySpending();
        await _fetchPreviousWeekCategorySpending();
        await _fetchPrediction();
        await _fetchWeeklyPrediction();
      }
    }

    Future<void> openWeekPicker() async {
      final picked = await _pickWeek(context, initial: _selectedWeekStart);
      if (picked != null) {
        await _setSelectedWeek(picked);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      appBar: AppPageHeaderBar(
        icon: Icons.analytics_outlined,
        title: t.analyticsTitle,
        subtitle: '$selectedWeekLabel • $monthLabel',
        onTap: openWeekPicker,
        actions: [
          HeaderIconButton(
            icon: Icons.date_range_rounded,
            tooltip: 'Chọn tuần',
            onPressed: openWeekPicker,
          ),
          HeaderIconButton(
            icon: Icons.calendar_month_rounded,
            tooltip: t.selectMonth,
            onPressed: openMonthPicker,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            budgetsProv.loadForMonth(year: _ym.year, month: _ym.month),
            ftProv.fetchByMonth(year: _ym.year, month: _ym.month),
            if (!catsProv.loading) catsProv.refresh(),
          ]);
          await _fetchPreviousMonthCategorySpending();
          await _fetchPreviousWeekCategorySpending();
          await _fetchPrediction();
          await _fetchWeeklyPrediction();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _SectionCard(
              title: t.predictionAndWarning,
              child: _buildPredictionInsightCard(nf, t, items, categories),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t.analyticsBudgetSplit,
              child: totalBudgetAmount <= 0
                  ? _AnalyticsEmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: hasTransactions
                          ? 'Chưa có kế hoạch theo danh mục'
                          : 'Chưa có dữ liệu tháng này',
                      message: hasTransactions
                          ? 'Bạn đã có giao dịch, nhưng chưa đặt ngân sách cho danh mục. Hãy cấp ngân sách để biểu đồ phân bổ có ý nghĩa hơn.'
                          : 'Nhập một vài giao dịch và đặt ngân sách để xem tiền được phân bổ theo từng danh mục.',
                      actionText: 'Thêm giao dịch',
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotePage()),
                        );
                      },
                    )
                  : _BudgetPieChart(items: items, categories: categories),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t.summary,
              child: _SummaryBox(
                totalIncome: totalIncome,
                totalAssigned: totalAssigned,
                totalSpent: totalSpent,
                monthRemaining: monthRemaining,
                budgetRemaining: budgetRemaining,
                hasBudgetPlan: hasBudgetPlan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showLegacyPredictionCard => false;

  Widget _buildWeeklyPredictionInsightCard(
    NumberFormat nf,
    AppLocalizations t,
    List<BudgetItem> budgetItems,
    Map<int, Category> categories,
  ) {
    final nextWeekPrediction = (_nextWeekPrediction ?? 0).toDouble();
    final currentWeekPrediction = (_currentWeekPrediction ?? 0).toDouble();
    final warningLimit = (_weeklyWarningLimit ?? 0).toDouble();
    final spentWtd = (_spentWtd ?? 0).toDouble();

    final hasWeeklyData = !_isNoPredictionStatus(_weeklyStatus) &&
        (nextWeekPrediction > 0 ||
            currentWeekPrediction > 0 ||
            warningLimit > 0);

    if (!hasWeeklyData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeekSelectorBar(
            label: _formatSelectedWeekRange(),
            onPrevious: () => _shiftSelectedWeek(-1),
            onNext: () => _shiftSelectedWeek(1),
            onTap: () async {
              final picked = await _pickWeek(
                context,
                initial: _selectedWeekStart,
              );
              if (picked != null) {
                await _setSelectedWeek(picked);
              }
            },
          ),
          const SizedBox(height: 12),
          _AnalyticsEmptyState(
            icon: Icons.insights_rounded,
            title: t.notEnoughDataTitle,
            message:
                (_weeklyMessage != null && _weeklyMessage!.trim().isNotEmpty)
                    ? _weeklyMessage!
                    : t.notEnoughDataDesc,
          ),
        ],
      );
    }

    late Color barColor;
    late Color badgeBg;
    late Color badgeText;

    switch (_weeklyStatus) {
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
      default:
        barColor = const Color(0xFF16A34A);
        badgeBg = const Color(0xFFECFDF5);
        badgeText = const Color(0xFF047857);
        break;
    }

    final isOver = _weeklyStatus == 'over' || _weeklyStatus == 'over_limit';
    final isWarning =
        _weeklyStatus == 'near_limit' || _weeklyStatus == 'warning';
    final statusLabel = isOver
        ? 'Vượt mốc'
        : isWarning
            ? 'Cần chú ý'
            : (_weeklyStatus == 'watch')
                ? 'Theo dõi'
                : 'An toàn';

    final progress = (_weeklyProgressPercent.clamp(0, 100)) / 100.0;
    final spentLabel = nf.format(spentWtd.round());
    final insightText = _weeklyHistoryWarningText(
      _previousWeekSpentByCategory,
      categories,
      nf,
      fallback: 'Chưa có dữ liệu chi tiêu tuần trước để đưa ra cảnh báo.',
    );
    final currentLabel =
        (_weeklyTargetLabel != null && _weeklyTargetLabel!.trim().isNotEmpty)
            ? _weeklyTargetLabel!
            : 'tuần này';
    final nextLabel = _formatWeekRange(_weeklyNextStart, _weeklyNextEnd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeekSelectorBar(
          label: _formatSelectedWeekRange(),
          onPrevious: () => _shiftSelectedWeek(-1),
          onNext: () => _shiftSelectedWeek(1),
          onTap: () async {
            final picked = await _pickWeek(
              context,
              initial: _selectedWeekStart,
            );
            if (picked != null) {
              await _setSelectedWeek(picked);
            }
          },
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PredictionMiniCard(
                  label: 'DỰ ĐOÁN $nextLabel',
                  value: nextWeekPrediction > 0
                      ? nf.format(nextWeekPrediction.round())
                      : '--',
                  caption: 'Ước chi tuần sau',
                  color: const Color(0xFF2F73B8),
                  footerIcon: Icons.trending_up_rounded,
                  footerText: statusLabel,
                  footerColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PredictionMiniCard(
                  label: 'DỰ CHI $currentLabel',
                  value: currentWeekPrediction > 0
                      ? nf.format(currentWeekPrediction.round())
                      : '--',
                  caption: 'Ước chi tuần này',
                  color: isOver
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF2F73B8),
                  progress: progress,
                  progressColor: barColor,
                  footerIcon:
                      isOver ? Icons.warning_rounded : Icons.shield_rounded,
                  footerText: 'Đã chi $spentLabel',
                  footerColor: barColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showWarningDialog(insightText),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isOver ? Icons.warning_rounded : Icons.shield_rounded,
                color: badgeText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: badgeText,
                    ),
                    children: [
                      const TextSpan(text: 'Cảnh báo: '),
                      TextSpan(text: insightText),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionInsightCard(
    NumberFormat nf,
    AppLocalizations t,
    List<BudgetItem> budgetItems,
    Map<int, Category> categories,
  ) {
    final isWeekMode = _predictionViewMode == _PredictionViewMode.week;

    Widget content;
    if (isWeekMode) {
      if (_loadingWeekly && !_weeklyLoaded) {
        content = const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (_weeklyLoaded) {
        content =
            _buildWeeklyPredictionInsightCard(nf, t, budgetItems, categories);
      } else {
        content = _AnalyticsEmptyState(
          icon: Icons.insights_rounded,
          title: t.notEnoughDataTitle,
          message: (_weeklyMessage != null && _weeklyMessage!.trim().isNotEmpty)
              ? _weeklyMessage!
              : t.notEnoughDataDesc,
        );
      }
    } else {
      content = _buildMonthlyPredictionInsightCard(
        nf,
        t,
        budgetItems,
        categories,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PredictionModeSelector(
          value: _predictionViewMode,
          onChanged: (value) => setState(() => _predictionViewMode = value),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildMonthlyPredictionInsightCard(
    NumberFormat nf,
    AppLocalizations t,
    List<BudgetItem> budgetItems,
    Map<int, Category> categories,
  ) {
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
          color: Colors.red.withValues(alpha: .08),
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

    final nextMonthPrediction = (_nextMonthPrediction ?? 0).toDouble();
    final currentMonthPrediction = (_currentMonthPrediction ?? 0).toDouble();
    final snapshotPrediction = (_snapshotPrediction ?? 0).toDouble();
    final warningLimit = (_warningLimit ?? 0).toDouble();
    final spentMtd = (_spentMtd ?? 0).toDouble();
    final mainPrediction = currentMonthPrediction > 0
        ? currentMonthPrediction
        : snapshotPrediction;
    final hasPredictionData = nextMonthPrediction > 0 ||
        currentMonthPrediction > 0 ||
        snapshotPrediction > 0 ||
        warningLimit > 0;

    if (!hasPredictionData) {
      return _AnalyticsEmptyState(
        icon: Icons.insights_rounded,
        title: t.notEnoughDataTitle,
        message: t.notEnoughDataDesc,
      );
    }

    final currentPredictionValue = mainPrediction;
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

    final isOver =
        _predictionStatus == 'over' || _predictionStatus == 'over_limit';
    final isWarning =
        _predictionStatus == 'near_limit' || _predictionStatus == 'warning';
    final hasCurrentMonthLimit = warningLimit > 0;
    final statusLabel = isOver
        ? 'Vượt mốc'
        : isWarning
            ? 'Cần chú ý'
            : (_predictionStatus == 'watch')
                ? 'Theo dõi'
                : hasCurrentMonthLimit
                    ? 'An toàn'
                    : 'Chưa có mốc';
    final spentLabel = nf.format(spentMtd.round());
    final limitSummary = warningLimit > 0
        ? '${nf.format(spentMtd.round())} / ${nf.format(warningLimit.round())}'
        : '${nf.format(spentMtd.round())} / --';
    final insightText = _monthlyHistoryWarningText(
      _previousMonthSpentByCategory,
      budgetItems,
      categories,
      nf,
      fallback: 'Chưa có dữ liệu chi tiêu tháng trước để đưa ra cảnh báo.',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PredictionMiniCard(
                  label: 'DỰ ĐOÁN $nextLabel',
                  value: nf.format(nextMonthPrediction.round()),
                  caption: 'Ước chi tháng tới',
                  color: const Color(0xFF2F73B8),
                  footerIcon: Icons.trending_up_rounded,
                  footerText: statusLabel,
                  footerColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PredictionMiniCard(
                  label: 'DỰ CHI $currentLabel',
                  value: currentPredictionValue > 0
                      ? nf.format(currentPredictionValue.round())
                      : '--',
                  caption: 'Ước chi tháng này',
                  color: isOver
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF2F73B8),
                  progress: progress,
                  progressColor: barColor,
                  footerIcon:
                      isOver ? Icons.warning_rounded : Icons.shield_rounded,
                  footerText: hasCurrentMonthLimit
                      ? 'Đã chi $spentLabel'
                      : 'Chưa có mốc',
                  footerColor: barColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showWarningDialog(insightText),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isOver ? Icons.warning_rounded : Icons.shield_rounded,
                color: badgeText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: badgeText,
                    ),
                    children: [
                      const TextSpan(text: 'Cảnh báo: '),
                      TextSpan(text: insightText),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
        if (_showLegacyPredictionCard) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dự báo $nextLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOver ? Icons.error_rounded : Icons.check_circle_rounded,
                      color: badgeText,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    nf.format(nextMonthPrediction.round()),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primaryDark,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cảnh báo mức chi $currentLabel',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                    Text(
                      percentLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã chi / Mốc cảnh báo: $limitSummary',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(color: barColor.withValues(alpha: .86)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOver ? Icons.warning_rounded : Icons.shield_rounded,
                        color: badgeText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insightText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: badgeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _categoryWarningText(
    List<BudgetItem> budgetItems,
    Map<int, Category> categories,
    NumberFormat nf, {
    required String fallback,
  }) {
    final items = budgetItems.where((item) => item.spent > 0).toList();

    if (items.isEmpty) {
      return fallback;
    }

    String categoryName(BudgetItem item) {
      final name = item.name?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }

      final category = categories[item.categoryId];
      if (category != null && category.name.trim().isNotEmpty) {
        return category.name;
      }

      return 'Danh mục #${item.categoryId}';
    }

    final overBudget = items.where((item) {
      return item.amount > 0 && item.spent > item.amount;
    }).toList()
      ..sort((a, b) => (b.spent - b.amount).compareTo(a.spent - a.amount));

    if (overBudget.isNotEmpty) {
      final item = overBudget.first;
      final overAmount = item.spent - item.amount;
      return '${categoryName(item)} đã vượt kế hoạch '
          '${nf.format(overAmount)}. Nên giảm chi ở danh mục này.';
    }

    final nearLimit = items.where((item) {
      if (item.amount <= 0) return false;
      return item.spent / item.amount >= 0.8;
    }).toList()
      ..sort((a, b) {
        final bp = b.amount <= 0 ? 0.0 : b.spent / b.amount;
        final ap = a.amount <= 0 ? 0.0 : a.spent / a.amount;
        return bp.compareTo(ap);
      });

    if (nearLimit.isNotEmpty) {
      final item = nearLimit.first;
      final percent = ((item.spent / item.amount) * 100).round();
      return '${categoryName(item)} đã dùng $percent% kế hoạch '
          '(${nf.format(item.spent)} / ${nf.format(item.amount)}).';
    }

    items.sort((a, b) => b.spent.compareTo(a.spent));
    final top = items.first;

    if (top.amount > 0) {
      return '${categoryName(top)} đang chi nhiều nhất: '
          '${nf.format(top.spent)} trên kế hoạch ${nf.format(top.amount)}.';
    }

    return '${categoryName(top)} đang chi nhiều nhất: ${nf.format(top.spent)}.';
  }

  String _spendingRiskWarningText(
    List<BudgetItem> budgetItems,
    Map<int, Category> categories,
    NumberFormat nf, {
    required String fallback,
  }) {
    final items = budgetItems.where((item) => item.spent > 0).toList();

    if (items.isEmpty) {
      return fallback;
    }

    String categoryName(BudgetItem item) {
      final name = item.name?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }

      final category = categories[item.categoryId];
      if (category != null && category.name.trim().isNotEmpty) {
        return category.name;
      }

      return 'Danh mục #${item.categoryId}';
    }

    final overBudget = items.where((item) {
      return item.amount > 0 && item.spent > item.amount;
    }).toList()
      ..sort((a, b) => (b.spent - b.amount).compareTo(a.spent - a.amount));

    if (overBudget.isNotEmpty) {
      final item = overBudget.first;
      final overAmount = item.spent - item.amount;
      return '${categoryName(item)} đang vượt kế hoạch '
          '${nf.format(overAmount)}. Bạn nên hạn chế thêm khoản chi '
          'ở nhóm này trong thời gian tới.';
    }

    final nearLimit = items.where((item) {
      if (item.amount <= 0) return false;
      return item.spent / item.amount >= 0.8;
    }).toList()
      ..sort((a, b) {
        final bp = b.amount <= 0 ? 0.0 : b.spent / b.amount;
        final ap = a.amount <= 0 ? 0.0 : a.spent / a.amount;
        return bp.compareTo(ap);
      });

    if (nearLimit.isNotEmpty) {
      final item = nearLimit.first;
      final percent = ((item.spent / item.amount) * 100).round();
      return '${categoryName(item)} đã dùng $percent% kế hoạch. '
          'Nếu tiếp tục chi như hiện tại, danh mục này có thể sớm vượt '
          'mức bạn đã đặt.';
    }

    items.sort((a, b) => b.spent.compareTo(a.spent));
    final top = items.first;
    final totalSpent = items.fold<int>(0, (sum, item) => sum + item.spent);
    final topShare = totalSpent > 0 ? top.spent / totalSpent : 0.0;

    if (topShare >= 0.4 && items.length > 1) {
      return 'Chi tiêu đang tập trung nhiều vào ${categoryName(top)}. '
          'Bạn nên theo dõi nhóm này để tránh làm lệch kế hoạch '
          'chi tiêu trong thời gian tới.';
    }

    return 'Chi tiêu hiện vẫn khá ổn định. Chưa có danh mục nào '
        'gây áp lực rõ rệt lên kế hoạch của bạn.';
  }

  String _monthlyHistoryWarningText(
    Map<int, num> previousMonthSpent,
    List<BudgetItem> currentBudgetItems,
    Map<int, Category> categories,
    NumberFormat nf, {
    required String fallback,
  }) {
    final entries = previousMonthSpent.entries
        .where((entry) => entry.key > 0 && entry.value > 0)
        .toList();

    if (entries.isEmpty) {
      return fallback;
    }

    entries.sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first;
    final totalPreviousSpent =
        entries.fold<num>(0, (sum, entry) => sum + entry.value);
    final topShare =
        totalPreviousSpent > 0 ? top.value / totalPreviousSpent : 0.0;
    final currentBudget = currentBudgetItems
        .where((item) => item.categoryId == top.key)
        .map((item) => item.amount)
        .fold<int>(0, (sum, amount) => sum + amount);

    String categoryName(int categoryId) {
      final category = categories[categoryId];
      if (category != null && category.name.trim().isNotEmpty) {
        return category.name;
      }

      BudgetItem? currentItem;
      for (final item in currentBudgetItems) {
        if (item.categoryId == categoryId) {
          currentItem = item;
          break;
        }
      }

      final itemName = currentItem?.name?.trim();
      if (itemName != null && itemName.isNotEmpty) {
        return itemName;
      }

      return 'Danh mục #$categoryId';
    }

    final name = categoryName(top.key);
    final spentLabel = nf.format(top.value.round());

    if (currentBudget > 0 && top.value > currentBudget) {
      return 'Tháng trước bạn chi $spentLabel cho $name, cao hơn kế hoạch '
          'tháng này. Nên để ý nhóm này sớm để tránh vượt ngân sách.';
    }

    if (topShare >= 0.4 && entries.length > 1) {
      return 'Tháng trước, $name là khoản chi nổi bật nhất với $spentLabel. '
          'Tháng này bạn nên theo dõi nhóm này kỹ hơn.';
    }

    return 'Dựa trên tháng trước, chi tiêu chưa tập trung quá mạnh vào một '
        'danh mục nào. Bạn vẫn nên theo dõi các khoản phát sinh lớn.';
  }

  String _weeklyHistoryWarningText(
    Map<int, num> previousWeekSpent,
    Map<int, Category> categories,
    NumberFormat nf, {
    required String fallback,
  }) {
    final entries = previousWeekSpent.entries
        .where((entry) => entry.key > 0 && entry.value > 0)
        .toList();

    if (entries.isEmpty) {
      return fallback;
    }

    entries.sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first;
    final totalPreviousSpent =
        entries.fold<num>(0, (sum, entry) => sum + entry.value);
    final topShare =
        totalPreviousSpent > 0 ? top.value / totalPreviousSpent : 0.0;

    String categoryName(int categoryId) {
      final category = categories[categoryId];
      if (category != null && category.name.trim().isNotEmpty) {
        return category.name;
      }

      return 'Danh mục #$categoryId';
    }

    final name = categoryName(top.key);
    final spentLabel = nf.format(top.value.round());

    if (topShare >= 0.4 && entries.length > 1) {
      return 'Tuần trước, $name là khoản chi nổi bật nhất với $spentLabel. '
          'Tuần này bạn nên theo dõi nhóm này kỹ hơn.';
    }

    return 'Tuần trước chi tiêu chưa tập trung quá mạnh vào một danh mục nào. '
        'Bạn vẫn nên chú ý các khoản phát sinh bất thường trong tuần này.';
  }

  Future<DateTime?> _pickMonth(
    BuildContext context, {
    required DateTime initial,
  }) async {
    final picked = await showAppMonthPicker(
      context: context,
      initial: initial,
      min: DateTime(2020, 1),
      max: DateTime(2035, 12),
    );

    if (picked == null) return null;
    return DateTime(picked.year, picked.month);
  }

  Future<DateTime?> _pickWeek(
    BuildContext context, {
    required DateTime initial,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeekPickerSheet(initial: initial),
    );
  }

  String _formatSelectedWeekRange() {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = _selectedWeekStart;
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('dd/MM', locale).format(start)} - ${DateFormat('dd/MM', locale).format(end)}';
  }

  static DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - DateTime.monday));
  }

  static String _formatApiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatWeekRange(String? startRaw, String? endRaw) {
    final start = startRaw == null ? null : DateTime.tryParse(startRaw);
    final end = endRaw == null ? null : DateTime.tryParse(endRaw);

    if (start == null || end == null) {
      return 'tuần sau';
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    return '${DateFormat('dd/MM', locale).format(start)} - ${DateFormat('dd/MM', locale).format(end)}';
  }

  bool _isNoPredictionStatus(String? status) {
    return status == 'no_prediction' ||
        status == 'no_data' ||
        status == 'insufficient_data';
  }

  void _showWarningDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cảnh báo chi tiêu',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF475467),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PredictionModeSelector extends StatelessWidget {
  const _PredictionModeSelector({
    required this.value,
    required this.onChanged,
  });

  final _PredictionViewMode value;
  final ValueChanged<_PredictionViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFEFF4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PredictionModeSegment(
            icon: Icons.calendar_view_week_rounded,
            label: 'Tuần',
            selected: value == _PredictionViewMode.week,
            onTap: () => onChanged(_PredictionViewMode.week),
          ),
          const SizedBox(width: 4),
          _PredictionModeSegment(
            icon: Icons.calendar_month_rounded,
            label: 'Tháng',
            selected: value == _PredictionViewMode.month,
            onTap: () => onChanged(_PredictionViewMode.month),
          ),
        ],
      ),
    );
  }
}

class _PredictionModeSegment extends StatelessWidget {
  const _PredictionModeSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final selectedColor = isDark ? Colors.white : AppColors.primaryDark;
    final idleColor = isDark ? Colors.white70 : const Color(0xFF667085);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          decoration: BoxDecoration(
            color: selected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? selectedColor : idleColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: selected ? selectedColor : idleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekSelectorBar extends StatelessWidget {
  const _WeekSelectorBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return Row(
      children: [
        _WeekNavButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrevious,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tuần $label',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _WeekNavButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  const _WeekNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF111827) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
      ),
    );
  }
}

class _WeekPickerSheet extends StatefulWidget {
  const _WeekPickerSheet({required this.initial});

  final DateTime initial;

  @override
  State<_WeekPickerSheet> createState() => _WeekPickerSheetState();
}

class _WeekPickerSheetState extends State<_WeekPickerSheet> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.initial.year, widget.initial.month);
  }

  List<DateTime> _weeksForVisibleMonth() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final lastDay = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final firstWeek = _AnalyticsPageState._startOfWeek(firstDay);
    final weeks = <DateTime>[];

    for (var week = firstWeek;
        !week.isAfter(lastDay);
        week = week.add(const Duration(days: 7))) {
      weeks.add(week);
    }

    return weeks;
  }

  String _weekRangeLabel(DateTime start) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('dd/MM', locale).format(start)} - ${DateFormat('dd/MM', locale).format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final nowWeek = _AnalyticsPageState._startOfWeek(DateTime.now());
    final selectedWeek = _AnalyticsPageState._startOfWeek(widget.initial);
    final weeks = _weeksForVisibleMonth();
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
                color: const Color(0xFF111827),
                iconSize: 26,
                splashRadius: 22,
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
                color: const Color(0xFF111827),
                iconSize: 26,
                splashRadius: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: weeks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final week = weeks[index];
                final selected = week == selectedWeek;
                final current = week == nowWeek;
                final label = _weekRangeLabel(week);

                Color background = Colors.white;
                Color border = const Color(0xFFE5E7EB);
                Color foreground = const Color(0xFF111827);

                if (selected) {
                  background = AppColors.primaryLight;
                  border = AppColors.primary;
                  foreground = AppColors.primaryDark;
                } else if (current) {
                  background = AppColors.primarySurface;
                  border = AppColors.border;
                  foreground = AppColors.primaryDark;
                }

                return Material(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, week),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            current
                                ? Icons.today_rounded
                                : Icons.date_range_rounded,
                            color: foreground,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tuần $label',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_rounded,
                              color: AppColors.primaryDark,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionMiniCard extends StatelessWidget {
  const _PredictionMiniCard({
    required this.label,
    required this.value,
    required this.color,
    required this.footerIcon,
    required this.footerText,
    required this.footerColor,
    this.caption,
    this.footerSubtext,
    this.progress,
    this.progressColor,
  });

  final String label;
  final String value;
  final Color color;
  final IconData footerIcon;
  final String footerText;
  final Color footerColor;
  final String? caption;
  final String? footerSubtext;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.05,
                color: color,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (progress != null) ...[
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE7ECF3),
                borderRadius: BorderRadius.circular(999),
              ),
              clipBehavior: Clip.antiAlias,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress!.clamp(0.0, 1.0),
                  child: Container(color: progressColor ?? footerColor),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(footerIcon, size: 15, color: footerColor),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      footerText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: footerColor,
                      ),
                    ),
                    if (footerSubtext != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        footerSubtext!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: footerColor.withValues(alpha: .82),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.darkSurface : null,
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF4F6FF)],
              ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (widget.collapsible)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      turns: _expanded ? 0.0 : 0.5,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 22,
                        color: isDark ? Colors.white70 : Colors.black54,
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

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.secondaryText,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2530) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: isDark ? Colors.white70 : const Color(0xFF667085),
            ),
          ),
          if (secondaryText != null) ...[
            const SizedBox(height: 6),
            Text(
              secondaryText!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475467),
              ),
            ),
          ],
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 14),
            _SmallActionButton(
              icon: Icons.add_rounded,
              label: actionText!,
              onPressed: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _BudgetChartSlice {
  const _BudgetChartSlice({
    required this.amount,
    required this.label,
  });

  final num amount;
  final String label;
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
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final data = items.where((e) => e.amount > 0).toList();
    data.sort((a, b) => b.amount.compareTo(a.amount));

    final total = data.fold<num>(0, (a, b) => a + b.amount);
    final chartData = data.length > 6
        ? [
            ...data.take(5).map(
                  (e) => _BudgetChartSlice(
                    amount: e.amount,
                    label: categories[e.categoryId]?.name ?? '#${e.categoryId}',
                  ),
                ),
            _BudgetChartSlice(
              amount: data.skip(5).fold<num>(0, (sum, e) => sum + e.amount),
              label: 'Khác',
            ),
          ]
        : data
            .map(
              (e) => _BudgetChartSlice(
                amount: e.amount,
                label: categories[e.categoryId]?.name ?? '#${e.categoryId}',
              ),
            )
            .toList();

    // Teal / cyan color palette
    const chartColors = [
      AppColors.primaryDark,
      AppColors.primary,
      Color(0xFF5EEAD4),
      Color(0xFF99F6E4),
      Color(0xFF115E59),
      Color(0xFF0D9488),
      Color(0xFF2DD4BF),
      Color(0xFFCCFBF1),
    ];

    final sections = chartData.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final color = chartColors[i % chartColors.length];
      return PieChartSectionData(
        value: e.amount.toDouble(),
        title: '',
        radius: 24,
        color: color,
      );
    }).toList();

    final legendItems = chartData.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final pct = total == 0 ? 0 : (e.amount / total) * 100;
      final color = chartColors[i % chartColors.length];

      return _BudgetLegendItem(
        color: color,
        percent: '${pct.toStringAsFixed(0)}%',
        label: e.label.toUpperCase(),
      );
    }).toList();

    final chart = SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 52,
              centerSpaceColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '100%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                t.totalSpentPieChart,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      children: [
        chart,
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 20) / 2;

            return Wrap(
              spacing: 20,
              runSpacing: 16,
              children: legendItems
                  .map((item) => SizedBox(width: itemWidth, child: item))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BudgetLegendItem extends StatelessWidget {
  const _BudgetLegendItem({
    required this.color,
    required this.percent,
    required this.label,
  });

  final Color color;
  final String percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  percent,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
                backgroundColor: Colors.indigo.withValues(alpha: .08),
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
    required this.totalIncome,
    required this.totalAssigned,
    required this.totalSpent,
    required this.monthRemaining,
    required this.budgetRemaining,
    required this.hasBudgetPlan,
  });

  final num totalIncome;
  final num totalAssigned;
  final num totalSpent;
  final num monthRemaining;
  final num budgetRemaining;
  final bool hasBudgetPlan;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nf = NumberFormat.decimalPattern(locale)..maximumFractionDigits = 0;
    final isBudgetOver = hasBudgetPlan && budgetRemaining < 0;
    final isMonthNegative = monthRemaining < 0;
    final planValue = hasBudgetPlan
        ? '${isBudgetOver ? t.overLabel : t.remaining} ${nf.format(budgetRemaining.abs())}'
        : t.notSetLabel;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.35,
      mainAxisSpacing: 8,
      crossAxisSpacing: 10,
      children: [
        _SummaryTile(
          label: t.incomeCollected,
          value: nf.format(totalIncome),
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFF16A34A),
        ),
        _SummaryTile(
          label: t.spent,
          value: nf.format(totalSpent),
          icon: Icons.remove_circle_outline_rounded,
          color: const Color(0xFFE8A838),
        ),
        _SummaryTile(
          label: t.remaining,
          value:
              '${isMonthNegative ? '-' : ''}${nf.format(monthRemaining.abs())}',
          icon: isMonthNegative
              ? Icons.trending_down_rounded
              : Icons.account_balance_wallet_outlined,
          color:
              isMonthNegative ? const Color(0xFFEF4444) : AppColors.primaryDark,
        ),
        _SummaryTile(
          label: t.planLabel,
          value: planValue,
          icon: Icons.receipt_long_outlined,
          color: !hasBudgetPlan
              ? const Color(0xFF667085)
              : isBudgetOver
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFDB2777),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    maxLines: 1,
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
