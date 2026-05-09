import 'dart:async';
import 'package:flutter/material.dart';

/// ================================
/// CONTEXT MOUNTED CHECK (COMPAT)
/// ================================
bool _isContextMounted(BuildContext context) {
  try {
    final mounted = (context as dynamic).mounted as bool;
    return mounted;
  } catch (_) {
    try {
      context.getElementForInheritedWidgetOfExactType<InheritedWidget>();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// ================================
/// SAFE SNACKBAR
/// ================================
SnackBar appSnackBar(
  String message, {
  IconData? icon,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final bg = isError ? const Color(0xFFB91C1C) : const Color(0xFF172033);
  final accent = isError ? const Color(0xFFFEE2E2) : const Color(0xFFEAF5FF);
  final fg = Colors.white;

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    elevation: 8,
    backgroundColor: bg,
    duration: duration,
    action: action,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withOpacity(.16),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon ??
                (isError ? Icons.error_outline_rounded : Icons.check_rounded),
            color: accent,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );
}

void safeShowSnackBar(BuildContext context, SnackBar snackBar) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_isContextMounted(context)) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  });
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  IconData? icon,
  bool isError = false,
  SnackBarAction? action,
}) {
  safeShowSnackBar(
    context,
    appSnackBar(message, icon: icon, isError: isError, action: action),
  );
}

/// ================================
/// SAFE MODAL BOTTOM SHEET
/// ❌ KHÔNG override showModalBottomSheet
/// ❌ KHÔNG đệ quy
/// ✅ Delay 1 frame để thoát gesture
/// ================================
Future<T?> safeShowModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
  bool useSafeArea = false,
}) async {
  if (!_isContextMounted(context)) return null;

  // ✅ Thoát gesture / build phase
  await Future.delayed(Duration.zero);

  if (!_isContextMounted(context)) return null;

  return await showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    shape: shape,
    clipBehavior: clipBehavior,
    useSafeArea: useSafeArea,
    builder: builder,
  );
}
