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

    return Stack(
      children: [
        SizedBox(
          height: 96,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.items.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: e.onTap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                          ),
                          child: Icon(
                            e.icon,
                            size: 26,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 76,
                          child: Text(
                            e.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
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
            top: 18,
            bottom: 18,
            child: GestureDetector(
              onTap: _scrollPrev,
              child: Container(
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      cs.surface.withOpacity(0.0),
                      cs.surface.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: cs.primary,
                ),
              ),
            ),
          ),

        /// ➡️ NÚT PHẢI
        if (_showRightArrow)
          Positioned(
            right: 0,
            top: 18,
            bottom: 18,
            child: GestureDetector(
              onTap: _scrollNext,
              child: Container(
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      cs.surface.withOpacity(0.0),
                      cs.surface.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 30,
                  color: cs.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

