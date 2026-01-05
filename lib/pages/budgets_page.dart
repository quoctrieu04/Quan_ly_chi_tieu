import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/auth/login.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/l10n/app_localizations.dart';

// mở trang Cài đặt Ngân sách
import 'setting/money_settings_page.dart';

// provider
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import '../core/budget/budgets_provider.dart';

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

/// tiện ích: làm sáng/tối màu để tạo gradient từ primary
Color _lighter(Color c, [double amount = .14]) {
  final hsl = HSLColor.fromColor(c);
  final l = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(l).toColor();
}

Color _darker(Color c, [double amount = .18]) {
  final hsl = HSLColor.fromColor(c);
  final l = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(l).toColor();
}

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  static const double _radius = 20;
  static const double _hPad = 16;
  static const double _vGap = 20;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      final authed = context.read<AuthProvider>().isAuthenticated;
      if (authed) {
        final ym = context.read<YearMonthProvider>().ym;
        context.read<CategoryProvider>().refresh();
        context
            .read<BudgetsProvider>()
            .loadForMonth(year: ym.year, month: ym.month);
      }
      _loadedOnce = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final totalBalance =
        context.select<BankAccountProvider, num>((w) => w.totalBalance);
    final totalAssigned =
        context.select<BudgetsProvider, num>((b) => b.totalAssigned);

    final unassigned = totalBalance - totalAssigned;
    final authed = context.select<AuthProvider, bool>((a) => a.isAuthenticated);

    final cs = Theme.of(context).colorScheme;
    final ym = context.watch<YearMonthProvider>().ym;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MoneySettingsPage()),
            );
          },
          color: cs.onPrimary,
        ),
        centerTitle: true,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: _MonthPill(
          label: _formatMonthYear(context, ym),
          onTap: () async {
            final picked = await showModalBottomSheet<DateTime>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => MonthPickerSheet(
                initial: ym,
                min: DateTime(2020, 1),
                max: DateTime(2035, 12),
              ),
            );
            if (picked != null && mounted) {
              context
                  .read<YearMonthProvider>()
                  .setYm(picked); // chỉ set ⇒ listeners reload
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: t.editCategories,
            onPressed: _openManageCategories,
            color: cs.onPrimary,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          onRefresh: _reloadAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(_hPad),
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
  }) {
    final cs = Theme.of(context).colorScheme;
    final walletLoading =
        context.select<BankAccountProvider, bool>((w) => w.loading);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_darker(cs.primary), _lighter(cs.primary)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _infoBox(context, t.moneyAssigned, assigned),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoBox(context, t.moneyUnassigned, unassigned),
                      ),
                    ],
                  ),
                  if (unassigned < 0) ...[
                    const SizedBox(height: 12),
                    _negativeBanner(context, debt: -unassigned),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAssignPressed,
                      icon: const Icon(Icons.task_alt),
                      label: Text(t.assignMoneyCta),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.onPrimary,
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: walletLoading
                ? Container(
                    key: const ValueKey('overlay'),
                    color: Colors.black.withOpacity(0.05),
                    alignment: Alignment.center,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(.9),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(BuildContext context, String label, num value) {
    final cs = Theme.of(context).colorScheme;
    final isNegative = value < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onPrimary, fontSize: 14),
        ),
        const SizedBox(height: 6),
        MoneyText(
          value,
          style: TextStyle(
            color: isNegative ? cs.errorContainer : cs.onPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _negativeBanner(BuildContext context, {required num debt}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: cs.onErrorContainer, fontSize: 13.5),
                children: [
                  const TextSpan(text: 'Đã phân bổ vượt số dư. Thiếu '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2, right: 2),
                      child: MoneyText(
                        debt,
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' để cân bằng tháng này.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                t.createCategoryTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: t.createMyOwn,
                onPressed: _openCreateCategory,
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
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

/// Pill hiển thị tháng/năm
class _MonthPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MonthPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _darker(cs.primary, .1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onPrimary.withOpacity(.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: cs.onPrimary, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet chọn tháng
class MonthPickerSheet extends StatefulWidget {
  final DateTime initial, min, max;
  const MonthPickerSheet({
    super.key,
    required this.initial,
    required this.min,
    required this.max,
  });

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _year > widget.min.year
                    ? () => setState(() => _year--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '$_year',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: _year < widget.max.year
                    ? () => setState(() => _year++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.7,
            children: List.generate(12, (i) {
              final m = i + 1;
              final dt = DateTime(_year, m);
              final enabled = dt.isAfter(
                      DateTime(widget.min.year, widget.min.month - 1)) &&
                  dt.isBefore(DateTime(widget.max.year, widget.max.month + 1));

              final monthName = DateFormat.MMMM(locale).format(dt);
              final label =
                  Localizations.of<AppLocalizations>(context, AppLocalizations)!
                              .localeName ==
                          'vi'
                      ? t.monthGridLabel(m.toString())
                      : monthName;

              final isSelected =
                  _year == widget.initial.year && m == widget.initial.month;

              return OutlinedButton(
                onPressed: enabled ? () => Navigator.pop(context, dt) : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black12,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
