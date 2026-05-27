import 'package:flutter/material.dart';
import 'package:chitieu/api/category/category_model.dart';

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    super.key,
    required this.items,
    required this.selectedId,
    this.onCreateCategory,
  });
  final List<Category> items;
  final int? selectedId;
  final Future<Category?> Function()? onCreateCategory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mint = cs.primary;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: mint.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.category_rounded,
                        color: mint, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Chọn danh mục',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface)),
                ),
                if (onCreateCategory != null)
                  Material(
                    color: mint.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final created = await onCreateCategory!.call();
                        if (created != null && context.mounted) {
                          Navigator.pop(context, created);
                        }
                      },
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.add_rounded, color: mint, size: 20),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.15,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8),
                itemBuilder: (_, i) {
                  final c = items[i];
                  final selected = c.id == selectedId;
                  final first =
                      (c.name.isNotEmpty ? c.name[0] : '•').toUpperCase();
                  return Material(
                    color: selected
                        ? mint.withValues(alpha: .08)
                        : (isDark ? cs.surfaceContainerHigh : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, c),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: selected
                                  ? mint.withValues(alpha: .3)
                                  : (cs.outlineVariant.withValues(alpha: .08))),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: mint.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(first,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: mint,
                                          fontSize: 15))),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(c.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: selected ? mint : cs.onSurface)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


