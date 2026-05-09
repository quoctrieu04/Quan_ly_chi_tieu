import 'package:flutter/material.dart';

class VoiceCaption extends StatelessWidget {
  const VoiceCaption({super.key, required this.text, required this.listening});
  final String text;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mint = Color(0xFF2EC4B6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: listening
                  ? mint.withOpacity(.3)
                  : (isDark
                      ? cs.outlineVariant.withOpacity(.08)
                      : const Color(0xFFECEDF2))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
                listening ? Icons.mic_rounded : Icons.record_voice_over_rounded,
                size: 18,
                color: listening ? mint : cs.onSurface.withOpacity(.5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text.isEmpty ? 'Đang nghe...' : text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}
