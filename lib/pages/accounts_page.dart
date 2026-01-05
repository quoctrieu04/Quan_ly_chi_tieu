import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:chitieu/widgets/create_saving_form.dart';
import 'package:chitieu/widgets/edit_bank_account_form.dart';
import 'package:chitieu/widgets/saving_transaction_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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


    /// ⚠️ SỬA LẠI ĐÚNG — TRUYỀN YEAR + MONTH
    await savingProv.fetch(year: year, month: month);

    await Future.wait([
      walletProv.fetch(),
      inProv.fetch(year: year, month: month),
      outProv.fetch(year: year, month: month),
      bankProv.fetch(year: year, month: month),
      budgetsProv.loadForMonth(year: year, month: month),
      incomeProv.fetch(year: year, month: month),
      investmentProv.fetch(),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
        walletProv.items.fold<double>(0, (s, w) => s + w.balance);

    final incomeProv = context.watch<IncomeProvider>();
    final incomes = incomeProv.items;

    final moneySettings = context.watch<MoneySettingsProvider>().settings;
    String fmt(num v) => MoneyFormatter(moneySettings).format(v);

    final inProv = context.watch<InInvoiceProvider>();
    final outProv = context.watch<OutInvoiceProvider>();
    final budgetsProv = context.watch<BudgetsProvider>();

    final num totalSpent =
        budgetsProv.items.fold<num>(0, (s, b) => s + b.spent);
    final num combinedRemaining = totalBalance - totalSpent;

    final bool overSpent =
        !(walletProv.loading || budgetsProv.loading) && combinedRemaining < 0;
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

    return RefreshIndicator(
      onRefresh: () async => _fetchCurrentYm(),
      child: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Tháng + Info =====
              Row(
                children: [
                  InkWell(
                    onTap: _openMonthPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Tháng ${ym.month.toString().padLeft(2, '0')} / ${ym.year}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.expand_more, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => _openAdviceSheet(
                        combinedRemaining: combinedRemaining,
                        dailyAllowance: dailyAllowance,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.primary, width: 1.7),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.info_outline_rounded,
                            size: 20, color: cs.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ===== Tổng tiền / Đã chi / Còn lại =====
              HeaderCard(
                title: t.totalAssets,
                totalText: _hideBalance
                    ? '•••'
                    : fmt(totalBalance), // Dùng totalBalance cho tổng tiền
                loading: walletProv.loading || budgetsProv.loading,
                paymentText: _hideBalance ? '•••' : fmt(totalSpent),
                trackingText: _hideBalance
                    ? '•••'
                    : fmt(
                        totalSaved), // Dùng combinedRemaining cho số tiền còn lại
                onToggleEye: _toggleHide,
                isHidden: _hideBalance,
              ),

              // ===== Cảnh báo vượt chi =====
              if (overSpent) ...[
                const SizedBox(height: 8),
                WarningBanner(
                  message: _hideBalance
                      ? 'Chi dự kiến tháng này đang vượt số tiền còn lại.'
                      : 'Chi dự kiến tháng này vượt quá số tiền còn lại ${fmt(deficit)}.',
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

              const SizedBox(height: 18),

              // ===== Danh sách TÀI KHOẢN =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tài khoản',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 24),
                    tooltip: 'Thêm tài khoản',
                    onPressed: () async {
                      final created = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => const CreateBankAccountForm(),
                      );
                      if (created == true && context.mounted) {
                        await _fetchCurrentYm();
                        safeShowSnackBar(
                          context,
                          const SnackBar(
                              content: Text('Đã thêm tài khoản mới')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (walletProv.loading && walletProv.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (!walletProv.loading && walletProv.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Chưa có tài khoản',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                )
              else
                Column(
                  children: walletProv.items.map((acc) {
                    return _WalletCard(
                      name: acc.name,
                      balanceText: _hideBalance ? '•••' : fmt(acc.balance),
                      isDefault: acc.isDefault,
                      icon: Icons.account_balance_wallet_rounded,
                      onEdit: () async {
                        final updated = await showModalBottomSheet<bool>(
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
                            child: EditBankAccountForm(
                              accountId: acc.id,
                              initialName: acc.name,
                              initialBankName: acc.bankname,
                              initialBankNumber: acc.banknumber,
                              initialBalance: acc.balance,
                              initialCurrency: acc.currency,
                            ),
                          ),
                        );
                        if (updated == true && context.mounted) {
                          await _fetchCurrentYm();
                        }
                      },
                    );
                  }).toList(),
                ),

              // ===== Danh sách Nguồn tiền =====
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nguồn tiền tháng này',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 24),
                    tooltip: 'Thêm nguồn thu',
                    onPressed: () async {
                      if (!isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                        return;
                      }
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
              ),
              const SizedBox(height: 8),
              if (incomeProv.loading && incomesToShow.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (!incomeProv.loading && incomesToShow.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Chưa có nguồn thu',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                )
              else
                Column(
                  children: incomesToShow.map((c) {
                    return _WalletCard(
                      name: c.title,
                      balanceText: _hideBalance ? '•••' : fmt(c.balance),
                      isDefault: false,
                      icon: Icons.savings_rounded,
                      onEdit: () async {
                        final int? incomeId = c.id;
                        if (incomeId == null) return;
                        final String initialTitle = (c.title).trim();
                        final String initialCurrency =
                            (c.currency.isEmpty) ? 'VND' : c.currency;
                        final updated = await showModalBottomSheet<bool>(
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
                            child: EditIncomeForm(
                              incomeId: incomeId,
                              initialTitle: initialTitle,
                              initialCurrency: initialCurrency,
                            ),
                          ),
                        );
                        if (updated == true && context.mounted) {
                          await _fetchCurrentYm();
                        }
                      },
                    );
                  }).toList(),
                ),

              // ===== Tiết kiệm =====
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiết kiệm',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 24),
                    tooltip: 'Thêm kế hoạch tiết kiệm',
                    onPressed: () async {
                      final created = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => const CreateSavingForm(),
                      );

                      if (created == true && context.mounted) {
                        final ym = context.read<YearMonthProvider>().ym;
                        await context
                            .read<SavingProvider>()
                            .fetch(year: ym.year, month: ym.month);

                        safeShowSnackBar(
                          context,
                          const SnackBar(
                              content: Text('Đã tạo kế hoạch tiết kiệm')),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Builder(builder: (_) {
                final savingProv = context.watch<SavingProvider>();

                if (savingProv.loading && savingProv.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }

                if (!savingProv.loading && savingProv.items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Chưa có kế hoạch tiết kiệm',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  );
                }

                return Column(
                  children: savingProv.items.map((s) {
                    final progress = (s.targetAmount > 0)
                        ? (s.currentAmount / s.targetAmount)
                        : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 6,
                            offset: Offset(0, 2),
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Row(
                                children: [
                                  // Nút sửa
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      final created =
                                          await showModalBottomSheet<bool>(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                        ),
                                        builder: (_) =>
                                            SavingTransactionForm(saving: s),
                                      );

                                      if (created == true && context.mounted) {
                                        final ym = context
                                            .read<YearMonthProvider>()
                                            .ym;
                                        await context
                                            .read<SavingProvider>()
                                            .fetch(
                                                year: ym.year, month: ym.month);

                                        context
                                            .read<BankAccountProvider>()
                                            .fetch();
                                      }
                                    },
                                  ),

                                  // Nút xoá tiết kiệm
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _confirmDeleteSaving(context, s.id!),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${fmt(s.currentAmount)} / ${fmt(s.targetAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: cs.surfaceVariant,
                            color: _progressColor(progress),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
              // ===== Đầu tư sinh lời =====
              // ===== Đầu tư sinh lời =====
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đầu tư sinh lời',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 24),
                    tooltip: 'Thêm khoản đầu tư',
                    onPressed: () async {
                      final created = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => const CreateInvestmentForm(),
                      );

                      if (created == true && context.mounted) {
                        context.read<InvestmentProvider>().fetch();
                        safeShowSnackBar(
                          context,
                          const SnackBar(content: Text('Đã thêm khoản đầu tư')),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Builder(
                builder: (_) {
                  final invProv = context.watch<InvestmentProvider>();
                  final items = invProv.items;

                  if (invProv.loading && items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    );
                  }

                  if (!invProv.loading && items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Chưa có khoản đầu tư',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((inv) {
                      final profit =
                          inv.currentPrice * inv.quantity - inv.totalInvested;
                      final profitPercent = profit / inv.totalInvested * 100;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                blurRadius: 6,
                                offset: Offset(0, 2),
                                color: Colors.black12),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profit >= 0
                                      ? "Lãi: +${profitPercent.toStringAsFixed(2)}%"
                                      : "Lỗ: ${profitPercent.toStringAsFixed(2)}%",
                                  style: TextStyle(
                                    color:
                                        profit >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // ===== Lịch sử giao dịch =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.transactionHistory,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/transactions',
                      arguments: {'year': ym.year, 'month': ym.month},
                    ),
                    child: Text(
                      t.viewAll,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (inProv.loading || outProv.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else
                Builder(builder: (_) {
                  final expenses = outProv.items;
                  final incomesTx = inProv.items;

                  if (expenses.isEmpty && incomesTx.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.noData,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    );
                  }

                  num sum(List list) =>
                      list.fold<num>(0, (s, tx) => s + (tx.amount as num));

                  return Column(
                    children: [
                      _SimpleTxItem(
                        title: 'Đã Chi',
                        color: const Color(0xFFD64545),
                        sign: '-',
                        total: sum(expenses),
                        type: 'expense',
                        moneySettings: moneySettings,
                        isHidden: _hideBalance,
                      ),
                      const SizedBox(height: 12),
                      _SimpleTxItem(
                        title: 'Đã Thu',
                        color: const Color(0xFF1F9D4C),
                        sign: '+',
                        total: sum(incomesTx),
                        type: 'income',
                        moneySettings: moneySettings,
                        isHidden: _hideBalance,
                      ),
                    ],
                  );
                }),
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
    final headerBg = cs.primary;
    final headerTitleBg = cs.tertiaryContainer;
    final onHeader = cs.onPrimary;
    final onHeaderTitle = cs.onTertiaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: headerTitleBg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: onHeaderTitle,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onToggleEye,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      isHidden ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: onHeaderTitle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              totalText,
              key: ValueKey(totalText),
              style: TextStyle(
                color: onHeader,
                fontSize: 36,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          if (loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: _Col(
                    label: 'Đã chi',
                    value: paymentText,
                    color: onHeader,
                  ),
                ),
                Container(width: 1.5, height: 24, color: onHeader),
                Expanded(
                  child: _Col(
                    label: 'Tiết kiệm',
                    value: trackingText,
                    color: onHeader,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF19999)),
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black12),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD64545)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B1E1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onFixBudgets,
                child: const Text('Điều chỉnh ngân sách'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onAddIncome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                ),
                child: const Text('Thêm nguồn thu'),
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
