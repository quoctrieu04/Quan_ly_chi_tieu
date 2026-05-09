import 'package:flutter/material.dart';
import 'package:chitieu/l10n/app_localizations.dart';

enum FlowType { out, in_ }

class FlowSegmented extends StatelessWidget {
  const FlowSegmented({super.key, required this.value, required this.onChanged});
  final FlowType value;
  final ValueChanged<FlowType> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;
    const mint = Color(0xFF2EC4B6);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? cs.surfaceContainerHigh : const Color(0xFFF1F5F9),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _seg(t.moneyOut, Icons.arrow_outward_rounded, value == FlowType.out,
              cs.error, cs, isDark, () => onChanged(FlowType.out)),
          const SizedBox(width: 3),
          _seg(t.moneyIn, Icons.arrow_downward_rounded, value == FlowType.in_,
              mint, cs, isDark, () => onChanged(FlowType.in_)),
        ],
      ),
    );
  }

  Widget _seg(String label, IconData icon, bool active, Color ac,
      ColorScheme cs, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? cs.surface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: active ? ac : cs.onSurface.withOpacity(.3)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.5,
                        color: active ? ac : cs.onSurface.withOpacity(.3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
