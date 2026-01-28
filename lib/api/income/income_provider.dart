import 'package:flutter/foundation.dart';
import 'income_service.dart';
import 'income_model.dart';
import 'package:chitieu/auth/auth_provider.dart';

class IncomeProvider extends ChangeNotifier {
  final IncomeService _service;
  final AuthProvider _auth;

  IncomeProvider(this._service, this._auth);

  String? error;
  bool loading = false;

  List<IncomeCategory> _items = [];
  List<IncomeCategory> get items => List.unmodifiable(_items);

  /// 📅 Lấy nguồn thu (theo tháng/năm)
  Future<void> fetch({required int year, required int month}) async {
    if (!_auth.isAuthenticated) return;

    loading = true;
    notifyListeners();

    try {
      _items = await _service.fetchAll(year: year, month: month);
    } catch (e, st) {
      debugPrint('❌ IncomeProvider.fetch lỗi: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 📁 Lấy toàn bộ danh mục thu nhập (picker)
  Future<void> fetchAll() async {
    if (!_auth.isAuthenticated) return;

    loading = true;
    notifyListeners();

    try {
      _items = await _service.fetchAll();
    } catch (e, st) {
      debugPrint('❌ IncomeProvider.fetchAll lỗi: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// ➕ Tạo danh mục thu nhập
  Future<bool> createIncomeCategory(
    String title, {
    String currency = 'VND',
    required int year,
    required int month,
  }) async {
    if (!_auth.isAuthenticated) return false;

    error = null;
    try {
      final created = await _service.create(
        title,
        currency: currency,
        year: year,
        month: month,
      );

      _items.add(created);
      _items.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  /// ✏️ Cập nhật danh mục
  Future<bool> updateIncomeCategory(
    int id, {
    required String title,
    String? currency,
  }) async {
    if (!_auth.isAuthenticated) return false;

    error = null;
    try {
      final updated =
          await _service.update(id, title: title, currency: currency);

      final idx = _items.indexWhere((e) => e.id == id);
      if (idx != -1) _items[idx] = updated;

      _items.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  /// ❌ Xóa danh mục
  Future<bool> deleteIncomeCategory(int id) async {
    if (!_auth.isAuthenticated) return false;

    error = null;
    try {
      await _service.delete(id);
      _items.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  /// 🧹 Reset provider
  void clear() {
    error = null;
    loading = false;
    _items.clear();
    notifyListeners();
  }
}
