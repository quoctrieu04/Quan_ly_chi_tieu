import 'dart:math' show pi;
import 'dart:ui';

import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/auth/login.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:chitieu/core/theme/app_colors.dart';
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

// === widget danh mục
import 'package:chitieu/core/budget/widgets/budget_category_tile.dart';

// dùng chung tháng/năm
import 'package:chitieu/core/date/year_month_provider.dart';

// ── Mint / Teal Design Tokens ──────────────────────
const _kMint       = Color(0xFF2EC4B6); // primary mint
const _kMintLight  = Color(0xFF5DE8DA); // gradient end
const _kMintDark   = Color(0xFF1A9E92); // dark accent
const _kMintSurface= Color(0xFFE6FAF7); // tinted surface
const _kBg         = Color(0xFFF5F7FA); // cool gray bg
const _kCard       = Colors.white;
const _kText       = Color(0xFF1A2332); // dark text
const _kTextSub    = Color(0xFF7B8794); // muted gray
const _kBorder     = Color(0xFFE8ECF0);
// dark mode
const _kDarkBg     = Color(0xFF0F1419);
const _kDarkCard   = Color(0xFF1C2530);
const _kDarkBorder = Color(0xFF2A3544);
const _kDarkText   = Color(0xFFE8ECF0);
const _kDarkTextSub= Color(0xFF7B8794);

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  static const double _hPad = 20;
  static const double _maxContentWidth = 640;

  bool _loadedOnce = false;
  bool _wasAuthed = false;

  void _onAuthChanged() {
    final authed = context.read<AuthProvider>().isAuthenticated;
    if (authed && !_wasAuthed) _reloadAll();
    _wasAuthed = authed;
  }

  void _onYmChanged() {
    if (!mounted) return;
    final ym = context.read<YearMonthProvider>().ym;
    context.read<BudgetsProvider>().loadForMonth(year: ym.year, month: ym.month);
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

  Future<bool> _ensureAuthed(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return true;
    final t = AppLocalizations.of(context);
    if (t == null) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.needLogin),
        content: Text(t.needLoginBudgets),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.login)),
        ],
      ),
    );
    if (go != true || !context.mounted) return false;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    final authedNow = ok == true && context.read<AuthProvider>().isAuthenticated;
    if (authedNow && context.mounted) await _reloadAll();
    return authedNow;
  }

  Future<void> _openCreateCategory() async {
    final ok = await _ensureAuthed(context);
    if (!ok || !mounted) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BudgetEditPage(type: '')),
    );
    if (created == true && mounted) await context.read<CategoryProvider>().refresh();
  }

  Future<void> _openManageCategories() async {
    final ok = await _ensureAuthed(context);
    if (!ok || !mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CategoryManagePage()),
    );
    if (changed == true && mounted) await context.read<CategoryProvider>().refresh();
  }

  Future<void> _reloadAll() async {
    final futures = <Future<void>>[];
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final ym = context.read<YearMonthProvider>().ym;
    final wallet = context.read<BankAccountProvider>();
    if (!wallet.loading) futures.add(wallet.fetch(year: ym.year, month: ym.month));
    final cat = context.read<CategoryProvider>();
    if (!cat.loading) futures.add(cat.refresh());
    final budgets = context.read<BudgetsProvider>();
    futures.add(budgets.loadForMonth(year: ym.year, month: ym.month));
    await Future.wait(futures);
    if (mounted) setState(() {});
  }

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
        it.categoryId: (it.amount > 0 ? it.amount : (it as dynamic).amount ?? 0) as num
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
      await context.read<BankAccountProvider>().fetch(year: ym.year, month: ym.month);
      setState(() {});
      return;
    }
    if (result is Map) {
      final allocations = <int, double>{};
      result.forEach((k, v) {
        int id;
        if (k is int) { id = k; }
        else if (k is Category) { id = k.id; }
        else { id = int.tryParse(k.toString()) ?? 0; }
        if (id > 0) allocations[id] = (v as num).toDouble();
      });
      try {
        await budProv.assignMany(year: ym.year, month: ym.month, allocations: allocations);
        await budProv.loadForMonth(year: ym.year, month: ym.month);
        await context.read<BankAccountProvider>().fetch(year: ym.year, month: ym.month);
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t?.errorGeneric ?? 'Lỗi'}: $e')),
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
        context.read<BudgetsProvider>().loadForMonth(year: ym.year, month: ym.month);
      }
      _loadedOnce = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final totalBalance = context.select<BankAccountProvider, num>((w) => w.totalBalance);
    final totalAssigned = context.select<BudgetsProvider, num>((b) => b.totalAssigned);
    final unassigned = totalBalance - totalAssigned;
    final authed = context.select<AuthProvider, bool>((a) => a.isAuthenticated);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ym = context.watch<YearMonthProvider>().ym;

    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _kMint,
          onRefresh: _reloadAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, t, isDark, ym)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 120),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _heroCard(context, t, totalAssigned, unassigned, isDark),
                          const SizedBox(height: 28),
                          if (authed) _categorySection(context, t, ym, isDark)
                          else _askLoginCard(context, t, isDark),
                        ],
                      ),
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

  // ═══════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════
  Widget _buildHeader(BuildContext context, AppLocalizations t, bool isDark, DateTime ym) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.settings_rounded,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MoneySettingsPage()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
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
                  context.read<YearMonthProvider>().setYm(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? _kDarkCard : _kCard,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: isDark ? _kDarkBorder : _kBorder),
                  boxShadow: isDark ? [] : [
                    BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 16, color: _kMint),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatMonthYear(context, ym),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: isDark ? _kDarkText : _kText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _kTextSub),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CircleBtn(
            icon: Icons.tune_rounded,
            isDark: isDark,
            onTap: _openManageCategories,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  HERO CARD – Mint gradient
  // ═══════════════════════════════════════
  Widget _heroCard(BuildContext context, AppLocalizations t, num assigned, num unassigned, bool isDark) {
    final walletLoading = context.select<BankAccountProvider, bool>((w) => w.loading);
    final total = assigned + (unassigned > 0 ? unassigned : 0);
    final pct = total > 0 ? (assigned / total).clamp(0.0, 1.0) : 0.0;
    final displayPct = (pct * 100).toInt();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F2D28), const Color(0xFF0A1F1C)]
                  : [_kMint, _kMintLight],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kMint.withOpacity(isDark ? .15 : .28),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: Label + Donut ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã lên kế hoạch',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.65),
                            fontSize: 13, fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        MoneyText(
                          assigned,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30, fontWeight: FontWeight.w900,
                            letterSpacing: -1.2, height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Donut
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: pct),
                      builder: (_, value, __) => CustomPaint(
                        painter: _DonutPainter(
                          progress: value,
                          trackColor: Colors.white.withOpacity(.15),
                          fillColor: Colors.white,
                          strokeWidth: 5,
                        ),
                        child: Center(
                          child: Text('$displayPct%',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.w900, letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // ── Divider ──
              Container(height: 1, color: Colors.white.withOpacity(.12)),
              const SizedBox(height: 14),
              // ── Bottom: Unassigned + CTA ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chưa dùng',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.55),
                            fontSize: 11.5, fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        MoneyText(
                          unassigned,
                          style: TextStyle(
                            color: unassigned < 0 ? const Color(0xFFFF8A8A) : Colors.white.withOpacity(.9),
                            fontSize: 17, fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openAllocateMoney(unassigned > 0 ? unassigned : 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white.withOpacity(.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pie_chart_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Phân bổ',
                            style: TextStyle(
                              color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.w700, letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── Over budget ──
        if (unassigned < 0) ...[
          // rendered below
        ],
        // Loading
        if (walletLoading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: Colors.black.withOpacity(.2),
                  alignment: Alignment.center,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black54 : _kCard,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 12)],
                    ),
                    padding: const EdgeInsets.all(9),
                    child: const CircularProgressIndicator(strokeWidth: 2.5, color: _kMint),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _askLoginCard(BuildContext context, AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: isDark ? _kDarkCard : _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? _kDarkBorder : _kBorder),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0, end: 1),
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
            ),
            child: Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                color: _kMint.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 30, color: _kMint),
            ),
          ),
          const SizedBox(height: 20),
          Text(t.needLogin,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800,
              color: isDark ? _kDarkText : _kText, letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(t.needLoginContent,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: _kTextSub, height: 1.55),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  CATEGORY SECTION
  // ═══════════════════════════════════════
  Widget _categorySection(BuildContext context, AppLocalizations t, DateTime ym, bool isDark) {
    final cat = context.watch<CategoryProvider>();

    if (cat.loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kMint)),
      );
    }

    if (cat.items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? _kDarkCard : _kCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? _kDarkBorder : _kBorder),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _kMint.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.category_rounded, size: 28, color: _kMint),
              ),
              const SizedBox(height: 16),
              Text(t.createCategoryTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: isDark ? _kDarkText : _kText, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(t.createCategoryDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: _kTextSub, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _openCreateCategory,
                  style: TextButton.styleFrom(
                    backgroundColor: _kMint,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(t.createMyOwn,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(t.createCategoryTitle,
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: isDark ? _kDarkText : _kText, letterSpacing: -0.8,
                ),
              ),
            ),
            GestureDetector(
              onTap: _openCreateCategory,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kMint, _kMintLight]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _kMint.withOpacity(.25), blurRadius: 10, offset: const Offset(0, 3), spreadRadius: -2),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...cat.items.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 250 + (i * 70)),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: _categoryTile(context, c, ym),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _categoryTile(BuildContext context, Category c, DateTime ym) {
    final budgets = context.watch<BudgetsProvider>();
    final item = budgets.items.firstWhere(
      (b) => b.categoryId == c.id,
      orElse: () => BudgetItem(
        id: 0, userId: 0, categoryId: c.id.toInt(),
        name: c.name, year: ym.year, month: ym.month,
        amount: 0, spent: 0,
      ),
    );

    return BudgetCategoryTile(
      category: c,
      item: item,
      onTap: () async {
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => CategoryDetailPage(
              category: c, year: ym.year, month: ym.month,
              initialLimit: item.amount.toDouble(),
            ),
          ),
        );
        if (updated == true && context.mounted) {
          await context.read<CategoryProvider>().refresh();
          await context.read<BudgetsProvider>().loadForMonth(year: ym.year, month: ym.month);
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

// ═══════════════════════════════════════
//  Circle Button
// ═══════════════════════════════════════
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: isDark ? _kDarkCard : _kCard,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? _kDarkBorder : _kBorder),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 19, color: _kTextSub),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  MONTH PICKER SHEET
// ═══════════════════════════════════════
class MonthPickerSheet extends StatefulWidget {
  final DateTime initial, min, max;
  const MonthPickerSheet({super.key, required this.initial, required this.min, required this.max});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _kDarkCard : _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _YearBtn(icon: Icons.chevron_left_rounded,
                onPressed: _year > widget.min.year ? () => setState(() => _year--) : null, isDark: isDark),
              Text('$_year',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: isDark ? _kDarkText : _kText, letterSpacing: -0.5,
                ),
              ),
              _YearBtn(icon: Icons.chevron_right_rounded,
                onPressed: _year < widget.max.year ? () => setState(() => _year++) : null, isDark: isDark),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.3,
            children: List.generate(12, (i) {
              final m = i + 1;
              final dt = DateTime(_year, m);
              final enabled = dt.isAfter(DateTime(widget.min.year, widget.min.month - 1)) &&
                  dt.isBefore(DateTime(widget.max.year, widget.max.month + 1));
              final monthName = DateFormat.MMMM(locale).format(dt);
              final label = Localizations.of<AppLocalizations>(context, AppLocalizations)!.localeName == 'vi'
                  ? t.monthGridLabel(m.toString()) : monthName;
              final isSelected = _year == widget.initial.year && m == widget.initial.month;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled ? () => Navigator.pop(context, dt) : null,
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [_kMint, _kMintLight])
                          : null,
                      color: isSelected ? null
                          : enabled ? (isDark ? Colors.white.withOpacity(.05) : const Color(0xFFF5F7FA))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white
                            : enabled ? (isDark ? Colors.white.withOpacity(.8) : _kText)
                            : (isDark ? Colors.white.withOpacity(.15) : Colors.black.withOpacity(.18)),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _YearBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDark;
  const _YearBtn({required this.icon, required this.onPressed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(enabled ? .06 : .02)
              : (enabled ? const Color(0xFFF5F7FA) : const Color(0xFFF5F7FA).withOpacity(.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22,
          color: enabled
              ? (isDark ? Colors.white.withOpacity(.7) : _kText)
              : (isDark ? Colors.white.withOpacity(.15) : Colors.black.withOpacity(.15)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  DONUT PAINTER
// ═══════════════════════════════════════
class _DonutPainter extends CustomPainter {
  final double progress;
  final Color trackColor, fillColor;
  final double strokeWidth;
  _DonutPainter({required this.progress, required this.trackColor, required this.fillColor, this.strokeWidth = 7});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, 2 * pi, false,
      Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    if (progress > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0.0, 1.0), false,
        Paint()..color = fillColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.trackColor != trackColor || old.fillColor != fillColor;
}
