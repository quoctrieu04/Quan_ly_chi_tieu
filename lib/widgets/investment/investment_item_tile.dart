import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/pages/investment_detail_page.dart';

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
    final profitColor = isGreen ? cs.primary : cs.error;
    final valueColor = cs.onSurface;

    final isBank = investment.type == 'bank';
    final dotColor = isBank ? cs.primary : const Color(0xFF3B82F6);

    // Subtitle: Bank/type info
    final subtitle = investment.bankName?.isNotEmpty == true
        ? investment.bankName!
        : (isBank ? '' : 'Cổ phiếu');

    Widget tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.grey : dotColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 9),
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
                            fontSize: 14,
                            color: cs.onSurface,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isClosed && !isBank)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (profit > 0 ? '+' : '') + money(profit),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: valueColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _miniChip(
                          '${investment.profitPercent.toStringAsFixed(2)}%',
                          profitColor,
                          isDark,
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
                        'Đã tất toán',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _inlineStats(
                context,
                principal: money(investment.totalInvested),
              ),
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: isClosed ? 0.45 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (investment.isMature)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: const Text('1',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inlineStats(
    BuildContext context, {
    required String principal,
  }) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withOpacity(.45);
    final strong = cs.onSurface;

    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        style: TextStyle(fontSize: 12, color: muted, height: 1.15),
        children: [
          const TextSpan(text: 'Vốn đầu tư: '),
          TextSpan(
            text: principal,
            style: TextStyle(color: strong, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(.14) : color.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ColorScheme cs) async {
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
            const Text('Xóa khoản đầu tư',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${investment.name}"?',
          style: TextStyle(
            color: cs.onSurface.withOpacity(.7),
            fontSize: 14,
            height: 1.5,
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
