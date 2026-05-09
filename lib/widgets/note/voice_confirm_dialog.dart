import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/api/income/income_model.dart';
import 'package:chitieu/widgets/note/flow_segmented.dart';

/// Kết quả trả về từ dialog xác nhận giọng nói.
class VoiceConfirmResult {
  final bool confirmed;
  final dynamic wallet;
  final Category? category;
  final IncomeCategory? income;

  VoiceConfirmResult({
    required this.confirmed,
    this.wallet,
    this.category,
    this.income,
  });
}

/// Popup xác nhận giao dịch giọng nói – hiện đại, hỗ trợ Dark Mode.
///
/// Hiển thị thông tin nhận diện (số tiền, danh mục, nguồn tiền)
/// và cho phép người dùng sửa trước khi xác nhận lưu.
Future<VoiceConfirmResult?> showVoiceConfirmDialog({
  required BuildContext context,
  required FlowType type,
  required double amount,
  required String note,
  required dynamic selectedWallet,
  required Category? selectedCategory,
  required IncomeCategory? selectedIncome,
  required List<dynamic> wallets,
  required List<Category> categories,
  required List<IncomeCategory> incomes,
}) {
  return showGeneralDialog<VoiceConfirmResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'voice_confirm',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) {
      return Center(
        child: _VoiceConfirmContent(
          type: type,
          amount: amount,
          note: note,
          selectedWallet: selectedWallet,
          selectedCategory: selectedCategory,
          selectedIncome: selectedIncome,
          wallets: wallets,
          categories: categories,
          incomes: incomes,
        ),
      );
    },
  );
}

class _VoiceConfirmContent extends StatefulWidget {
  final FlowType type;
  final double amount;
  final String note;
  final dynamic selectedWallet;
  final Category? selectedCategory;
  final IncomeCategory? selectedIncome;
  final List<dynamic> wallets;
  final List<Category> categories;
  final List<IncomeCategory> incomes;

  const _VoiceConfirmContent({
    required this.type,
    required this.amount,
    required this.note,
    required this.selectedWallet,
    required this.selectedCategory,
    required this.selectedIncome,
    required this.wallets,
    required this.categories,
    required this.incomes,
  });

  @override
  State<_VoiceConfirmContent> createState() => _VoiceConfirmContentState();
}

class _VoiceConfirmContentState extends State<_VoiceConfirmContent> {
  late dynamic _wallet;
  late Category? _category;
  late IncomeCategory? _income;

  final _vi = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _wallet = widget.selectedWallet;
    _category = widget.selectedCategory;
    _income = widget.selectedIncome;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOut = widget.type == FlowType.out;
    final accentColor = isOut ? const Color(0xFFE85D75) : const Color(0xFF2EC4B6);
    final tileBg = isDark
        ? cs.surfaceContainerHigh
        : cs.surfaceContainerHighest.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header icon ──
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.record_voice_over_rounded,
                size: 28,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ──
            Text(
              'Xác nhận giao dịch',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kiểm tra thông tin trước khi lưu',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 22),

            // ── Amount ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOut ? 'Chi tiêu' : 'Thu nhập',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_vi.format(widget.amount)} đ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Grouped detail card ──
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Note row
                  if (widget.note.isNotEmpty) ...[
                    _row(
                      icon: Icons.sticky_note_2_outlined,
                      iconColor: cs.onSurface.withValues(alpha: 0.4),
                      label: 'Ghi chú',
                      value: widget.note,
                      cs: cs,
                    ),
                    Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.1)),
                  ],

                  // Wallet row
                  _row(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: cs.primary,
                    label: 'Nguồn tiền',
                    value: _wallet != null
                        ? (_wallet.name ?? _wallet.title ?? 'Chưa chọn')
                        : 'Chưa chọn',
                    cs: cs,
                    editable: true,
                    onTap: _pickWallet,
                  ),
                  Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.1)),

                  // Category / Income row
                  if (isOut)
                    _row(
                      icon: Icons.category_outlined,
                      iconColor: cs.primary,
                      label: 'Danh mục',
                      value: _category?.name ?? 'Chưa chọn',
                      cs: cs,
                      editable: true,
                      onTap: _pickCategory,
                    )
                  else
                    _row(
                      icon: Icons.savings_outlined,
                      iconColor: cs.primary,
                      label: 'Nguồn thu',
                      value: _income?.title ?? 'Chưa chọn',
                      cs: cs,
                      editable: true,
                      onTap: _pickIncome,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      VoiceConfirmResult(confirmed: false),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: cs.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      VoiceConfirmResult(
                        confirmed: true,
                        wallet: _wallet,
                        category: _category,
                        income: _income,
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      'Xác nhận lưu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Unified row widget ──

  Widget _row({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ColorScheme cs,
    bool editable = false,
    VoidCallback? onTap,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.4))),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: editable ? FontWeight.w700 : FontWeight.w600,
                        color: cs.onSurface)),
              ],
            ),
          ),
          if (editable)
            Icon(Icons.chevron_right_rounded,
                size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );

    if (editable && onTap != null) {
      return InkWell(onTap: onTap, child: child);
    }
    return child;
  }

  // ── Inline pickers ──

  void _pickWallet() async {
    final picked = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePickerSheet<dynamic>(
        title: 'Chọn nguồn tiền',
        items: widget.wallets,
        selectedId: _wallet?.id,
        labelBuilder: (w) => w.name ?? w.title ?? '',
        subtitleBuilder: (w) {
          final bal = (w.balance ?? 0) as num;
          return '${_vi.format(bal)} đ';
        },
        icon: Icons.account_balance_wallet_rounded,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _wallet = picked);
    }
  }

  void _pickCategory() async {
    final picked = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePickerSheet<Category>(
        title: 'Chọn danh mục',
        items: widget.categories,
        selectedId: _category?.id,
        labelBuilder: (c) => c.name,
        icon: Icons.category_rounded,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _category = picked);
    }
  }

  void _pickIncome() async {
    final picked = await showModalBottomSheet<IncomeCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePickerSheet<IncomeCategory>(
        title: 'Chọn nguồn thu',
        items: widget.incomes,
        selectedId: _income?.id,
        labelBuilder: (i) => i.title,
        subtitleBuilder: (i) => '${_vi.format(i.balance)} đ',
        icon: Icons.savings_rounded,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _income = picked);
    }
  }
}

// ── Reusable bottom-sheet picker ──

class _SimplePickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final int? selectedId;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final IconData icon;

  const _SimplePickerSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.labelBuilder,
    required this.icon,
    this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final id = (item as dynamic).id as int?;
                  final isSelected = id == selectedId;
                  return Card(
                    color: isSelected
                        ? cs.primaryContainer.withValues(alpha: 0.4)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primary.withValues(alpha: 0.12),
                        child: Icon(icon, color: cs.primary, size: 20),
                      ),
                      title: Text(
                        labelBuilder(item),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: subtitleBuilder != null
                          ? Text(subtitleBuilder!(item))
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: cs.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, item),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
