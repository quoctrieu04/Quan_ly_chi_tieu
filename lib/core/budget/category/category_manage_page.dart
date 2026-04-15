import 'package:chitieu/pages/budget_edit_page.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';

class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  /// 'out' = Chi (mặc định), 'in' = Thu
  String _type = 'out';

  Future<void> _refresh() async {
    await context.read<CategoryProvider>().fetchAll(type: _type);
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetEditPage(type: _type),
      ),
    );
    if (created == true) {
      await _refresh();
      if (mounted) {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã tạo danh mục')),
        );
      }
    }
  }

  Future<void> _edit(Category c) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetEditPage(category: c, type: _type),
      ),
    );
    if (changed == true) {
      await _refresh();
      if (mounted) {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã cập nhật danh mục')),
        );
      }
    }
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Xoá danh mục "${c.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await context.read<CategoryProvider>().delete(id: c.id);
      await _refresh();
      if (mounted) {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã xoá danh mục')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      safeShowSnackBar(
        context,
        SnackBar(content: Text('Xoá thất bại: $e')),
      );
    }
  }

  void _changeType(String newType) {
    if (_type == newType) return;
    setState(() => _type = newType);
    // ignore: discarded_futures
    _refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  // ── Icon map giống trang budget ──
  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('ăn') || n.contains('uống') || n.contains('food'))
      return Icons.restaurant_rounded;
    if (n.contains('di chuyển') ||
        n.contains('xăng') ||
        n.contains('transport')) return Icons.directions_car_rounded;
    if (n.contains('giải trí') || n.contains('entertainment'))
      return Icons.sports_esports_rounded;
    if (n.contains('mua sắm') || n.contains('shopping'))
      return Icons.shopping_bag_rounded;
    if (n.contains('sức khỏe') || n.contains('health'))
      return Icons.favorite_rounded;
    if (n.contains('giáo dục') || n.contains('học') || n.contains('education'))
      return Icons.school_rounded;
    if (n.contains('tiết kiệm') || n.contains('saving'))
      return Icons.savings_rounded;
    if (n.contains('hoá đơn') || n.contains('tiện ích') || n.contains('bill'))
      return Icons.receipt_long_rounded;
    if (n.contains('nhà') || n.contains('thuê') || n.contains('rent'))
      return Icons.home_rounded;
    if (n.contains('lương') || n.contains('thu nhập') || n.contains('income'))
      return Icons.attach_money_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isIncome = _type == 'in';
    final typeLabel = isIncome ? 'Thu' : 'Chi';
    final bgColor = isDark ? cs.surface : const Color(0xFFFAFBFE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Danh mục $typeLabel',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? cs.outlineVariant.withOpacity(.1)
                : const Color(0xFFEEEFF3),
          ),
        ),
        actions: [
          // ── Type toggle chip ──
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PopupMenuButton<String>(
              tooltip: 'Chọn loại',
              onSelected: _changeType,
              position: PopupMenuPosition.under,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              itemBuilder: (_) => [
                _popupItem('out', 'Chi', Icons.arrow_upward_rounded, cs),
                _popupItem('in', 'Thu', Icons.arrow_downward_rounded, cs),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.swap_vert_rounded,
                        size: 16, color: cs.primary),
                  ],
                ),
              ),
            ),
          ),
          // ── Add button ──
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.add_rounded, color: cs.primary, size: 22),
                tooltip: 'Thêm danh mục',
                onPressed: _create,
                constraints:
                    const BoxConstraints(minWidth: 38, minHeight: 38),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _refresh,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.items.isEmpty
                ? _buildEmpty(cs)
                : _buildList(provider.items, cs, isDark),
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmpty(ColorScheme cs) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.category_rounded,
                    size: 28, color: cs.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có danh mục',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nhấn + để tạo danh mục mới',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── List ──
  Widget _buildList(List<Category> items, ColorScheme cs, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 350 + (i * 50)),
          tween: Tween(begin: 0, end: 1),
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - v)),
              child: child,
            ),
          ),
          child: _buildCard(c, cs, isDark),
        );
      },
    );
  }

  Widget _buildCard(Category c, ColorScheme cs, bool isDark) {
    final typeLabel = _type == 'in' ? 'Thu' : 'Chi';
    final typeColor =
        _type == 'in' ? const Color(0xFF2E7D32) : cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _edit(c),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? cs.outlineVariant.withOpacity(.08)
                    : const Color(0xFFECEDF2),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForCategory(c.name),
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Name + type chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typeColor.withOpacity(.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 20, color: cs.onSurface.withOpacity(.35)),
                  tooltip: 'Sửa',
                  onPressed: () => _edit(c),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.surfaceContainerHighest.withOpacity(.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 6),
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20,
                      color: cs.error.withOpacity(.45)),
                  tooltip: 'Xoá',
                  onPressed: () => _delete(c),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.error.withOpacity(.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
      String value, String label, IconData icon, ColorScheme cs) {
    final isActive = _type == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isActive ? cs.primary : cs.onSurface.withOpacity(.5)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? cs.primary : cs.onSurface,
            ),
          ),
          if (isActive) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 18, color: cs.primary),
          ],
        ],
      ),
    );
  }
}
