import 'package:flutter/material.dart';
import 'package:chitieu/core/money/widgets/money_text.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:chitieu/api/category/category_model.dart';

const double kWarn1 = 0.75;
const double kWarn2 = 0.90;

enum BudgetStatus { normal, warn1, warn2, overspent }

String _capFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

IconData _getIconForCategory(String name) {
  final n = name.trim().toLowerCase();
  if (n.contains('ăn') ||
      n.contains('uống') ||
      n.contains('cafe') ||
      n.contains('thực') ||
      n.contains('food')) {
    return Icons.restaurant_outlined;
  }
  if (n.contains('nhà') ||
      n.contains('thuê') ||
      n.contains('điện') ||
      n.contains('nước')) {
    return Icons.home_outlined;
  }
  if (n.contains('xe') ||
      n.contains('đi lại') ||
      n.contains('xăng') ||
      n.contains('grab')) {
    return Icons.directions_car_outlined;
  }
  if (n.contains('mua sắm') ||
      n.contains('quần áo') ||
      n.contains('giày') ||
      n.contains('shopping')) {
    return Icons.local_mall_outlined;
  }
  if (n.contains('giải trí') || n.contains('phim') || n.contains('chơi')) {
    return Icons.confirmation_num_outlined;
  }
  if (n.contains('khỏe') ||
      n.contains('y tế') ||
      n.contains('thuốc') ||
      n.contains('bệnh')) {
    return Icons.favorite_border_rounded;
  }
  if (n.contains('học') || n.contains('sách') || n.contains('giáo')) {
    return Icons.menu_book_rounded;
  }
  if (n.contains('du lịch') || n.contains('nghỉ') || n.contains('bay')) {
    return Icons.flight_takeoff_rounded;
  }
  if (n.contains('quà') || n.contains('tặng') || n.contains('cưới')) {
    return Icons.card_giftcard_rounded;
  }
  if (n.contains('sam')) {
    // Dành riêng cho mock data 'Sam'
    return Icons.pets_outlined;
  }

  final genericIcons = [
    Icons.label_outline_rounded,
    Icons.folder_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.category_outlined,
    Icons.dashboard_customize_outlined,
  ];
  final hash = name.codeUnits.fold<int>(0, (prev, e) => prev + e);
  return genericIcons[hash % genericIcons.length];
}

class BudgetCategoryTile extends StatelessWidget {
  final Category category;
  final BudgetItem item;
  final VoidCallback? onTap;

  const BudgetCategoryTile({
    super.key,
    required this.category,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = item.amount - item.spent;
    final percent = item.amount > 0
        ? (item.spent / item.amount)
        : (item.spent > 0 ? 1.0 : 0.0);

    final status = _statusFor(item.amount, item.spent);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cs = Theme.of(context).colorScheme;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.2)
        : const Color(0xFF0F172A).withOpacity(0.04);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF64748B);

    final isOver = status == BudgetStatus.overspent;

    // Màu sắc Red Theme (Dựa theo bản thiết kế)
    final redStripColor = const Color(0xFF991B1B); // Vạch đỏ mép Card
    final redTextColor = const Color(0xFFDC2626); // Chữ đỏ thông báo
    final redBadgeBg = isDark
        ? const Color(0xFF7F1D1D).withOpacity(0.4)
        : const Color(0xFFFEE2E2); // Nền chip đỏ

    // Màu chính phụ thuộc trạng thái
    final spentColor = isOver
        ? redTextColor
        : (isDark
            ? Colors.white
            : const Color(0xFF0F172A)); // Màu chữ tiền chi (Đen hoặc Đỏ)

    // Màu thanh tiến trình (Dựa theo ảnh 2)
    final barIndicatorColor = isOver ? redStripColor : cs.primary;
    final barTrackColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    // Kênh màu phụ (Dành cho Avatar vuông bo góc theo mẫu)
    final avatarBg = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    final avatarColor =
        isDark ? Colors.white : const Color(0xFF0F4C5C); // Teal đậm sang trọng

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias, // Để thanh strip màu đỏ ốp dính rìa bo tròn
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: isOver ? Border.all(color: redTextColor.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // (Đã xóa dải đỏ ở viền trái theo yêu cầu của User)

                // 2) Thân Card chính
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // (2.1) AVATAR Hình vuông bo góc mượt
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: avatarBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getIconForCategory(category.name),
                            size: 20,
                            color: avatarColor,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // (2.2) NỘI DUNG VÀ THANH TIẾN TRÌNH CHIẾM GỌN PHẦN CÒN LẠI
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HÀNG 1: Tên danh mục (Trái) - Kế hoạch (Phải)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _capFirst(category.name),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.amount > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Kế hoạch: ',
                                            style: TextStyle(
                                                color: textMuted,
                                                fontSize: 13)),
                                        MoneyText(
                                          item.amount,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text('Chưa cấp ngân sách',
                                        style: TextStyle(
                                            color: textMuted,
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic)),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // HÀNG 2: Đã chi (Căn phải)
                              GestureDetector(
                                onTap: isOver ? () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('💸 Ui chao! Cảnh báo lạm chi!'),
                                      content: Text('Bạn lại lỡ tay vung quá trán cho khoản "${_capFirst(category.name)}" mất rồi!\nĐừng để rỗng túi nhé, từ giờ tới cuối tháng hãy "thắt lưng buộc bụng" nha.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Biết rồi khổ lắm nói mãi!'),
                                        ),
                                      ],
                                    ),
                                  );
                                } : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Đã chi: ',
                                        style: TextStyle(
                                            color: textMuted, fontSize: 13)),
                                    MoneyText(
                                      item.spent,
                                      style: TextStyle(
                                        color:
                                            spentColor, // Đỏ nếu vượt chữ, bình thường nếu an toàn
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (isOver) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.touch_app, size: 14, color: redTextColor.withOpacity(0.8)),
                                    ]
                                  ],
                                ),
                              ),

                              // Removed: HÀNG 3: THANH TIẾN TRÌNH

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Helpers =====

  BudgetStatus _statusFor(num amount, num spent) {
    if (amount <= 0) {
      return spent > 0 ? BudgetStatus.warn2 : BudgetStatus.normal;
    }
    final p = spent / amount;
    if (spent > amount) return BudgetStatus.overspent;
    if (p >= kWarn2) return BudgetStatus.warn2;
    if (p >= kWarn1) return BudgetStatus.warn1;
    return BudgetStatus.normal;
  }
}
