import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/financial_transaction/financial_transaction_provider.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:chitieu/widgets/create_saving_form.dart';
import 'package:chitieu/widgets/edit_bank_account_form.dart';
import 'package:chitieu/widgets/feature_grid.dart';
import 'package:chitieu/widgets/models/monthly_cashflow.dart';
import 'package:chitieu/widgets/saving_transaction_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:chitieu/widgets/spending_trend_card.dart';
import 'package:chitieu/widgets/saving_goal_card.dart';

import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';

// Tháng/Năm dùng chung
import 'package:chitieu/core/date/year_month_provider.dart';

// Form khoản thu
import 'package:chitieu/widgets/create_income_form.dart';
// Form chỉnh sửa khoản thu
import 'package:chitieu/widgets/edit_income_form.dart';

// Auth
import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/auth/login.dart';

// BankAccount / ví
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

// ===== Cấu trúc giao dịch mới =====
import 'package:chitieu/api/in_invoice/in_invoice_provider.dart';
import 'package:chitieu/api/out_invoice/out_invoice_provider.dart';
import 'package:chitieu/api/bank_transaction/bank_transaction_provider.dart';

// Budgets
import 'package:chitieu/core/budget/budgets_provider.dart';

// Income
import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/widgets/create_bank_account_form.dart';

import 'package:chitieu/api/saving/saving_provider.dart';
import 'package:chitieu/widgets/create_saving_form.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});
  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  Color _progressColor(double progress) {
    if (progress >= 1) return Colors.green.shade800;
    if (progress >= 0.7) return Colors.green;
    if (progress >= 0.4) return Colors.orange;
    return Colors.redAccent;
  }

  List<MonthlyCashFlow> _trendData = [];
  bool _loadingTrend = true;
  num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  static const _prefKeyHideBalance = 'pref_hide_balance';

  AuthProvider? _auth;
  bool _hideBalance = false;
  VoidCallback? _authListener;

  @override
  @override
  void initState() {
    super.initState();
    _loadHidePref();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _auth = context.read<AuthProvider>();
      final ym = context.read<YearMonthProvider>().ym;

      await _auth!.bootstrap();

      // 🔁 ĐỔI TOÀN BỘ ĐOẠN IF Ở ĐÂY
      if (_auth!.isAuthenticated) {
        // Gọi 1 hàm duy nhất, fetch đủ ví + chi + thu + ngân sách + saving
        await _fetchForYm(ym.year, ym.month);
        await _loadLast6MonthsTrend();
        if (mounted) setState(() {});
      } else {
        // Clear ví khi chưa login
        context.read<BankAccountProvider>().clear();
        if (mounted) setState(() {});
      }

      // 🔁 SỬA LUÔN _authListener
      _authListener = () async {
        if (!mounted) return;
        final ymNow = context.read<YearMonthProvider>().ym;

        try {
          if (_auth!.isAuthenticated) {
            // Lúc trạng thái auth thay đổi, cũng fetch full data
            await _fetchForYm(ymNow.year, ymNow.month);
            await _loadLast6MonthsTrend();
            if (mounted) setState(() {});
          } else {
            final bank = context.read<BankAccountProvider>();
            if (!bank.hasListeners) return;
            bank.clear();
            if (mounted) setState(() {});
          }
        } catch (e) {
          if (kDebugMode) print('Auth listener fetch error: $e');
        }
      };

      _auth!.addListener(_authListener!);
      context.read<YearMonthProvider>().addListener(_onYmChanged);
    });
  }

  Future<void> _loadLast6MonthsTrend() async {
    final inApi = context.read<InInvoiceProvider>().api;
    final outApi = context.read<OutInvoiceProvider>().api;

    final now = DateTime.now();
    final List<MonthlyCashFlow> list = [];

    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);

      final inRes = await inApi.fetchByMonth(year: d.year, month: d.month);
      final outRes = await outApi.fetchByMonth(year: d.year, month: d.month);

      final income = (inRes['data'] as List? ?? [])
          .fold<num>(0, (s, e) => s + _toNum(e['amount']));

      final expense = (outRes['data'] as List? ?? [])
          .fold<num>(0, (s, e) => s + _toNum(e['amount']));

      list.add(MonthlyCashFlow(
        year: d.year,
        month: d.month,
        income: income,
        expense: expense,
      ));
    }

    if (!mounted) return;
    setState(() {
      _trendData = list;
      _loadingTrend = false;
    });
  }

  @override
  void dispose() {
    if (_authListener != null) _auth?.removeListener(_authListener!);
    try {
      context.read<YearMonthProvider>().removeListener(_onYmChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadHidePref() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getBool(_prefKeyHideBalance) ?? false;
    if (mounted) setState(() => _hideBalance = v);
  }

  Future<void> _toggleHide() async {
    setState(() => _hideBalance = !_hideBalance);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_prefKeyHideBalance, _hideBalance);
  }

  void _onYmChanged() {
    if (!mounted) return;
    _fetchCurrentYm();
  }

  Future<void> _fetchCurrentYm() async {
    final ym = context
        .read<YearMonthProvider>()
        .ym; // lấy year và month từ YearMonthProvider
    await _fetchForYm(ym.year, ym.month); // Gọi lại API cho tháng năm hiện tại
    context.read<SavingProvider>().fetch(
        year: ym.year,
        month: ym.month); // Gọi lại API tiết kiệm cho tháng/năm cụ thể
  }

  Future<void> _fetchForYm(int year, int month) async {
    final walletProv = context.read<BankAccountProvider>();
    final inProv = context.read<InInvoiceProvider>();
    final outProv = context.read<OutInvoiceProvider>();
    final bankProv = context.read<BankTransactionProvider>();
    final budgetsProv = context.read<BudgetsProvider>();
    final incomeProv = context.read<IncomeProvider>();
    final savingProv = context.read<SavingProvider>();
    final investmentProv = context.read<InvestmentProvider>();
    final ftProv = context.read<FinancialTransactionProvider>();

    /// ⚠️ SỬA LẠI ĐÚNG — TRUYỀN YEAR + MONTH
    await savingProv.fetch(year: year, month: month);

    await Future.wait([
      walletProv.fetchAccounts(), // 🔥 FIX
      inProv.fetch(year: year, month: month),
      outProv.fetch(year: year, month: month),
      bankProv.fetch(year: year, month: month),
      budgetsProv.loadForMonth(year: year, month: month),
      incomeProv.fetch(year: year, month: month),
      investmentProv.fetch(),
      ftProv.fetchByMonth(year: year, month: month),
    ]);
  }

  int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  bool _isCurrentMonth(DateTime ym) =>
      ym.year == DateTime.now().year && ym.month == DateTime.now().month;

  Future<void> _openMonthPicker() async {
    final ym = context.read<YearMonthProvider>().ym;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MonthPickerSheet(
        initial: DateTime(ym.year, ym.month, 1),
      ),
    );
    if (picked != null && mounted) {
      context.read<YearMonthProvider>().setYm(picked);
    }
  }

  Future<void> _openAdviceSheet({
    required num combinedRemaining,
    required num dailyAllowance,
  }) async {
    final ym = context.read<YearMonthProvider>().ym;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdviceSheet(
        year: ym.year,
        month: ym.month,
        isCurrentMonth: _isCurrentMonth(ym),
        combinedRemaining: combinedRemaining,
        dailyAllowance: dailyAllowance,
        hideBalance: _hideBalance,
      ),
    );

    if (created == true && mounted) {
      await _fetchCurrentYm();
      safeShowSnackBar(
        context,
        const SnackBar(content: Text('Đã thêm nguồn thu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final ym = context.watch<YearMonthProvider>().ym;
    final isLoggedIn =
        context.select<AuthProvider, bool>((a) => a.isAuthenticated);

    final walletProv = context.watch<BankAccountProvider>();
    final totalBalance =
        walletProv.items.fold<double>(0, (s, w) => s + (w.balance ?? 0));

    final incomeProv = context.watch<IncomeProvider>();
    final incomes = incomeProv.items;

    final moneySettings = context.watch<MoneySettingsProvider>().settings;
    String fmt(num v) => MoneyFormatter(moneySettings).format(v);

    final ftProv = context.watch<FinancialTransactionProvider>();
    final budgetsProv = context.watch<BudgetsProvider>();

    final num totalIncome = ftProv.totalIncome;
    final num totalSpent = ftProv.totalExpense;
    final num combinedRemaining = totalBalance - totalSpent;

    final bool overSpent =
        !(walletProv.loading || ftProv.loading) && combinedRemaining < 0;
    final num deficit = (combinedRemaining < 0) ? -combinedRemaining : 0;

    final now = DateTime.now();
    final int daysInMonth = _daysInMonth(DateTime(ym.year, ym.month));
    final bool isCurr = _isCurrentMonth(ym);
    final int dayToday = isCurr ? now.day : daysInMonth;
    final int daysLeft = isCurr ? (daysInMonth - dayToday + 1) : 0;
    final num dailyAllowance =
        daysLeft > 0 ? (combinedRemaining / daysLeft) : 0;

    final incomesToShow =
        incomes.where((c) => (c.title ?? '').trim().isNotEmpty).toList();
    final savingProv = context.watch<SavingProvider>();
    final totalSaved =
        savingProv.items.fold<double>(0, (sum, s) => sum + s.currentAmount);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const _mint = Color(0xFF2EC4B6);
    const _mintLight = Color(0xFF5DE8DA);
    final bgColor = isDark ? cs.surface : const Color(0xFFF5F7FA);

    return RefreshIndicator(
      color: _mint,
      onRefresh: () async => _fetchCurrentYm(),
      child: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Tháng + Info =====
              Row(
                children: [
                  Material(
                    color: isDark
                        ? cs.surfaceContainerHigh
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _openMonthPicker,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? cs.outlineVariant.withOpacity(.08)
                                : const Color(0xFFECEDF2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                size: 18, color: _mint),
                            const SizedBox(width: 8),
                            Text(
                              'Tháng ${ym.month.toString().padLeft(2, '0')} / ${ym.year}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.expand_more_rounded,
                                size: 18,
                                color: cs.onSurface.withOpacity(.4)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: _mint.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => _openAdviceSheet(
                        combinedRemaining: combinedRemaining,
                        dailyAllowance: dailyAllowance,
                      ),
                      icon: Icon(Icons.lightbulb_outline_rounded,
                          size: 20, color: _mint),
                      tooltip: 'Gợi ý chi tiêu',
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ===== Tổng tiền / Đã chi / Còn lại =====
              HeaderCard(
                title: t.totalAssets,
                totalText: _hideBalance
                    ? '•••'
                    : fmt(totalBalance),
                loading: walletProv.loading || ftProv.loading,
                paymentText: _hideBalance ? '•••' : fmt(totalSpent),
                trackingText: _hideBalance
                    ? '•••'
                    : fmt(totalSaved),
                onToggleEye: _toggleHide,
                isHidden: _hideBalance,
              ),
              const SizedBox(height: 16),

              FeatureHorizontalMenu(
                items: [
                  FeatureItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Tài khoản',
                    onTap: () async {
                      final prov = context.read<BankAccountProvider>();
                      if (prov.loading) return;
                      await Future.delayed(Duration.zero);
                      if (!context.mounted) return;
                      if (prov.items.isEmpty) {
                        final created = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => const CreateBankAccountForm(),
                        );
                        if (created == true && context.mounted) {
                          await prov.fetch();
                        }
                      } else {
                        Navigator.pushNamed(context, '/accounts');
                      }
                    },
                  ),
                  FeatureItem(
                    icon: Icons.attach_money_rounded,
                    label: 'Nguồn tiền',
                    onTap: () async {
                      final prov = context.read<IncomeProvider>();
                      if (prov.items.isEmpty) {
                        final created = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => const CreateIncomeForm(),
                        );
                        if (created == true && context.mounted) {
                          final ym = context.read<YearMonthProvider>().ym;
                          await prov.fetch(year: ym.year, month: ym.month);
                        }
                      } else {
                        Navigator.pushNamed(context, '/income');
                      }
                    },
                  ),
                  FeatureItem(
                    icon: Icons.savings_rounded,
                    label: 'Tiết kiệm',
                    onTap: () async {
                      final prov = context.read<SavingProvider>();
                      final ym = context.read<YearMonthProvider>().ym;
                      if (prov.items.isEmpty) {
                        final created = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => const CreateSavingForm(),
                        );
                        if (created == true && context.mounted) {
                          await prov.fetch(year: ym.year, month: ym.month);
                        }
                      } else {
                        Navigator.pushNamed(context, '/saving');
                      }
                    },
                  ),
                  FeatureItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Đầu tư',
                    onTap: () {
                      Navigator.pushNamed(context, '/investment');
                    },
                  ),
                  FeatureItem(
                    icon: Icons.history_rounded,
                    label: 'Lịch sử',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/transactions',
                        arguments: {'year': ym.year, 'month': ym.month},
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ===== TỔNG THU / TỔNG CHI =====
              MonthSummaryCard(
                totalIncome: totalIncome,
                totalExpense: totalSpent,
                hideBalance: _hideBalance,
              ),

              const SizedBox(height: 32),

              if (_loadingTrend)
                const Center(child: CircularProgressIndicator())
              else
                SpendingTrendCard(data: _trendData),

              const SizedBox(height: 32),

              SavingGoalCard(
                totalSaved: totalSaved,
                onCreate: () {
                  Navigator.pushNamed(context, '/saving');
                },
              ),

              const SizedBox(height: 24),

              // ===== Cảnh báo vượt chi =====
              if (overSpent) ...[
                WarningBanner(
                  message: _hideBalance
                      ? 'Chi dự kiến đang báo động vượt số dư.'
                      : 'Chi dự kiến vượt quá số tiền còn lại ${fmt(deficit)}.',
                  onFixBudgets: () {
                    Navigator.pushNamed(context, '/budgets');
                  },
                  onAddIncome: () async {
                    final created = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: const CreateIncomeForm(),
                      ),
                    );
                    if (created == true && context.mounted) {
                      await _fetchCurrentYm();
                      safeShowSnackBar(
                        context,
                        const SnackBar(content: Text('Đã thêm nguồn thu')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSaving(BuildContext context, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa kế hoạch tiết kiệm"),
        content: const Text("Bạn có chắc chắn muốn xóa kế hoạch này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await context.read<SavingProvider>().remove(id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xoá kế hoạch tiết kiệm")),
      );
    }
  }
}

/// ================== Widgets phụ (không đổi cấu trúc) ==================

class HeaderCard extends StatelessWidget {
  final String title, totalText, paymentText, trackingText;
  final bool loading, isHidden;
  final VoidCallback onToggleEye;

  const HeaderCard({
    super.key,
    required this.title,
    required this.totalText,
    required this.paymentText,
    required this.trackingText,
    required this.loading,
    required this.onToggleEye,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2EC4B6),
            Color(0xFF1FA598),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2EC4B6).withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  // Title pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onToggleEye,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              isHidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Total amount
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      totalText,
                      key: ValueKey(totalText),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (loading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.white.withOpacity(.1),
                      color: Colors.white.withOpacity(.5),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Col(
                            label: 'Đã chi',
                            value: paymentText,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withOpacity(.2),
                        ),
                        Expanded(
                          child: _Col(
                            label: 'Tiết kiệm',
                            value: trackingText,
                            color: Colors.white,
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
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Col({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onFixBudgets;
  final VoidCallback onAddIncome;

  const WarningBanner({
    super.key,
    required this.message,
    required this.onFixBudgets,
    required this.onAddIncome,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.error.withOpacity(.08)
            : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.error.withOpacity(.15),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.error.withOpacity(.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: cs.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFixBudgets,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Điều chỉnh',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: cs.outline.withOpacity(.2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddIncome,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Thêm thu',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initial;
  const _MonthPickerSheet({required this.initial});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int y;
  @override
  void initState() {
    super.initState();
    y = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : const Color(0xFFFAFBFE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Year row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EC4B6).withOpacity(.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    tooltip: 'Năm trước',
                    onPressed: () => setState(() => y--),
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Color(0xFF2EC4B6)),
                    constraints:
                        const BoxConstraints(minWidth: 38, minHeight: 38),
                  ),
                ),
                Text('$y',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    )),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EC4B6).withOpacity(.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    tooltip: 'Năm sau',
                    onPressed: () => setState(() => y++),
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF2EC4B6)),
                    constraints:
                        const BoxConstraints(minWidth: 38, minHeight: 38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: List.generate(12, (i) {
                final m = i + 1;
                final isSel =
                    (y == widget.initial.year && m == widget.initial.month);
                return Material(
                  color: isSel
                      ? const Color(0xFF2EC4B6)
                      : (isDark ? cs.surfaceContainerHigh : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, DateTime(y, m, 1)),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFF2EC4B6)
                              : (isDark
                                  ? cs.outlineVariant.withOpacity(.08)
                                  : const Color(0xFFECEDF2)),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'T$m',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSel
                              ? Colors.white
                              : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceSheet extends StatelessWidget {
  final int year, month;
  final bool isCurrentMonth;
  final num combinedRemaining;
  final num dailyAllowance;
  final bool hideBalance;

  const _AdviceSheet({
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.combinedRemaining,
    required this.dailyAllowance,
    required this.hideBalance,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String fmt(num v) {
      final moneySettings = context.read<MoneySettingsProvider>().settings;
      return MoneyFormatter(moneySettings).format(v);
    }

    String advice() {
      if (!isCurrentMonth) return 'Dữ liệu của tháng $month/$year.';
      if (combinedRemaining <= 0) {
        return 'Bạn đã ${combinedRemaining < 0 ? "vượt" : "hết"} số tiền còn lại của tháng này. Hãy tiết kiệm hoặc cân nhắc thêm nguồn thu.';
      }
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final now = DateTime.now();
      final today = (isCurrentMonth) ? now.day : daysInMonth;
      final daysLeft = (isCurrentMonth) ? (daysInMonth - today + 1) : 0;
      if (daysLeft <= 0) return 'Đây là dữ liệu tổng kết tháng $month/$year.';
      if (dailyAllowance <= 0) {
        return 'Số dư hiện tại không đủ để chi tiêu cho $daysLeft ngày còn lại. Hãy thêm nguồn thu hoặc cắt giảm chi.';
      }
      const kLow = 20000;
      if (dailyAllowance < kLow) {
        return 'Mức chi trung bình/ngày đang rất thấp. Hãy tiết kiệm hơn hoặc cân nhắc thêm nguồn thu.';
      }
      return 'Để đủ cho $daysLeft ngày còn lại, hãy giữ mức chi khoảng ${fmt(dailyAllowance)} mỗi ngày.';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : const Color(0xFFFAFBFE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EC4B6).withOpacity(.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.lightbulb_outline_rounded,
                        color: const Color(0xFF2EC4B6), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Gợi ý chi tiêu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        )),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EC4B6).withOpacity(.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'T${month.toString().padLeft(2, '0')}/$year',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2EC4B6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surfaceContainerHigh
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? cs.outlineVariant.withOpacity(.08)
                              : const Color(0xFFECEDF2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Còn lại',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(.45),
                              )),
                          const SizedBox(height: 4),
                          Text(
                            hideBalance ? '•••' : fmt(combinedRemaining),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: combinedRemaining >= 0
                                  ? const Color(0xFF2EC4B6)
                                  : cs.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isCurrentMonth && combinedRemaining > 0) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? cs.surfaceContainerHigh
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? cs.outlineVariant.withOpacity(.08)
                                : const Color(0xFFECEDF2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chi/ngày',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface.withOpacity(.45),
                                )),
                            const SizedBox(height: 4),
                            Text(
                              hideBalance ? '•••' : fmt(dailyAllowance),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              // Advice text
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EC4B6).withOpacity(.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF2EC4B6).withOpacity(.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16,
                        color: const Color(0xFF2EC4B6).withOpacity(.6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        advice(),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: cs.onSurface.withOpacity(.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Add income button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2EC4B6),
                        const Color(0xFF1FA598),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2EC4B6).withOpacity(.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm nguồn thu',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                    onPressed: () async {
                      final created = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: const CreateIncomeForm(),
                        ),
                      );
                      if (created == true && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final String name;
  final String balanceText;
  final bool isDefault;
  final IconData icon;
  final VoidCallback onEdit;

  const _WalletCard({
    required this.name,
    required this.balanceText,
    required this.isDefault,
    required this.icon,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black12)
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: 48,
                  height: 48,
                  child: Icon(icon, color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Mặc định',
                                style: TextStyle(
                                  color: cs.onSecondaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(balanceText,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa nguồn thu',
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTxItem extends StatelessWidget {
  final String title;
  final Color color;
  final String sign;
  final num total;
  final String type; // 'expense' or 'income'
  final dynamic moneySettings;
  final bool isHidden;

  const _SimpleTxItem({
    required this.title,
    required this.color,
    required this.sign,
    required this.total,
    required this.type,
    required this.moneySettings,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context) {
    String fmt(num v) =>
        isHidden ? '•••' : MoneyFormatter(moneySettings).format(v);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/transactions',
          arguments: {
            'type': type, // Giữ đúng loại giao dịch khi bấm
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 6,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              '$sign${fmt(total)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MonthSummaryCard extends StatelessWidget {
  final num totalIncome;
  final num totalExpense;
  final bool hideBalance;

  const MonthSummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.hideBalance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moneySettings = context.watch<MoneySettingsProvider>().settings;

    String fmt(num v) =>
        hideBalance ? '•••' : MoneyFormatter(moneySettings).format(v);

    const mint = Color(0xFF2EC4B6);
    const danger = Color(0xFFEF4444);
    final net = totalIncome - totalExpense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thu chi tháng này',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A2332),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        _FlowRow(
          label: 'Thu nhập',
          value: '+${fmt(totalIncome)}',
          color: mint,
          icon: Icons.south_west_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _FlowRow(
          label: 'Chi tiêu',
          value: '-${fmt(totalExpense)}',
          color: danger,
          icon: Icons.north_east_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          color: isDark ? Colors.white.withOpacity(.06) : const Color(0xFFEDF2F7),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Chênh lệch',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withOpacity(.5) : const Color(0xFF94A3B8),
              ),
            ),
            const Spacer(),
            Text(
              '${net >= 0 ? '+' : ''}${fmt(net)}',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: net >= 0 ? mint : danger,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _FlowRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? .12 : .06),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        Text(label,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: isDark ? Colors.white.withOpacity(.7) : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(value,
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

