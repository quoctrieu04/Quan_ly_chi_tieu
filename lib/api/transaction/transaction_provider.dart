import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';
import 'package:chitieu/auth/auth_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _service;
  final AuthProvider _auth;

  bool loading = false;
  List<TransactionItem> _items = [];
  List<TransactionItem> get items => _items;

  TransactionProvider(Dio dio, this._auth)
      : _service = TransactionService(dio);

  /// ==============================
  /// 🔄 Lấy danh sách tất cả giao dịch
  /// ==============================
  Future<void> fetchAll() async {
    final tk = _auth.token;
    if (tk == null || tk.isEmpty || tk == 'null') return;

    loading = true;
    notifyListeners();

    try {
      _items = await _service.fetchAll();
    } catch (e, st) {
      debugPrint('❌ TransactionProvider.fetchAll lỗi: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// ==============================
  /// 💾 Ghi giao dịch mới (thu hoặc chi)
  /// ==============================
  Future<void> create({
    required bool isIncome, // true = tiền vào, false = tiền ra
    required int bankId,
    required int categoryId,
    required num amount,
    String? content,
    required int month,   // ✅ thêm
    required int year, 
    String? occurredAt,
  }) async {
    final tk = _auth.token;
    if (tk == null || tk.isEmpty || tk == 'null') {
      throw Exception('Chưa đăng nhập');
    }

    try {
      await _service.createTransaction(
        type: isIncome ? 'in' : 'out',
        bankId: bankId,
        categoryId: categoryId,
        amount: amount,
        content: content,
        month: month,   // ✅ thêm
        year: year, 
        occurredAt: occurredAt, 
      );

      // ✅ Sau khi lưu thành công, tải lại danh sách
      await fetchAll();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?['message'] ?? e.message;

      debugPrint('❌ TransactionProvider.create lỗi Dio: $code $msg');

      if (code == 500) {
        throw Exception('Lỗi máy chủ khi lưu giao dịch. Vui lòng thử lại sau.');
      } else if (code == 400 || code == 422) {
        throw Exception('Dữ liệu không hợp lệ: $msg');
      } else {
        throw Exception('Không thể lưu giao dịch: $msg');
      }
    } catch (e, st) {
      debugPrint('❌ TransactionProvider.create lỗi khác: $e\n$st');
      rethrow;
    }
  }
}
