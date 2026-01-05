import 'package:flutter/material.dart';
import 'package:chitieu/core/money/widgets/money_text.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:chitieu/api/category/category_model.dart';

/// Ngưỡng cảnh báo – có thể đưa vào cài đặt sau này
const double kWarn1 = 0.75; // nhắc nhẹ
const double kWarn2 = 0.90; // sắp vượt mức

enum BudgetStatus { normal, warn1, warn2, overspent }

class BudgetCategoryTile extends StatelessWidget {
  final Category category;
  final BudgetItem item;
  final VoidCallback? onTap;
  final double radius;

  const BudgetCategoryTile({
    super.key,
    required this.category,
    required this.item,
    this.onTap,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = item.amount - item.spent;
    final percent = item.amount > 0
        ? (item.spent / item.amount)
        : (item.spent > 0 ? 1.0 : 0.0);

    final status = _statusFor(item.amount, item.spent);
    final barColor = _colorFor(status);
    final warning = _warningText(status, amount: item.amount, spent: item.spent);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        // ĐÃ BỎ CHẤM MÀU:
        // leading: _Dot(color: barColor),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Text('Đã phân bổ: '), MoneyText(item.amount)]),
              const SizedBox(height: 2),
              Row(children: [
                const Text('Đã tiêu: '),
                MoneyText(
                  item.spent,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Text('Còn lại: '),
                MoneyText(
                  remaining,
                  style: TextStyle(
                    color: remaining < 0 ? Colors.redAccent : Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),

              // Thanh tiến trình
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    );
                  },
                ),
              ),

              // Dòng cảnh báo
              if (warning.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      status == BudgetStatus.overspent
                          ? Icons.error_outline
                          : Icons.warning_amber_rounded,
                      size: 18,
                      color: barColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _WarningRichText(
                        text: warning,
                        status: status,
                        amount: item.amount,
                        spent: item.spent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_down_rounded),
        onTap: onTap,
      ),
    );
  }

  // ===== Helpers =====

  BudgetStatus _statusFor(num amount, num spent) {
    if (amount <= 0) {
      // Không có ngân sách: có chi là đáng báo
      return spent > 0 ? BudgetStatus.warn2 : BudgetStatus.normal;
    }
    final p = spent / amount;
    if (spent > amount) return BudgetStatus.overspent;
    if (p >= kWarn2) return BudgetStatus.warn2;
    if (p >= kWarn1) return BudgetStatus.warn1;
    return BudgetStatus.normal;
  }

  Color _colorFor(BudgetStatus s) {
    switch (s) {
      case BudgetStatus.overspent:
        return Colors.redAccent;
      case BudgetStatus.warn2:
        return Colors.orangeAccent;
      case BudgetStatus.warn1:
        return Colors.amber;
      case BudgetStatus.normal:
        return Colors.green.shade400;
    }
  }

  String _warningText(BudgetStatus s, {required num amount, required num spent}) {
    final p = (amount > 0) ? (spent / amount * 100) : 0;
    switch (s) {
      case BudgetStatus.overspent:
        return '❗ Đã vượt ngân sách ';
      case BudgetStatus.warn2:
        return '⚠️ Sắp vượt mức (đã chi ${p.toStringAsFixed(0)}%)';
      case BudgetStatus.warn1:
        return '💡 Đã chi khoảng ${p.toStringAsFixed(0)}% ngân sách';
      case BudgetStatus.normal:
        return '';
    }
  }
}

class _WarningRichText extends StatelessWidget {
  final String text;
  final BudgetStatus status;
  final num amount;
  final num spent;

  const _WarningRichText({
    required this.text,
    required this.status,
    required this.amount,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    if (status != BudgetStatus.overspent) {
      return Text(
        text,
        style: TextStyle(color: _colorFor(status), fontWeight: FontWeight.w700, fontSize: 13),
      );
    }
    final missing = spent - amount;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 13),
        children: [
          const TextSpan(
            text: '❗ Đã vượt ngân sách ',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.redAccent),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: MoneyText(
                missing,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(BudgetStatus s) {
    switch (s) {
      case BudgetStatus.overspent:
        return Colors.redAccent;
      case BudgetStatus.warn2:
        return Colors.orangeAccent;
      case BudgetStatus.warn1:
        return Colors.amber;
      case BudgetStatus.normal:
        return Colors.green.shade400;
    }
  }
}
