import 'package:chitieu/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:chitieu/l10n/app_localizations.dart';
import 'models/monthly_cashflow.dart';

const _kMint = AppColors.primary;
const _kWarning = AppColors.warning;
const _kDanger = AppColors.danger;

class SpendingTrendCard extends StatelessWidget {
  final List<MonthlyCashFlow> data;
  const SpendingTrendCard({super.key, required this.data});

  num _maxValue() {
    return data
        .map((e) => e.income > e.expense ? e.income : e.expense)
        .fold<num>(0, (a, b) => a > b ? a : b);
  }

  num _changePercent() {
    if (data.length < 2) return 0;
    final prev = data[data.length - 2].expense.toDouble().abs();
    final curr = data.last.expense.toDouble().abs();
    if (prev == 0 && curr == 0) return 0;
    final base = prev > curr ? prev : curr;
    if (base == 0) return 0;
    final percent = ((curr - prev) / base) * 100;
    return percent.clamp(-100.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final maxVal = _maxValue();
    final percent = _changePercent();
    final isDown = percent < 0;

    final incomeColor = _kMint;
    final expenseColor = _kWarning; // Orange for variation, or cs.error

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            Text(
              t.incomeExpenseFluctuation,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A2332),
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            // Change percent badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isDown ? _kMint : _kDanger)
                    .withOpacity(isDark ? .15 : .08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDown
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: isDown ? _kMint : _kDanger,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percent.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: isDown ? _kMint : _kDanger,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Chart Area
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.asMap().entries.map((entry) {
              final m = entry.value;
              final isLast = entry.key == data.length - 1;

              final double incomeH =
                  maxVal == 0 ? 0 : ((m.income / maxVal) * 90).toDouble();
              final double expenseH =
                  maxVal == 0 ? 0 : ((m.expense / maxVal) * 90).toDouble();

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 500 + (entry.key * 80)),
                tween: Tween(begin: 0, end: 1),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Income bar
                        Container(
                          width: 10,
                          height: incomeH.clamp(4, 90),
                          decoration: BoxDecoration(
                            color: isLast
                                ? incomeColor
                                : incomeColor.withOpacity(isDark ? .3 : .2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Expense bar
                        Container(
                          width: 10,
                          height: expenseH.clamp(4, 90),
                          decoration: BoxDecoration(
                            color: isLast
                                ? expenseColor
                                : expenseColor.withOpacity(isDark ? .3 : .2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'T${m.month}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                        color: isLast
                            ? cs.onSurface
                            : cs.onSurface.withOpacity(.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: incomeColor, label: t.incomeLabel),
            const SizedBox(width: 16),
            _Legend(color: expenseColor, label: t.expenseLabel),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.5),
          ),
        ),
      ],
    );
  }
}
