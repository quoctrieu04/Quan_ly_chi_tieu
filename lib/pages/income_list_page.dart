import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/widgets/create_income_form.dart';
import 'package:chitieu/widgets/edit_income_form.dart';
import 'package:chitieu/core/date/year_month_provider.dart';

// ── Design tokens ──
const _kMint = AppColors.primary;
const _kMintLight = AppColors.primaryLight;

class IncomeListPage extends StatelessWidget {
  const IncomeListPage({super.key});

  // ── Icon map loại thu nhập ──
  IconData _incomeIcon(String title) {
    final n = title.toLowerCase();
    if (n.contains('lương') || n.contains('salary')) return Icons.work_rounded;
    if (n.contains('thưởng') || n.contains('bonus'))
      return Icons.card_giftcard_rounded;
    if (n.contains('đầu tư') || n.contains('invest'))
      return Icons.trending_up_rounded;
    if (n.contains('cho thuê') || n.contains('rent')) return Icons.home_rounded;
    if (n.contains('freelance')) return Icons.laptop_mac_rounded;
    if (n.contains('bán') || n.contains('sell'))
      return Icons.storefront_rounded;
    if (n.contains('lãi') || n.contains('interest'))
      return Icons.account_balance_rounded;
    return Icons.attach_money_rounded;
  }

  // ── Color cho từng loại ──
  Color _incomeColor(String title) {
    final n = title.toLowerCase();
    if (n.contains('lương') || n.contains('salary')) return _kMint;
    if (n.contains('thưởng') || n.contains('bonus'))
      return const Color(0xFFF59E0B);
    if (n.contains('đầu tư') || n.contains('invest'))
      return const Color(0xFF8B5CF6);
    if (n.contains('cho thuê') || n.contains('rent'))
      return const Color(0xFF3B82F6);
    if (n.contains('freelance')) return const Color(0xFFEC4899);
    return _kMint;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<IncomeProvider>();
    final items = prov.items;
    final ym = context.read<YearMonthProvider>().ym;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1419) : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C2530) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Nguồn tiền',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(.06)
                : const Color(0xFFEEEFF3),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: _kMint, size: 24),
              tooltip: 'Thêm nguồn tiền',
              onPressed: () async {
                final created = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreateIncomeForm(),
                );
                if (created == true && context.mounted) {
                  await prov.fetch(year: ym.year, month: ym.month);
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: _kMint.withOpacity(.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState(context, prov, ym, isDark)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // ── Income cards ──
                ...items.asMap().entries.map((e) {
                  final i = e.key;
                  final inc = e.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (i * 80)),
                    tween: Tween(begin: 0, end: 1),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child:
                          _buildIncomeCard(context, inc, cs, isDark, prov, ym),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  // ═══════════════════════════
  //  HERO CARD
  // ═══════════════════════════
  Widget _buildHeroCard(int count, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2530) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3544) : AppColors.border,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kMint.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: _kMint,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nguồn thu nhập',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count nguồn đang hoạt động',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textMain,
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

  // ═══════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════
  Widget _buildEmptyState(
      BuildContext context, IncomeProvider prov, dynamic ym, bool isDark) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0, end: 1),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - v)),
            child: child,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated rings
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kMint.withOpacity(.04),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kMint.withOpacity(.08),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _kMint.withOpacity(.15),
                          _kMintLight.withOpacity(.1)
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 24,
                      color: _kMint.withOpacity(.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có nguồn tiền',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? Colors.white.withOpacity(.7)
                    : const Color(0xFF1A2332),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm nguồn thu nhập để bắt đầu\nquản lý tài chính hiệu quả',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark
                    ? Colors.white.withOpacity(.4)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () async {
                final created = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreateIncomeForm(),
                );
                if (created == true && context.mounted) {
                  await prov.fetch(year: ym.year, month: ym.month);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kMint, _kMintLight],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: _kMint.withOpacity(.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Thêm nguồn tiền',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  INCOME CARD
  // ═══════════════════════════
  Widget _buildIncomeCard(BuildContext context, dynamic inc, ColorScheme cs,
      bool isDark, IncomeProvider prov, dynamic ym) {
    final color = _incomeColor(inc.title ?? '');
    final icon = _incomeIcon(inc.title ?? '');

    return Material(
      color: isDark ? const Color(0xFF1C2530) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3544) : AppColors.border,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: color.withOpacity(.1),
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inc.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A2332),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Khoản thu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                onSelected: (v) async {
                  if (v == 'edit') {
                    final updated = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => EditIncomeForm(
                        incomeId: inc.id!,
                        initialTitle: inc.title,
                        initialCurrency: inc.currency,
                      ),
                    );
                    if (updated == true && context.mounted) {
                      await prov.fetch(year: ym.year, month: ym.month);
                    }
                  }

                  if (v == 'delete') {
                    await _confirmDelete(context, inc, prov, ym, cs);
                  }
                },
                icon: Icon(Icons.more_vert_rounded,
                    color: isDark
                        ? Colors.white.withOpacity(.3)
                        : const Color(0xFF94A3B8),
                    size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: _kMint),
                        const SizedBox(width: 10),
                        const Text('Sửa',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: cs.error),
                        const SizedBox(width: 10),
                        Text('Xóa',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: cs.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  DELETE DIALOG
  // ═══════════════════════════
  Future<void> _confirmDelete(BuildContext context, dynamic inc,
      IncomeProvider prov, dynamic ym, ColorScheme cs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Xóa nguồn tiền',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${inc.title}"?',
          style: TextStyle(
            color: cs.onSurface.withOpacity(.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await prov.deleteIncomeCategory(inc.id!);
      if (success) {
        await prov.fetch(year: ym.year, month: ym.month);
      }
    }
  }
}
