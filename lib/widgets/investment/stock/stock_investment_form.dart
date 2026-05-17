import 'package:flutter/material.dart';

class StockInvestmentForm extends StatelessWidget {
  const StockInvestmentForm({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withOpacity(.1)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.candlestick_chart_rounded,
              color: Color(0xFF1565C0),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cổ phiếu đang phát triển',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chức năng đầu tư cổ phiếu chưa hoàn thiện.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(.55),
            ),
          ),
        ],
      ),
    );
  }
}
