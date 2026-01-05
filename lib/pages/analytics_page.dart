import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/auth/auth_service.dart';

// ================= CONFIG =================
const String _API_BASE_URL = "http://192.168.1.68:8000";

/// ===============================================================
///  ANALYTICS (CÓ LƯU DỰ BÁO THÁNG TRƯỚC)
/// ===============================================================
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _ym = DateTime(DateTime.now().year, DateTime.now().month);

  bool _loadingAI = false;
  double? _predictedExpense; // dự báo tháng hiện tại
  double? _prevMonthSpent; // chi tiêu tháng trước
  double? _prevMonthPredicted; // 🔹 dự báo tháng trước
  List<dynamic> _alerts = [];
  String? _aiError;

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
      if (!c.loading && c.items.isEmpty) futures.add(c.refresh());
      await Future.wait(futures);
      await _computePrevMonthSpent();
      await _fetchPrediction();
    });
  }

  // ================= FETCH DỰ BÁO =================
  Future<void> _fetchPrediction() async {
    try {
      _safeSetState(() {
        _loadingAI = true;
        _aiError = null;
      });

      final token = await _getAccessTokenFromYourAuth();
      final uri = Uri.parse("$_API_BASE_URL/api/predict").replace(
        queryParameters: {
          'year': _ym.year.toString(),
          'month': _ym.month.toString(),
        },
      );

      final res = await http.get(uri, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final num? v =
            (data['prediction'] as num?) ?? (data['predicted_expense'] as num?);

        final rawAlerts = data['alerts'];
        final List<Map<String, dynamic>> alerts =
            (rawAlerts is List) ? rawAlerts.cast<Map<String, dynamic>>() : [];

        // lọc cảnh báo
        List<Map<String, dynamic>> filtered = alerts.where((a) {
          final st = (a['status'] ?? 'new').toString().toLowerCase();
          final active = st == 'new' || st == 'open';
          final createdAt = (a['created_at'] ?? '').toString();
          DateTime? dt;
          try {
            dt = DateTime.parse(createdAt).toLocal();
          } catch (_) {}
          final inMonth =
              dt != null && dt.year == _ym.year && dt.month == _ym.month;
          return active && inMonth;
        }).toList();

        filtered.sort((a, b) {
          DateTime pa, pb;
          try {
            pa = DateTime.parse(a['created_at']).toLocal();
          } catch (_) {
            pa = DateTime.fromMillisecondsSinceEpoch(0);
          }
          try {
            pb = DateTime.parse(b['created_at']).toLocal();
          } catch (_) {
            pb = DateTime.fromMillisecondsSinceEpoch(0);
          }
          return pb.compareTo(pa);
        });

        // loại trùng
        final seenCodes = <String>{};
        filtered = filtered.where((a) {
          final code = (a['code'] ?? '').toString();
          if (seenCodes.contains(code)) return false;
          seenCodes.add(code);
          return true;
        }).toList();

        _safeSetState(() {
          _predictedExpense = v?.toDouble();
          _alerts = filtered;
          _loadingAI = false;
        });

        // 🔹 Lưu dự báo tháng hiện tại
        final prefs = await SharedPreferences.getInstance();
        final key = 'prediction_${_ym.year}_${_ym.month}';
        await prefs.setDouble(key, _predictedExpense ?? 0);

        return;
      }

      if (res.statusCode == 401) {
        _safeSetState(() {
          _aiError = "Bạn chưa đăng nhập hoặc phiên đã hết hạn (401).";
          _loadingAI = false;
        });
        return;
      }

      _safeSetState(() {
        _aiError = "Lỗi API: ${res.statusCode}";
        _loadingAI = false;
      });
    } catch (e) {
      _safeSetState(() {
        _aiError = "Không kết nối được tới server: $e";
        _loadingAI = false;
      });
    }
  }

  // ================= CHI & DỰ BÁO THÁNG TRƯỚC =================
  Future<void> _computePrevMonthSpent() async {
    try {
      final b = context.read<BudgetsProvider>();
      final curY = _ym.year;
      final curM = _ym.month;
      final prev = DateTime(_ym.year, _ym.month - 1, 1);

      await b.loadForMonth(year: prev.year, month: prev.month);
      num spent = 0;
      for (final it in b.items) {
        try {
          final s = (it as dynamic).spent;
          if (s is num) spent += s;
        } catch (_) {}
      }

      // 🔹 lấy dự báo tháng trước
      final prefs = await SharedPreferences.getInstance();
      final prevPredKey = 'prediction_${prev.year}_${prev.month}';
      final prevPredicted = prefs.getDouble(prevPredKey);

      await b.loadForMonth(year: curY, month: curM);
      _safeSetState(() {
        _prevMonthSpent = spent.toDouble();
        _prevMonthPredicted = prevPredicted;
      });
    } catch (_) {}
  }

  Future<String> _getAccessTokenFromYourAuth() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.token != null && auth.token!.isNotEmpty) {
      return auth.token!;
    }
    final t = await AuthService.readToken();
    if (t != null && t.isNotEmpty) return t;
    throw "Chưa đăng nhập";
  }

  // ================= BUILD =================
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
            Text(t.analyticsTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(monthLabel,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
                    year: _ym.year, month: _ym.month);
                await _computePrevMonthSpent();
                _fetchPrediction();
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
          await _computePrevMonthSpent();
          await _fetchPrediction();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: "Dự báo & Cảnh báo",
              child: _buildPredictionCard(nf,
                  totalAssigned: totalAssigned.toDouble(),
                  totalSpent: totalSpent.toDouble(),
                  prevSpent: _prevMonthSpent),
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
                      items: items, categories: categories, number: nf),
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

  // ================== CARD DỰ BÁO ==================
  Widget _buildPredictionCard(NumberFormat nf,
      {required double totalAssigned,
      required double totalSpent,
      double? prevSpent}) {
    if (_loadingAI) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_aiError != null) {
      return Text(_aiError!, style: const TextStyle(color: Colors.red));
    }

    final predicted = _predictedExpense ?? 0;
    final baseline = _prevMonthPredicted ?? predicted;
    final maxBase =
        [baseline, totalSpent, totalAssigned].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_predictedExpense != null)
          Text("Chi tiêu dự báo tháng sau: đ ${nf.format(predicted.round())}",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _ForecastCompareBar(
          maxValue: maxBase == 0 ? 1 : maxBase,
          topValue: baseline,
          topLabel: 'Dự báo tháng trước',
          bottomValue: totalSpent,
          bottomLabel: 'Đã chi (MTD)',
          budget: totalAssigned,
        ),
        const SizedBox(height: 10),
        if (_alerts.isEmpty)
          const Text("Không có cảnh báo.",
              style: TextStyle(color: Colors.black54))
        else
          Column(children: _alerts.map((a) => _AlertTile(data: a)).toList()),
      ],
    );
  }

  Future<DateTime?> _pickMonth(BuildContext context,
      {required DateTime initial}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2035, 12),
      helpText: AppLocalizations.of(context)!.selectMonth,
    );
    if (picked == null) return null;
    return DateTime(picked.year, picked.month);
  }
}

/* ============================================================
   CÁC WIDGET PHỤ (giữ nguyên logic gốc)
   ============================================================ */
class _SectionCard extends StatefulWidget {
  const _SectionCard(
      {required this.title,
      required this.child,
      this.collapsible = true,
      this.initiallyExpanded = true});
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
          )
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  if (widget.collapsible)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      turns: _expanded ? 0.0 : 0.5,
                      child: const Icon(Icons.keyboard_arrow_up_rounded,
                          size: 22, color: Colors.black54),
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
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(24), child: Center(child: Text(text)));
}

/// Thanh so sánh dự báo vs chi
class _ForecastCompareBar extends StatelessWidget {
  const _ForecastCompareBar({
    required this.maxValue,
    required this.topValue,
    required this.topLabel,
    required this.bottomValue,
    required this.bottomLabel,
    required this.budget,
  });
  final double maxValue;
  final double topValue;
  final String topLabel;
  final double bottomValue;
  final String bottomLabel;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag());

    Widget buildBar(double value, String label, Color color) {
      final p = (value / (maxValue == 0 ? 1 : maxValue)).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('đ ${nf.format(value.round())}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black12.withOpacity(.06),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              LayoutBuilder(
                builder: (context, c) {
                  final p =
                      (value / (maxValue == 0 ? 1 : maxValue)).clamp(0.0, 1.0);
                  final markX =
                      (budget / (maxValue == 0 ? 1 : maxValue)).clamp(0.0, 1.0);
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: c.maxWidth * p,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                              colors: [color.withOpacity(.85), color]),
                        ),
                      ),
                      if (budget > 0)
                        Positioned(
                          left: c.maxWidth * markX - 1,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: Colors.black26),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildBar(topValue, topLabel, Colors.indigo),
        buildBar(bottomValue, bottomLabel, Colors.orange),
        if (budget > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Icon(Icons.stacked_line_chart, size: 14, color: Colors.black45),
              SizedBox(width: 4),
              Text('Vạch ngân sách',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final msg = (data['message'] ?? '').toString();
    final rawLevel = (data['level'] ?? 'info').toString().toLowerCase();
    final normalized = switch (rawLevel) {
      'critical' || 'danger' => 'danger',
      'warning' || 'warn' => 'warn',
      _ => 'info',
    };

    final (color, icon) = switch (normalized) {
      'danger' => (Colors.red, Icons.error_outline),
      'warn' => (Colors.orange, Icons.warning_amber_rounded),
      _ => (Colors.blue, Icons.info_outline),
    };

    String? timeStr;
    final createdAt = data['created_at']?.toString();
    if (createdAt != null && createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        final loc = Localizations.localeOf(context).toLanguageTag();
        timeStr = DateFormat.yMd(loc).add_Hm().format(dt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.18), width: .8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.isEmpty ? 'Có cảnh báo mới.' : msg,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w800)),
                if (timeStr != null) ...[
                  const SizedBox(height: 2),
                  Text(timeStr,
                      style: TextStyle(
                          color: color.withOpacity(.9), fontSize: 11)),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// ==================== BIỂU ĐỒ & TỔNG KẾT ====================
class _BudgetPieChart extends StatelessWidget {
  const _BudgetPieChart({required this.items, required this.categories});
  final List<BudgetItem> items;
  final Map<int, Category> categories;

  @override
  Widget build(BuildContext context) {
    final data = items.where((e) => e.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = data.fold<num>(0, (a, b) => a + b.amount);
    final sections = data
        .map((e) => PieChartSectionData(
              value: e.amount.toDouble(),
              title: '${((e.amount / total) * 100).toStringAsFixed(0)}%',
              radius: 70,
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ))
        .toList();

    return Column(children: [
      SizedBox(
        height: 220,
        child: PieChart(PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 44,
          centerSpaceColor: Colors.white,
        )),
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
    ]);
  }
}

class _TopCategoriesList extends StatelessWidget {
  const _TopCategoriesList(
      {required this.items, required this.categories, required this.number});
  final List<BudgetItem> items;
  final Map<int, Category> categories;
  final NumberFormat number;

  @override
  Widget build(BuildContext context) {
    final data = items.where((e) => e.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return Column(
      children: data
          .map((it) => ListTile(
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
                  categories[it.categoryId]?.name ??
                      'Danh mục ${it.categoryId}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Text('đ ${number.format(it.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ))
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

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
    ]);
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
  Widget build(BuildContext context) => Container(
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
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
