import 'package:flutter/material.dart';

class KeypadBar extends StatelessWidget {
  const KeypadBar(
      {super.key,
      required this.onTap,
      required this.onBack,
      required this.onConfirm,
      required this.isConfirming,
      this.onVoice});
  final ValueChanged<String> onTap;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final bool isConfirming;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);
    final keyBg = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    const mint = Color(0xFF2EC4B6);

    Widget btn(String label, {Color? textColor, VoidCallback? action}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Material(
            color: keyBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: action ?? () => onTap(label),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color:
                        textColor ?? (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget iconBtn(IconData icon,
        {Color? color, required VoidCallback action}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Material(
            color: keyBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: action,
              child: Center(
                child: Icon(icon, color: color ?? mint, size: 24),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 7  8  9  ⌫
          SizedBox(
            height: 56,
            child: Row(children: [
              btn('7'),
              btn('8'),
              btn('9'),
              iconBtn(Icons.backspace_outlined, action: onBack),
            ]),
          ),
          // Rows 2-4: left(4-5-6 / 1-2-3 / 0) + right(✓ spanning all 3)
          SizedBox(
            height: 168,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left 3 columns
                Expanded(
                  flex: 3,
                  child: Column(children: [
                    Expanded(
                        child: Row(children: [btn('4'), btn('5'), btn('6')])),
                    Expanded(
                        child: Row(children: [btn('1'), btn('2'), btn('3')])),
                    Expanded(child: Row(children: [btn('0')])),
                  ]),
                ),
                // Right col: ✓ spanning 3 rows
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Material(
                      color: isConfirming ? mint.withOpacity(.55) : mint,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: isConfirming ? null : onConfirm,
                        child: Center(
                          child: isConfirming
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
