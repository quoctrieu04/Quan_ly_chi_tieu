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
import 'package:chitieu/widgets/app_page_header.dart';
import 'package:chitieu/widgets/app_month_picker_sheet.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/widgets/onboarding_next_step_card.dart';

import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';

// Tháng/Năm dùng chung
import 'package:chitieu/core/date/year_month_provider.dart';
import 'package:chitieu/pages/setting/settings_provider.dart';
import 'package:chitieu/pages/note_page.dart';

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
  VoidCallback? _financeListener;
  bool _trendRefreshQueued = false;

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

      _financeListener = () {
        if (!mounted || _trendRefreshQueued) return;
        _trendRefreshQueued = true;
        Future.microtask(() async {
          try {
            await _loadLast6MonthsTrend();
          } finally {
            _trendRefreshQueued = false;
          }
        });
      };
      context
          .read<FinancialTransactionProvider>()
          .addListener(_financeListener!);
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
      if (_financeListener != null) {
        context
            .read<FinancialTransactionProvider>()
            .removeListener(_financeListener!);
      }
    } catch (_) {}
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
    final picked = await showAppMonthPicker(
      context: context,
      initial: DateTime(ym.year, ym.month),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
      showAppSnackBar(context, 'Đã thêm nguồn thu', icon: Icons.check_circle_rounded);
    }
  }

  Future<void> _openCreateAccount() async {
    final prov = context.read<BankAccountProvider>();
    if (prov.loading) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateBankAccountForm(),
    );

    if (created == true && mounted) {
      await prov.fetch();
      await _fetchCurrentYm();
    }
  }

  Future<void> _openCreateIncome() async {
    final prov = context.read<IncomeProvider>();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateIncomeForm(),
    );

    if (created == true && mounted) {
      final ym = context.read<YearMonthProvider>().ym;
      await prov.fetch(year: ym.year, month: ym.month);
      await _fetchCurrentYm();
    }
  }

  Future<void> _openFirstTransaction() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotePage()),
    );
    if (mounted) await _fetchCurrentYm();
  }

  @override
  Widget build(BuildContext context) {
    // Ép AccountsPage luôn build lại khi thay đổi màu chủ đạo ở SettingsProvider
    context.watch<SettingsProvider>();

    final t = AppLocalizations.of(context)!;
    final ym = context.watch<YearMonthProvider>().ym;
    final monthLabel = DateFormat.yMMMM(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(ym);
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
    final hasAccounts = walletProv.items.isNotEmpty;
    final hasTransactions = totalIncome > 0 || totalSpent > 0;



    final now = DateTime.now();
    final int daysInMonth = _daysInMonth(DateTime(ym.year, ym.month));
    final bool isCurr = _isCurrentMonth(ym);
    final int dayToday = isCurr ? now.day : daysInMonth;
    final int daysLeft = isCurr ? (daysInMonth - dayToday + 1) : 0;
    final num dailyAllowance =
        daysLeft > 0 ? (combinedRemaining / daysLeft) : 0;

    final incomesToShow =
        incomes.where((c) => (c.title ?? '').trim().isNotEmpty).toList();
    final showOnboardingGuide =
        !hasAccounts || incomesToShow.isEmpty || !hasTransactions;
    final savingProv = context.watch<SavingProvider>();
    final totalSaved =
        savingProv.items.fold<double>(0, (sum, s) => sum + s.currentAmount);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      appBar: AppPageHeaderBar(
        icon: Icons.account_balance_rounded,
        title: t.tabAccounts,
        subtitle: monthLabel,
        onTap: _openMonthPicker,
        actions: [
          HeaderIconButton(
            icon: Icons.calendar_today_outlined,
            tooltip: t.selectMonth,
            onPressed: _openMonthPicker,
          ),
          HeaderIconButton(
            icon: Icons.info_outline_rounded,
            tooltip: 'Gợi ý chi tiêu',
            onPressed: () => _openAdviceSheet(
              combinedRemaining: combinedRemaining,
              dailyAllowance: dailyAllowance,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchCurrentYm(),
        child: SafeArea(
          top: false,
          bottom: true,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Tổng tiền / Đã chi / Còn lại =====
                HeaderCard(
                  title: t.totalAssets,
                  totalText: _hideBalance
                      ? '•••'
                      : fmt(totalBalance), // Dùng totalBalance cho tổng tiền
                  loading: walletProv.loading || ftProv.loading,
                  paymentText: _hideBalance ? '•••' : fmt(totalSpent),
                  trackingText: _hideBalance
                      ? '•••'
                      : fmt(
                          totalSaved), // Dùng combinedRemaining cho số tiền còn lại
                  onToggleEye: _toggleHide,
                  isHidden: _hideBalance,
                ),
                const SizedBox(height: 16),

                if (!hasAccounts) ...[
                  OnboardingNextStepCard(
                    stepLabel: 'Bước 1/5',
                    title: 'Thêm tài khoản đầu tiên',
                    message:
                        'Tạo một tài khoản như Tiền mặt, Ngân hàng hoặc Ví điện tử để app biết bạn đang quản lý tiền ở đâu.',
                    buttonLabel: 'Thêm tài khoản',
                    icon: Icons.account_balance_wallet_rounded,
                    onPressed: _openCreateAccount,
                  ),
                  const SizedBox(height: 16),
                ] else if (incomesToShow.isEmpty) ...[
                  OnboardingNextStepCard(
                    stepLabel: 'Bước 2/5',
                    title: 'Thêm nguồn thu',
                    message:
                        'Cho app biết tiền của bạn đến từ đâu, ví dụ Lương, Phụ cấp hoặc Kinh doanh.',
                    buttonLabel: 'Thêm nguồn thu',
                    icon: Icons.attach_money_rounded,
                    onPressed: _openCreateIncome,
                  ),
                  const SizedBox(height: 16),
                ] else if (!hasTransactions) ...[
                  OnboardingNextStepCard(
                    stepLabel: 'Bước 5/5',
                    title: 'Thêm giao dịch đầu tiên',
                    message:
                        'Ghi lại khoản thu hoặc chi đầu tiên. Từ đây app sẽ bắt đầu thống kê cho bạn.',
                    buttonLabel: 'Thêm giao dịch',
                    icon: Icons.edit_note_rounded,
                    onPressed: _openFirstTransaction,
                  ),
                  const SizedBox(height: 16),
                ],

                if (!showOnboardingGuide)
                  FeatureHorizontalMenu(
                    items: [
                      FeatureItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: t.tabAccounts,
                        onTap: () async {
                          final prov = context.read<BankAccountProvider>();

                          if (prov.loading) return;

                          // ✅ Delay 1 frame để thoát gesture
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
                        label: t.fundingSource,
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
                        label: t.savings,
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
                        label: t.investment,
                        onTap: () {
                          Navigator.pushNamed(context, '/investment');
                        },
                      ),
                      FeatureItem(
                        icon: Icons.history_rounded,
                        label: t.transactionHistory,
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
                if (!showOnboardingGuide) const SizedBox(height: 20),

// ===== TỔNG THU / TỔNG CHI =====
                MonthSummaryCard(
                  totalIncome: totalIncome,
                  totalExpense: totalSpent,
                  hideBalance: _hideBalance,
                ),

                const SizedBox(height: 16),

                if (_loadingTrend)
                  const Center(child: CircularProgressIndicator())
                else
                  SpendingTrendCard(data: _trendData),

                const SizedBox(height: 16),


              ],
            ),
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
      showAppSnackBar(context, "Đã xoá kế hoạch tiết kiệm", icon: Icons.delete_rounded);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? cs.surfaceContainerHigh : Colors.white;
    final textColor = isDark ? cs.onSurface : AppColors.textMain;
    final mutedColor = cs.onSurface.withValues(alpha: .52);
    final accent = cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? cs.outlineVariant.withValues(alpha: .1) : AppColors.border,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 19,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .1,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onToggleEye,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      totalText,
                      key: ValueKey(totalText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (loading) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class LegacyAccountsMonthPickerSheet extends StatefulWidget {
  final DateTime initial;
  const LegacyAccountsMonthPickerSheet({required this.initial});

  @override
  State<LegacyAccountsMonthPickerSheet> createState() =>
      LegacyAccountsMonthPickerSheetState();
}

class LegacyAccountsMonthPickerSheetState
    extends State<LegacyAccountsMonthPickerSheet> {
  late int y;
  @override
  void initState() {
    super.initState();
    y = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Năm trước',
                onPressed: () => setState(() => y--),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$y',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(
                tooltip: 'Năm sau',
                onPressed: () => setState(() => y++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(12, (i) {
              final m = i + 1;
              final isSel =
                  (y == widget.initial.year && m == widget.initial.month);
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor:
                      isSel ? cs.primaryContainer : cs.surfaceVariant,
                  foregroundColor:
                      isSel ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, DateTime(y, m, 1));
                },
                child: Text('$m',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              );
            }),
          ),
        ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Gợi ý chi tiêu tháng này',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('Tháng ${month.toString().padLeft(2, '0')} / $year',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Còn lại: ${hideBalance ? "•••" : fmt(combinedRemaining)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (isCurrentMonth && combinedRemaining > 0) ...[
            const SizedBox(height: 6),
            Text(
                'Mức chi trung bình/ngày: ${hideBalance ? "•••" : fmt(dailyAllowance)}'),
          ],
          const SizedBox(height: 12),
          Text(advice()),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm nguồn thu'),
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
            ),
          ),
        ],
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
              fmt(total),
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
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moneySettings = context.watch<MoneySettingsProvider>().settings;

    String fmt(num v) =>
        hideBalance ? '•••' : MoneyFormatter(moneySettings).format(v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            t.overview,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _SummaryItem(
                icon: Icons.arrow_downward_rounded,
                label: t.income,
                value: fmt(totalIncome),
                color: const Color(0xFF12805C),
                bg: const Color(0xFFE9F7EF),
                isDark: isDark,
                onTap: () {
                  final ym = context.read<YearMonthProvider>().ym;
                  Navigator.pushNamed(context, '/transactions', arguments: {
                    'year': ym.year,
                    'month': ym.month,
                    'type': 'in',
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryItem(
                icon: Icons.arrow_upward_rounded,
                label: t.expense,
                value: fmt(totalExpense),
                color: const Color(0xFFD13B3B),
                bg: const Color(0xFFFFEFEF),
                isDark: isDark,
                onTap: () {
                  final ym = context.read<YearMonthProvider>().ym;
                  Navigator.pushNamed(context, '/transactions', arguments: {
                    'year': ym.year,
                    'month': ym.month,
                    'type': 'out',
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final bool isDark;
  final VoidCallback onTap;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withValues(alpha: .12)
              : const Color(0xFFE8EEF2),
        ),
        boxShadow: [
          if (!isDark)
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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: .25),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: .55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    ),
    );
  }
}


