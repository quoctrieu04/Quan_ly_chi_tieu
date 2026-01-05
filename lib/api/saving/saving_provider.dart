import 'package:flutter/material.dart';
import 'saving_service.dart';
import 'saving_model.dart';

class SavingProvider with ChangeNotifier {
  final SavingService api;

  SavingProvider({required this.api});

  List<SavingModel> items = [];
  bool loading = false;

  /// Lấy danh sách Saving cho tháng/năm
  Future<void> fetch({int? year, int? month}) async {
    loading = true;
    notifyListeners();

    try {
      print("Fetching data for year: $year, month: $month");
      items = await api.getAll(year: year, month: month); // Gọi API với tham số year và month
      print("Fetched items: ${items.length}");
    } catch (e) {
      print("Saving fetch error: $e");
    }

    loading = false;
    notifyListeners();
  }

  /// Tạo Saving
  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final newItem = await api.create(data);
      items.insert(0, newItem); // Thêm item mới vào đầu danh sách
      notifyListeners();
      return true;
    } catch (e) {
      print("Saving create error: $e");
      return false;
    }
  }

  /// Tạo giao dịch tiết kiệm (Nạp / Rút)
  Future<bool> addTransaction({
    required int savingId,
    required int bankId,
    required double amount,
    required String note,
  }) async {
    try {
      final ok = await api.createTransaction(
        savingId: savingId,
        bankId: bankId,
        amount: amount,
        note: note,
      );

      if (ok) {
        await fetch(); // Cập nhật lại dữ liệu sau khi giao dịch
      }

      return ok;
    } catch (e) {
      print("Saving transaction error: $e");
      return false;
    }
  }

  /// Xóa kế hoạch tiết kiệm
  Future<bool> remove(int id) async {
    try {
      await api.delete(id);
      items.removeWhere((e) => e.id == id); // Xóa mục tiết kiệm khỏi danh sách
      notifyListeners();
      return true;
    } catch (e) {
      print("Saving delete error: $e");
      return false;
    }
  }
}
