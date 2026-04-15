import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';

const _kMint = Color(0xFF2EC4B6);

class SavingGoalCard extends StatelessWidget {
  final num totalSaved;
  final VoidCallback onCreate;

  const SavingGoalCard({
    super.key,
    required this.totalSaved,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moneySettings = context.watch<MoneySettingsProvider>().settings;
    final text = MoneyFormatter(moneySettings).format(totalSaved);

    return InkWell(
      onTap: onCreate,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 54, height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54, height: 54,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: 0.6),
                      builder: (_, value, __) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(.1)
                            : const Color(0xFFF0F1F5),
                        color: _kMint,
                      ),
                    ),
                  ),
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: _kMint.withOpacity(isDark ? .15 : .08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.savings_rounded,
                        color: _kMint, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mục tiêu tiết kiệm',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white.withOpacity(.5) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A2332),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(.05) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white.withOpacity(.4) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

