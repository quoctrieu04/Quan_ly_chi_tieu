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
