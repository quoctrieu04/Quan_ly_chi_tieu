import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:chitieu/api/investment/investment_provider.dart';

const _kMint      = Color(0xFF2EC4B6);
const _kMintLight = Color(0xFF5DE8DA);

class InvestmentSummaryCard extends StatelessWidget {
  const InvestmentSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<InvestmentProvider>();

    final totalInvested = provider.totalInvested;
    final profit = provider.totalProfit;
    final percent = totalInvested == 0 ? 0.0 : provider.totalProfitPercent.toDouble();
    final isProfit = profit >= 0;
    final totalCurrent = totalInvested + profit;

    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    String money(num v) => '${moneyFmt.format(v).replaceAll(',', '.')}đ';

    final progressRatio = (percent.abs() / 100).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF162028), const Color(0xFF1A2B35)]
              : [_kMint, _kMintLight],
        ),
        boxShadow: [
          BoxShadow(
            color: _kMint.withOpacity(isDark ? .1 : .25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Label + Circle ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giá trị hiện tại',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        money(totalCurrent),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Circle progress
                SizedBox(
                  width: 56,
                  height: 56,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: progressRatio),
                    builder: (_, val, __) {
                      return CustomPaint(
                        painter: _CirclePainter(
                          progress: val,
                          color: isProfit
                              ? Colors.white
                              : const Color(0xFFEF9A9A),
                        ),
                        child: Center(
                          child: Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isProfit
                                  ? Colors.white
                                  : const Color(0xFFEF9A9A),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Row 2: Vốn gốc + Lợi nhuận ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vốn gốc',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          money(totalInvested),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withOpacity(.15),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isProfit ? 'Lợi nhuận' : 'Thua lỗ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isProfit ? "+" : ""}${money(profit)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isProfit
                                ? Colors.white
                                : const Color(0xFFEF9A9A),
                          ),
                        ),
                      ],
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
}

// ── Circular progress painter ──
class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  _CirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
