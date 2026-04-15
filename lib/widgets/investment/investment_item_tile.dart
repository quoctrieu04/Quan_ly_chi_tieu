import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/pages/investment_detail_page.dart';

const _kMint = Color(0xFF2EC4B6);

class InvestmentItemTile extends StatelessWidget {
  final Investment investment;

  const InvestmentItemTile({
    super.key,
    required this.investment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    String money(num v) => '${moneyFmt.format(v).replaceAll(',', '.')}đ';

    final profit = investment.profitLoss;
    final bool isClosed = investment.closedAt != null;
    final isGreen = profit >= 0;
    final profitColor = isGreen ? _kMint : cs.error;
    final pctValue = investment.profitPercent.abs().clamp(0, 100) / 100;

    final isBank = investment.type == 'bank';
    final dotColor = isBank ? _kMint : const Color(0xFF3B82F6);

    // Subtitle: Bank/type info
    final subtitle = [
      if (investment.bankName?.isNotEmpty == true) investment.bankName!,
      isBank ? 'Tiền gửi' : 'Cổ phiếu',
    ].join(' • ');

    return Opacity(
      opacity: isClosed ? 0.45 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? cs.outlineVariant.withOpacity(.08)
                : const Color(0xFFECEDF2),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isClosed
              ? null
              : () async {
                  final needReload = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InvestmentDetailPage(investment: investment),
                    ),
                  );
                  if (needReload == true && context.mounted) {
                    context.read<InvestmentProvider>().fetch();
                  }
                },
          onLongPress: isClosed ? () => _confirmDelete(context, cs) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Row 1: dot + name + profit amount ──
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: isClosed ? Colors.grey : dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isClosed)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isGreen ? "+" : ""}${money(profit)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: profitColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${investment.profitPercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: profitColor.withOpacity(.7),
                            ),
                          ),
                        ],
                      ),
                    if (isClosed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.error.withOpacity(.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tất toán',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Row 2: Vốn + Hiện tại ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(.03)
                        : const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vốn đầu tư',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              money(investment.totalInvested),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: isDark
                            ? Colors.white.withOpacity(.06)
                            : const Color(0xFFE8ECF0),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Giá trị hiện tại',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              money(investment.totalInvested + profit),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: profitColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Progress bar ──
                if (!isClosed && profit != 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: pctValue.clamp(0.01, 1.0)),
                      builder: (_, val, __) {
                        return LinearProgressIndicator(
                          value: val,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(.05)
                              : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation(
                            profitColor.withOpacity(.5),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ColorScheme cs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: cs.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Xóa khoản đầu tư',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${investment.name}"?',
          style: TextStyle(
            color: cs.onSurface.withOpacity(.7),
            fontSize: 14, height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<InvestmentProvider>().remove(investment.id!);
      await context.read<InvestmentProvider>().fetch();
    }
  }
}
