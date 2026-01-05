import 'package:flutter/foundation.dart';

/// Provider giữ state Tháng/Năm dùng chung toàn app.
class YearMonthProvider extends ChangeNotifier {
  DateTime _ym = DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime get ym => _ym;
  int get year => _ym.year;
  int get month => _ym.month;

  /// Đặt lại tháng/năm (ngày luôn = 1 để ổn định).
  void setYm(DateTime dt) {
    final next = DateTime(dt.year, dt.month, 1);
    if (next.year == _ym.year && next.month == _ym.month) return; // tránh notify thừa
    _ym = next;
    notifyListeners();
  }

  /// Quay về tháng hiện tại nhanh.
  void setNow() => setYm(DateTime.now());
}
