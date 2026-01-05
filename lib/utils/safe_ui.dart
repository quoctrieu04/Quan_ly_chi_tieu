// lib/utils/safe_ui.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// Kiểm tra "mounted" tương thích nhiều version Flutter:
bool _isContextMounted(BuildContext context) {
  // Trên Flutter mới: context.mounted có sẵn.
  try {
    // ignore: unnecessary_statements
    // Nếu BuildContext có getter mounted, dòng dưới sẽ không throw.
    // Ta đọc gián tiếp qua Object? để không cần ràng buộc SDK.
    final _ = (context as dynamic).mounted as bool;
    return _;
  } catch (_) {
    // Trên Flutter cũ, fallback: nếu owner element đã unmount, dependOn... sẽ throw.
    try {
      context.getElementForInheritedWidgetOfExactType<InheritedWidget>();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Hiển thị SnackBar an toàn:
/// - Dùng maybeOf để không crash nếu chưa có ScaffoldMessenger.
/// - Ẩn snack hiện tại trước khi show cái mới.
/// - Không bắt buộc post-frame (nếu đang ở trong frame hợp lệ).
void safeShowSnackBar(BuildContext context, SnackBar snackBar) {
  if (!_isContextMounted(context)) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    // Nếu chưa có ScaffoldMessenger trong cây, đợi tới frame kế tiếp.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isContextMounted(context)) return;
      final m2 = ScaffoldMessenger.maybeOf(context);
      if (m2 == null) return;
      m2.hideCurrentSnackBar();
      m2.showSnackBar(snackBar);
    });
    return;
  }
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(snackBar);
}

/// Hiển thị BottomSheet an toàn, trả về Future<T?> như showModalBottomSheet:
Future<T?> safeShowModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
  bool useSafeArea = false,
}) {
  final c = Completer<T?>();
  // Nếu context chưa sẵn sàng, đợi đến frame sau.
  void _open() async {
    if (!_isContextMounted(context)) {
      if (!c.isCompleted) c.complete(null);
      return;
    }
    final r = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      useSafeArea: useSafeArea,
      builder: builder,
    );
    if (!c.isCompleted) c.complete(r);
  }

  // Thử mở ngay; nếu gọi từ trong build, Flutter vẫn cho phép.
  // Nếu bạn muốn bắt buộc đợi frame, hãy giữ addPostFrameCallback như bản cũ.
  // Ở đây mình chọn mở ngay cho ít độ trễ.
  // Nếu gặp trường hợp hiếm gây assert, đổi sang addPostFrameCallback.
  _open();
  return c.future;
}
