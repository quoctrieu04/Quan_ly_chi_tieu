import 'package:flutter/material.dart';

class FeatureItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;
  final int badgeCount;

  FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
  });
}

class FeatureHorizontalMenu extends StatelessWidget {
  final List<FeatureItem> items;
  const FeatureHorizontalMenu({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = items.length.clamp(1, 5);
        final gap = columns > 1 ? 8.0 : 0.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _FeatureButton(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final FeatureItem item;

  const _FeatureButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget iconContainer = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh
            : cs.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withOpacity(.1)
              : cs.primary.withOpacity(.14),
        ),
      ),
      child: Icon(
        item.icon,
        size: 22,
        color: cs.primary,
      ),
    );

    if (item.showBadge) {
      iconContainer = Badge(
        label: Text('${item.badgeCount > 0 ? item.badgeCount : 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        offset: const Offset(4, -4),
        child: iconContainer,
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconContainer,
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.78),
            ),
          ),
        ],
      ),
    );
  }
}
