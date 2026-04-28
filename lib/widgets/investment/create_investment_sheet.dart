import 'package:flutter/material.dart';
import 'package:chitieu/core/theme/app_colors.dart';

import 'bank/bank_investment_form.dart';
import 'stock/stock_investment_form.dart';
import 'real_estate/real_estate_investment_form.dart';

class CreateInvestmentSheet extends StatefulWidget {
  const CreateInvestmentSheet({super.key});

  @override
  State<CreateInvestmentSheet> createState() =>
      _CreateInvestmentSheetState();
}

class _CreateInvestmentSheetState extends State<CreateInvestmentSheet> {
  String type = 'bank';

  IconData _typeIcon(String t) {
    switch (t) {
      case 'stock':
        return Icons.candlestick_chart_rounded;
      case 'real_estate':
        return Icons.home_work_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'stock':
        return const Color(0xFF1565C0);
      case 'real_estate':
        return const Color(0xFFE65100);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : AppColors.background;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Handle bar ──
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withOpacity(.12),
                              cs.primary.withOpacity(.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.primary.withOpacity(.1),
                          ),
                        ),
                        child: Icon(Icons.trending_up_rounded,
                            color: cs.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm đầu tư',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ngân hàng, cổ phiếu, bất động sản',
                              style: TextStyle(
                                fontSize: 12.5,
                                color:
                                    cs.onSurface.withOpacity(.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Type selector ──
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHigh
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? cs.outlineVariant.withOpacity(.08)
                            : const Color(0xFFECEDF2),
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        _typeChip('bank', 'Ngân hàng', cs, isDark),
                        const SizedBox(width: 4),
                        _typeChip('stock', 'Cổ phiếu', cs, isDark),
                        const SizedBox(width: 4),
                        _typeChip(
                            'real_estate', 'BĐS', cs, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Form content ──
                  if (type == 'bank') const BankInvestmentForm(),
                  if (type == 'stock') const StockInvestmentForm(),
                  if (type == 'real_estate')
                    const RealEstateInvestmentForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
      String value, String label, ColorScheme cs, bool isDark) {
    final selected = type == value;
    final color = _typeColor(value);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? color.withOpacity(.3) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _typeIcon(value),
                size: 16,
                color: selected
                    ? color
                    : cs.onSurface.withOpacity(.35),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? color
                        : cs.onSurface.withOpacity(.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
