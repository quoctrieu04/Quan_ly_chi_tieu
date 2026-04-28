import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InvestmentSummaryCard extends StatelessWidget {
  const InvestmentSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<InvestmentProvider>();

    final totalInvested = provider.totalInvested;
    final profit = provider.totalProfit;
    final percent =
        totalInvested == 0 ? 0.0 : provider.totalProfitPercent.toDouble();
    final totalCurrent = totalInvested + profit;
    final isProfit = profit >= 0;
    final profitColor = isProfit ? AppColors.primaryDark : AppColors.danger;
    final valueColor = isDark ? cs.onSurface : AppColors.textMain;

    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    String money(num v) => '${moneyFmt.format(v).replaceAll(',', '.')}đ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalInvestmentTile(
          label: 'Tổng đầu tư',
          value: money(totalCurrent),
          percent: percent,
          color: cs.primary,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Vốn gốc',
                value: money(totalInvested),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primaryDark,
                valueColor: valueColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Lợi nhuận',
                value: money(profit),
                icon: isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: profitColor,
                valueColor: valueColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TotalInvestmentTile extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;
  final bool isDark;

  const _TotalInvestmentTile({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = isDark ? cs.onSurface : AppColors.textMain;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: _tileDecoration(context, isDark),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PercentBadge(percent: percent, color: color),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color valueColor;
  final bool isDark;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _tileDecoration(context, isDark),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(.48),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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

class _PercentBadge extends StatelessWidget {
  final double percent;
  final Color color;

  const _PercentBadge({
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final positive = percent >= 0;
    final displayColor = positive ? color : AppColors.danger;

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: displayColor.withOpacity(.22), width: 5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: displayColor,
            size: 14,
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(
              color: displayColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _tileDecoration(BuildContext context, bool isDark) {
  final cs = Theme.of(context).colorScheme;

  return BoxDecoration(
    color: isDark ? cs.surfaceContainerHigh : Colors.white,
    borderRadius: BorderRadius.circular(20),
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
  );
}
