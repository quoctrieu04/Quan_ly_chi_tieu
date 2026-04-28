import 'package:flutter/material.dart';

class AppMonthPickerSheet extends StatefulWidget {
  const AppMonthPickerSheet({
    super.key,
    required this.initial,
    this.min,
    this.max,
  });

  final DateTime initial;
  final DateTime? min;
  final DateTime? max;

  @override
  State<AppMonthPickerSheet> createState() => _AppMonthPickerSheetState();
}

class _AppMonthPickerSheetState extends State<AppMonthPickerSheet> {
  late int _year;

  DateTime get _min => widget.min ?? DateTime(2020, 1);
  DateTime get _max => widget.max ?? DateTime(2035, 12);

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  bool _isEnabled(int month) {
    final dt = DateTime(_year, month);
    return !dt.isBefore(DateTime(_min.year, _min.month)) &&
        !dt.isAfter(DateTime(_max.year, _max.month));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                enabled: _year > _min.year,
                onTap: () => setState(() => _year--),
              ),
              Expanded(
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                enabled: _year < _max.year,
                onTap: () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.55,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final enabled = _isEnabled(month);
              final selected =
                  _year == widget.initial.year && month == widget.initial.month;
              final current = _year == now.year && month == now.month;

              Color background = Colors.white;
              Color border = const Color(0xFFE5E7EB);
              Color foreground = const Color(0xFF0F172A);

              if (selected) {
                background = const Color(0xFF8BE0DC);
                border = const Color(0xFF0F766E);
                foreground = const Color(0xFF064E4A);
              } else if (current) {
                background = const Color(0xFFE6FAF7);
                border = const Color(0xFFBDEBE6);
                foreground = const Color(0xFF0F766E);
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled
                      ? () => Navigator.pop(context, DateTime(_year, month))
                      : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled ? background : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: enabled ? border : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$month',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: enabled
                              ? foreground
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      color: const Color(0xFF111827),
      disabledColor: const Color(0xFFCBD5E1),
      iconSize: 26,
      splashRadius: 22,
    );
  }
}

Future<DateTime?> showAppMonthPicker({
  required BuildContext context,
  required DateTime initial,
  DateTime? min,
  DateTime? max,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppMonthPickerSheet(
      initial: DateTime(initial.year, initial.month),
      min: min,
      max: max,
    ),
  );
}
