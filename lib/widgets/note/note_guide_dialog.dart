import 'package:flutter/material.dart';

class NoteGuideStep {
  const NoteGuideStep({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

class NoteGuideDialog extends StatelessWidget {
  const NoteGuideDialog({super.key, required this.step});

  final NoteGuideStep step;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(step.icon, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              step.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
