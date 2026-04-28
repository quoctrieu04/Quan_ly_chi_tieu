import 'package:flutter/material.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/core/money/widgets/money_text.dart';
import 'package:chitieu/core/budget/budget_model.dart';
import 'package:chitieu/api/category/category_model.dart';

const double kWarn1 = 0.80;

enum BudgetStatus { normal, warn1, overspent }

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
    final status = _statusFor(item.amount, item.spent);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cs = Theme.of(context).colorScheme;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.2)
        : const Color(0xFF0F172A).withOpacity(0.04);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF64748B);

    final isOver = status == BudgetStatus.overspent;
    final isWarning = status == BudgetStatus.warn1;

    // Màu sắc Red Theme (Dựa theo bản thiết kế)
    final redStripColor = const Color(0xFF991B1B); // Vạch đỏ mép Card
    final redTextColor = const Color(0xFFDC2626); // Chữ đỏ thông báo
    final redBadgeBg = isDark
        ? const Color(0xFF7F1D1D).withOpacity(0.4)
        : const Color(0xFFFEE2E2); // Nền chip đỏ
    const orangeTextColor = Color(0xFFD97706);
    const orangeBorderColor = Color(0xFFF59E0B);

    // Màu chính phụ thuộc trạng thái
    final spentColor = isOver
        ? redTextColor
        : isWarning
            ? orangeTextColor
            : (isDark
                ? Colors.white
                : const Color(0xFF0F172A)); // Màu chữ tiền chi

    // Kênh màu phụ (Dành cho Avatar vuông bo góc theo mẫu)
    final avatarBg = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    final avatarColor = isDark ? Colors.white : AppColors.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias, // Để thanh strip màu đỏ ốp dính rìa bo tròn
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOver
              ? redTextColor.withOpacity(.55)
              : isWarning
                  ? orangeBorderColor.withOpacity(.7)
                  : Colors.transparent,
          width: isOver || isWarning ? 1.4 : 0,
        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // (2.1) AVATAR Hình vuông bo góc mượt
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: avatarBg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getIconForCategory(category.name),
                            size: 22,
                            color: avatarColor,
                          ),
                        ),

                        const SizedBox(width: 12),

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
                                        fontSize: 15,
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
                                                fontSize: 12)),
                                        MoneyText(
                                          item.amount,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text('Chưa cấp ngân sách',
                                        style: TextStyle(
                                            color: textMuted,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic)),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // HÀNG 2: Đã chi (Căn phải)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Đã chi: ',
                                      style: TextStyle(
                                          color: textMuted, fontSize: 12)),
                                  MoneyText(
                                    item.spent,
                                    style: TextStyle(
                                      color:
                                          spentColor, // Đỏ nếu vượt chữ, bình thường nếu an toàn
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),

                              // CẢNH BÁO BÊN DƯỚI KHI GẦN/VƯỢT KẾ HOẠCH
                              if (isWarning && !isOver)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          size: 16, color: orangeTextColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sắp chạm kế hoạch',
                                        style: const TextStyle(
                                          color: orangeTextColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isOver)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                              '💸 Ui chao! Cảnh báo lạm chi!'),
                                          content: Text(
                                              'Bạn lại lỡ tay vung quá trán cho khoản "${_capFirst(category.name)}" mất rồi!\nĐừng để rỗng túi nhé, từ giờ tới cuối tháng hãy "thắt lưng buộc bụng" nha.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text(
                                                  'Biết rồi khổ lắm nói mãi!'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning_amber_rounded,
                                              size: 16, color: redTextColor),
                                          const SizedBox(width: 4),
                                          Text('Đã vượt Kế hoạch ',
                                              style: TextStyle(
                                                  color: redTextColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 6),
                                          // Icon ngón tay chọt báo hiệu bấm được
                                          Icon(Icons.touch_app,
                                              size: 16,
                                              color: redTextColor
                                                  .withOpacity(0.8)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
      return spent > 0 ? BudgetStatus.warn1 : BudgetStatus.normal;
    }
    final p = spent / amount;
    if (spent > amount) return BudgetStatus.overspent;
    if (p >= kWarn1) return BudgetStatus.warn1;
    return BudgetStatus.normal;
  }
}
