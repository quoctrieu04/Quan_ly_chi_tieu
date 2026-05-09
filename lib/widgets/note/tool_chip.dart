import 'package:flutter/material.dart';

class ToolChip extends StatelessWidget {
  const ToolChip({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mint = Color(0xFF2EC4B6);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? mint.withOpacity(0.08)
                : (isDark ? cs.surfaceContainerHigh : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? mint.withOpacity(0.3)
                  : (isDark
                      ? cs.outlineVariant.withOpacity(0.08)
                      : const Color(0xFFE5E8ED)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? mint : cs.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? mint : cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
