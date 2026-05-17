import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/widgets/edit_bank_account_form.dart';
import 'package:chitieu/widgets/create_bank_account_form.dart';

import 'package:intl/intl.dart';

String formatMoney(num v) {
  final f = NumberFormat('#,###', 'vi_VN');
  return f.format(v);
}

class AccountsListPage extends StatefulWidget {
  const AccountsListPage({super.key});

  @override
  State<AccountsListPage> createState() => _AccountsListPageState();
}

class _AccountsListPageState extends State<AccountsListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.microtask(() {
      context.read<BankAccountProvider>().fetchAccounts();
    });
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Icon map ngân hàng ──
  IconData _bankIcon(String? bankname) {
    final n = (bankname ?? '').toLowerCase();
    if (n.contains('vietcombank') || n.contains('vcb'))
      return Icons.account_balance_rounded;
    if (n.contains('techcombank') || n.contains('tcb'))
      return Icons.account_balance_rounded;
    if (n.contains('momo')) return Icons.phone_android_rounded;
    if (n.contains('cash') || n.contains('tiền mặt'))
      return Icons.payments_rounded;
    if (n.contains('zalopay') || n.contains('zalo'))
      return Icons.qr_code_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BankAccountProvider>();
    final items = prov.items;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : AppColors.background;

    // Tổng số dư
    final totalBalance = items.fold<double>(0, (s, w) => s + (w.balance ?? 0));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Tài khoản',
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
                ? cs.outlineVariant.withOpacity(.1)
                : const Color(0xFFEEEFF3),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: cs.primary, size: 24),
              tooltip: 'Thêm tài khoản',
              onPressed: () async {
                final created = await safeShowModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const CreateBankAccountForm(),
                );
                if (created == true && mounted) {
                  await context.read<BankAccountProvider>().fetchAccounts();
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: cs.primary.withOpacity(.06),
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
          ? _buildEmptyState(cs, isDark)
          : FadeTransition(
              opacity:
                  CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // ── Tổng số dư card ──
                  _buildTotalCard(cs, isDark, totalBalance),
                  const SizedBox(height: 20),

                  // ── Section title ──
                  _buildSectionTitle('Danh sách tài khoản',
                      Icons.list_alt_rounded, cs, items.length),
                  const SizedBox(height: 10),

                  // ── Account items ──
                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final acc = entry.value;
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
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildAccountCard(context, acc, cs, isDark),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════
  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined,
                size: 36, color: cs.primary.withOpacity(.4)),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tài khoản',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thêm tài khoản đầu tiên để theo dõi',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withOpacity(.35),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════
  //  TOTAL BALANCE CARD
  // ═══════════════════════════
  Widget _buildTotalCard(ColorScheme cs, bool isDark, double totalBalance) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? cs.outlineVariant.withOpacity(.1) : AppColors.border,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.account_balance_rounded,
                    color: cs.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Tổng số dư',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(.52),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(totalBalance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? cs.onSurface : AppColors.textMain,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════
  //  SECTION TITLE
  // ═══════════════════════════
  Widget _buildSectionTitle(
      String title, IconData icon, ColorScheme cs, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary.withOpacity(.7)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.45),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════
  //  ACCOUNT CARD
  // ═══════════════════════════
  Widget _buildAccountCard(
      BuildContext context, dynamic acc, ColorScheme cs, bool isDark) {
    final prov = context.read<BankAccountProvider>();
    final isPositive = (acc.balance ?? 0) >= 0;

    return Material(
      color: isDark ? cs.surfaceContainerHigh : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Có thể mở chi tiết tài khoản
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? cs.outlineVariant.withOpacity(.08)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Bank icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _bankIcon(acc.bankname),
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if ((acc.bankname ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        acc.bankname!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(.4),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(acc.balance ?? 0),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isPositive ? AppColors.textMain : cs.error,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu
              PopupMenuButton(
                onSelected: (v) async {
                  if (v == 'edit') {
                    final updated = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: isDark
                          ? cs.surfaceContainerHigh
                          : Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: EditBankAccountForm(
                          accountId: acc.id,
                          initialName: acc.name,
                          initialBankName: acc.bankname,
                          initialBankNumber: acc.banknumber,
                          initialBalance: (acc.balance ?? 0).toDouble(),
                          initialCurrency: acc.currency ?? 'VND',
                        ),
                      ),
                    );
                    if (updated == true && context.mounted) {
                      await context
                          .read<BankAccountProvider>()
                          .fetchAccounts();
                    }
                  }
                  if (v == 'delete') {
                    await _confirmDelete(context, acc, prov, cs);
                  }
                },
                icon: Icon(Icons.more_vert_rounded,
                    color: cs.onSurface.withOpacity(.3), size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: cs.primary),
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
  Future<void> _confirmDelete(BuildContext context, dynamic acc,
      BankAccountProvider prov, ColorScheme cs) async {
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
            const Text('Xóa tài khoản',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản "${acc.name}"?',
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
      await prov.deleteAccount(acc.id!);
      await prov.fetchAccounts();
    }
  }
}
