import 'package:flutter/material.dart';

class FeatureItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class FeatureHorizontalMenu extends StatefulWidget {
  final List<FeatureItem> items;
  const FeatureHorizontalMenu({super.key, required this.items});

  @override
  State<FeatureHorizontalMenu> createState() =>
      _FeatureHorizontalMenuState();
}

class _FeatureHorizontalMenuState extends State<FeatureHorizontalMenu> {
  final ScrollController _controller = ScrollController();

  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
      _controller.addListener(_updateArrows);
    });
  }

  void _updateArrows() {
    if (!_controller.hasClients) return;

    final max = _controller.position.maxScrollExtent;
    final offset = _controller.offset;

    final showLeft = offset > 4;
    final showRight = offset < max - 4;

    if ((showLeft != _showLeftArrow ||
            showRight != _showRightArrow) &&
        mounted) {
      setState(() {
        _showLeftArrow = showLeft;
        _showRightArrow = showRight;
      });
    }
  }

  void _scrollNext() {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      _controller.offset + 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollPrev() {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      (_controller.offset - 120).clamp(
        0,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        SizedBox(
          height: 96,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.items.asMap().entries.map((entry) {
                final e = entry.value;
                final i = entry.key;
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (i * 60)),
                  tween: Tween(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - v)),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: e.onTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withOpacity(.08),
                              border: Border.all(
                                color: cs.primary.withOpacity(.1),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              e.icon,
                              size: 22,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 68,
                            child: Text(
                              e.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        /// ⬅️ NÚT TRÁI
        if (_showLeftArrow)
          Positioned(
            left: 0,
            top: 8,
            bottom: 18,
            child: GestureDetector(
              onTap: _scrollPrev,
              child: Container(
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      (isDark ? cs.surface : const Color(0xFFFAFBFE))
                          .withOpacity(0.0),
                      isDark ? cs.surface : const Color(0xFFFAFBFE),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          ),

        /// ➡️ NÚT PHẢI
        if (_showRightArrow)
          Positioned(
            right: 0,
            top: 8,
            bottom: 18,
            child: GestureDetector(
              onTap: _scrollNext,
              child: Container(
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      (isDark ? cs.surface : const Color(0xFFFAFBFE))
                          .withOpacity(0.0),
                      isDark ? cs.surface : const Color(0xFFFAFBFE),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
