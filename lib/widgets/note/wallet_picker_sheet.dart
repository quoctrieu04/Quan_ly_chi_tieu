import 'package:flutter/material.dart';
import 'package:chitieu/core/money/widgets/money_text.dart';

class WalletPickerSheet extends StatelessWidget {
  const WalletPickerSheet(
      {super.key, required this.items, required this.selectedId, required this.onTopUp});
  final List<dynamic> items;
  final dynamic selectedId;
  final Future<void> Function(dynamic wallet) onTopUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mint = Color(0xFF2EC4B6);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : const Color(0xFFFAFBFE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(.12),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: mint.withOpacity(.08),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: mint, size: 18)),
                  const SizedBox(width: 12),
                  Text('Chọn tài khoản',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface)),
                ]),
                const SizedBox(height: 14),
                for (final w in items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHigh : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: (w as dynamic).id == selectedId
                              ? mint.withOpacity(.3)
                              : (isDark
                                  ? cs.outlineVariant.withOpacity(.08)
                                  : const Color(0xFFECEDF2))),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: mint.withOpacity(.08),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.account_balance_rounded,
                              color: mint, size: 20)),
                      title: Text(
                          (w as dynamic).name ?? (w as dynamic).title ?? '—',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      subtitle: Row(children: [
                        Text('Số dư: ',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(.4))),
                        MoneyText((w as dynamic).balance ??
                            (w as dynamic).amount ??
                            0),
                      ]),
                      trailing: (w as dynamic).id == selectedId
                           ? const Icon(Icons.check_circle_rounded,
                              color: mint, size: 22)
                          : null,
                      onTap: () => Navigator.pop(context, w),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
