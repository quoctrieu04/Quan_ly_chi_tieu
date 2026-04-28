import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/auth/login.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/l10n/app_localizations.dart';

// provider
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import '../core/budget/budgets_provider.dart';
import 'package:chitieu/pages/setting/settings_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';

// hiển thị tiền
import '../core/money/widgets/money_text.dart';

// TRANG TẠO DANH MỤC
import 'budget_edit_page.dart';

// Category
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';

// QUẢN LÝ DANH MỤC
import 'package:chitieu/core/budget/category/category_manage_page.dart';

// TRANG PHÂN BỔ TIỀN
import 'allocate_money_page.dart';

// TRANG CHI TIẾT DANH MỤC
import 'package:chitieu/core/budget/category/category_detail_page.dart';

// === NEW: widget danh mục có thanh tiến trình + cảnh báo
import 'package:chitieu/core/budget/widgets/budget_category_tile.dart';

// NEW: dùng chung tháng/năm
import 'package:chitieu/core/date/year_month_provider.dart';
import 'package:chitieu/widgets/app_page_header.dart';
import 'package:chitieu/widgets/app_month_picker_sheet.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  static const double _radius = 20;
  static const double _hPad = 16;
  static const double _vGap = 12;
  static const double _maxContentWidth = 640;

  bool _loadedOnce = false;

  // === Theo dõi thay đổi trạng thái đăng nhập để auto reload ===
  bool _wasAuthed = false;

  void _onAuthChanged() {
    final authed = context.read<AuthProvider>().isAuthenticated;
    if (authed && !_wasAuthed) {
      _reloadAll();
    }
    _wasAuthed = authed;
  }

  void _onYmChanged() {
    if (!mounted) return;
    final ym = context.read<YearMonthProvider>().ym;
    context
        .read<BudgetsProvider>()
        .loadForMonth(year: ym.year, month: ym.month);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      _wasAuthed = auth.isAuthenticated;
      auth.addListener(_onAuthChanged);
      context.read<YearMonthProvider>().addListener(_onYmChanged);

      // Tải dữ liệu ban đầu một cách an toàn (tránh lỗi setState during build)
      if (_wasAuthed) {
        final ym = context.read<YearMonthProvider>().ym;
        context.read<CategoryProvider>().refresh();
        context
            .read<BudgetsProvider>()
            .loadForMonth(year: ym.year, month: ym.month);
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<AuthProvider>().removeListener(_onAuthChanged);
      context.read<YearMonthProvider>().removeListener(_onYmChanged);
    } catch (_) {}
    super.dispose();
  }

  // ===== Helper: đảm bảo đã đăng nhập (có hỏi người dùng nếu chưa) =====
  Future<bool> _ensureAuthed(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return true;

    final t = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.needLogin),
        content: Text(t.needLoginBudgets),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.login),
          ),
        ],
      ),
    );

    if (go != true || !context.mounted) return false;

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );

    final authedNow =
        ok == true && context.read<AuthProvider>().isAuthenticated;

    if (authedNow && context.mounted) {
      await _reloadAll();
    }

    return authedNow;
  }

  Future<void> _openCreateCategory() async {
    final ok = await _ensureAuthed(context);
    if (!ok || !mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => const BudgetEditPage(
                type: '',
              )),
    );

    if (created == true && mounted) {
      await context.read<CategoryProvider>().refresh();
    }
  }

  Future<void> _openManageCategories() async {
    final ok = await _ensureAuthed(context);
    if (!ok || !mounted) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CategoryManagePage()),
    );
    if (changed == true && mounted) {
      await context.read<CategoryProvider>().refresh();
    }
  }

  Future<void> _openBudgetActions(
      Future<void> Function() openMonthPicker) async {
    final t = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(t.selectMonth),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    openMonthPicker();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(t.editCategories),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openManageCategories();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reloadAll() async {
    final futures = <Future<void>>[];
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final ym = context.read<YearMonthProvider>().ym;

    final wallet = context.read<BankAccountProvider>();
    if (!wallet.loading)
      futures.add(wallet.fetch(year: ym.year, month: ym.month));

    final cat = context.read<CategoryProvider>();
    if (!cat.loading) futures.add(cat.refresh());

    final budgets = context.read<BudgetsProvider>();
    futures.add(budgets.loadForMonth(year: ym.year, month: ym.month));

    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  /// MỞ TRANG PHÂN BỔ TIỀN
  Future<void> _openAllocateMoney(num available) async {
    final ok = await _ensureAuthed(context);
    if (!ok || !mounted) return;

    final ym = context.read<YearMonthProvider>().ym;

    final catProv = context.read<CategoryProvider>();
    await catProv.refresh();
    final categories = catProv.items;

    final budProv = context.read<BudgetsProvider>();
    await budProv.loadForMonth(year: ym.year, month: ym.month);

    final initialAssigned = <int, num>{
      for (final it in budProv.items)
        it.categoryId:
            (it.amount > 0 ? it.amount : (it as dynamic).amount ?? 0) as num
    };

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllocateMoneyPage(
          available: (available > 0 ? available : 0).toDouble(),
          categories: categories,
          initialAssigned: initialAssigned,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await budProv.loadForMonth(year: ym.year, month: ym.month);
      await context
          .read<BankAccountProvider>()
          .fetch(year: ym.year, month: ym.month);
      setState(() {});
      return;
    }

    if (result is Map) {
      final allocations = <int, double>{};
      result.forEach((k, v) {
        int id;
        if (k is int) {
          id = k;
        } else if (k is Category) {
          id = k.id;
        } else {
          id = int.tryParse(k.toString()) ?? 0;
        }
        if (id > 0) allocations[id] = (v as num).toDouble();
      });

      try {
        await budProv.assignMany(
          year: ym.year,
          month: ym.month,
          allocations: allocations,
        );

        await budProv.loadForMonth(year: ym.year, month: ym.month);
        await context
            .read<BankAccountProvider>()
            .fetch(year: ym.year, month: ym.month);
        setState(() {});
      } catch (e) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.errorGeneric}: $e')),
        );
      }
    }
  }

  // Removed didChangeDependencies to prevent state modification during build phase when Theme changes

  @override
  Widget build(BuildContext context) {
    // Ép BudgetsPage luôn build lại khi thay đổi màu chủ đạo ở SettingsProvider
    context.watch<SettingsProvider>();

    final t = AppLocalizations.of(context)!;

    final totalBalance =
        context.select<BankAccountProvider, num>((w) => w.totalBalance);
    final totalAssigned =
        context.select<BudgetsProvider, num>((b) => b.totalAssigned);

    final unassigned = totalBalance - totalAssigned;
    final authed = context.select<AuthProvider, bool>((a) => a.isAuthenticated);

    final cs = Theme.of(context).colorScheme;
    final ym = context.watch<YearMonthProvider>().ym;
    Future<void> openMonthPicker() async {
      final picked = await showAppMonthPicker(
        context: context,
        initial: ym,
        min: DateTime(2020, 1),
        max: DateTime(2035, 12),
      );
      if (picked != null && mounted) {
        context.read<YearMonthProvider>().setYm(picked);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      appBar: AppPageHeaderBar(
        icon: Icons.wallet_rounded,
        title: t.tabBudgets,
        subtitle: _formatMonthYear(context, ym),
        onTap: openMonthPicker,
        actions: [
          HeaderIconButton(
            icon: Icons.more_vert_rounded,
            tooltip: 'Tuỳ chọn',
            onPressed: () => _openBudgetActions(openMonthPicker),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          onRefresh: _reloadAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 8),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    children: [
                      _overviewCard(
                        context,
                        t,
                        totalAssigned,
                        unassigned,
                        onAssignPressed: () => _openAllocateMoney(
                          unassigned > 0 ? unassigned : 0,
                        ),
                        onCreateCategoryPressed: _openCreateCategory,
                      ),
                      const SizedBox(height: _vGap),
                      if (authed)
                        _categorySection(context, t, ym)
                      else
                        _askLoginCard(context, t),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewCard(
    BuildContext context,
    AppLocalizations t,
    num assigned,
    num unassigned, {
    required VoidCallback onAssignPressed,
    required VoidCallback onCreateCategoryPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // Tính toán thanh tiến trình chung
    final total = assigned + (unassigned > 0 ? unassigned : 0);
    final percent = total > 0 ? (assigned / total).clamp(0.0, 1.0) : 0.0;

    // Màu sắc neo-fintech theo ảnh thiết kế
    final primaryDark = isDark ? Colors.white : AppColors.primaryDark;
    final actionColor = cs.primary;
    final textMuted = isDark ? Colors.white60 : const Color(0xFF64748B);
    final cardBg1 =
        isDark ? const Color(0xFF1E293B) : Colors.white; // Thẻ "ALLOCATED"
    final cardBg2 =
        isDark ? const Color(0xFF1E293B) : Colors.white; // Thẻ "UNALLOCATED"
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.2)
        : const Color(0xFF0F172A).withOpacity(0.06);

    // Tính trạng ví
    final walletLoading =
        context.select<BankAccountProvider, bool>((w) => w.loading);

    return Stack(
      children: [
        Column(
          children: [
            // --- TOP ROW: HAI THẺ ĐÃ PHÂN BỔ VÀ CHƯA PHÂN BỔ ---
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // THẺ 1: ĐÃ PHÂN BỔ (ALLOCATED)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg1,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ĐÃ CÓ KẾ HOẠCH',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: MoneyText(
                                    assigned,
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Thanh Progress nhỏ
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 4, // Rất mỏng gọn gàng
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation(primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // THẺ 2: CHƯA PHÂN BỔ (UNALLOCATED)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg2,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CÒN LẠI',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: MoneyText(
                                    unassigned,
                                    style: TextStyle(
                                      color: unassigned < 0
                                          ? const Color(0xFFDC2626)
                                          : primaryDark.withOpacity(0.85),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Nhãn phụ: Safe to Save
                          Row(
                            children: [
                              Icon(
                                unassigned < 0
                                    ? Icons.warning_rounded
                                    : Icons.trending_up_rounded,
                                size: 15,
                                color: unassigned < 0
                                    ? const Color(0xFFDC2626)
                                    : primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  unassigned < 0
                                      ? 'Thâm hụt!'
                                      : 'An toàn dự trữ',
                                  style: TextStyle(
                                    color: unassigned < 0
                                        ? const Color(0xFFDC2626)
                                        : primaryDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: onAssignPressed,
                      icon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                      ),
                      label: Text(
                        'Lên kế hoạch',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: cs.onPrimary,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: onCreateCategoryPressed,
                      icon: const Icon(Icons.add_chart_rounded, size: 18),
                      label: Text(
                        t.createMyOwn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: actionColor,
                        side: BorderSide(color: actionColor.withOpacity(.55)),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Lớp phủ loading nếu đang fetch tiền
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: walletLoading
                ? Container(
                    key: const ValueKey('overlay'),
                    color: surfaceColor(context).withOpacity(0.3),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                      ),
                      child: CircularProgressIndicator(color: primaryDark),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ),
      ],
    );
  }

  Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white;

  Widget _askLoginCard(BuildContext context, AppLocalizations t) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Card(
      color: cs.secondaryContainer.withOpacity(.3),
      elevation: 0.5,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              t.needLogin,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              t.needLoginContent,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(
      BuildContext context, AppLocalizations t, DateTime ym) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cat = context.watch<CategoryProvider>();

    if (cat.loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (cat.items.isEmpty) {
      return Card(
        color: cs.secondaryContainer.withOpacity(.3),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                t.createCategoryTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                t.createCategoryDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openCreateCategory,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(t.createMyOwn),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...cat.items.map((c) => _categoryTile(context, c, ym)).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Liên kết Category với BudgetItem theo categoryId
  Widget _categoryTile(BuildContext context, Category c, DateTime ym) {
    final budgets = context.watch<BudgetsProvider>();

    final item = budgets.items.firstWhere(
      (b) => b.categoryId == c.id,
      orElse: () => BudgetItem(
        id: 0,
        userId: 0,
        categoryId: c.id.toInt(),
        name: c.name,
        year: ym.year,
        month: ym.month,
        amount: 0,
        spent: 0,
      ),
    );

    return BudgetCategoryTile(
      category: c,
      item: item,
      onTap: () async {
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => CategoryDetailPage(
              category: c,
              year: ym.year,
              month: ym.month,
              initialLimit: item.amount.toDouble(),
            ),
          ),
        );

        if (updated == true && context.mounted) {
          await context.read<CategoryProvider>().refresh();
          await context
              .read<BudgetsProvider>()
              .loadForMonth(year: ym.year, month: ym.month);
          setState(() {});
        }
      },
    );
  }

  String _formatMonthYear(BuildContext ctx, DateTime ym) {
    final locale = Localizations.localeOf(ctx).toLanguageTag();
    final t = AppLocalizations.of(ctx)!;
    final monthName = DateFormat.MMMM(locale).format(ym);
    final year = DateFormat.y(locale).format(ym);
    return t.monthYearTitle(monthName, year);
  }
}
