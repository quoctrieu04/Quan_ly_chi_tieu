import 'package:dio/dio.dart';
import 'transaction_model.dart';

class TransactionService {
  final Dio _dio;
  TransactionService(this._dio);

  /// Ghi giao dịch mới (thu hoặc chi)
  Future<void> createTransaction({
  required String type,
  required int bankId,
  required int categoryId,
  required num amount,
  String? content,
  required int month,
  required int year,
  String? occurredAt, // 🟢 thêm
}) async {
  final data = {
    'type': type,
    'bank_id': bankId,
    'category_id': categoryId,
    'amount': amount,
    'content': content,
    'month': month,
    'year': year,
    if (occurredAt != null) 'occurred_at': occurredAt, // 🟢 thêm
  };
  await _dio.post('/transactions', data: data);
}



  /// 🧾 Lấy danh sách chi tiêu theo tháng/năm
  Future<List<TransactionItem>> fetchExpenseByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final r = await _dio.get('/out-invoices', queryParameters: {
        'year': year,
        'month': month,
      });

      final list = (r.data is List)
          ? r.data
          : (r.data['data'] ?? []);

      return List<Map<String, dynamic>>.from(list)
          .map(TransactionItem.fromJson)
          .toList();
    } catch (e, st) {
      print('❌ TransactionService.fetchExpenseByMonth lỗi: $e\n$st');
      rethrow;
    }
  }

  /// 💰 Lấy danh sách nguồn tiền (thu nhập) theo tháng/năm
  Future<List<TransactionItem>> fetchIncomeByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final r = await _dio.get('/in-invoices', queryParameters: {
        'year': year,
        'month': month,
      });

      final list = (r.data is List)
          ? r.data
          : (r.data['data'] ?? []);

      return List<Map<String, dynamic>>.from(list)
          .map(TransactionItem.fromJson)
          .toList();
    } catch (e, st) {
      print('❌ TransactionService.fetchIncomeByMonth lỗi: $e\n$st');
      rethrow;
    }
  }

  /// (Tuỳ chọn) Gộp tất cả giao dịch - không lọc tháng
  Future<List<TransactionItem>> fetchAll() async {
    try {
      final r = await _dio.get('/transactions'); // nếu backend có API gộp
      final list = (r.data is List)
          ? r.data
          : (r.data['data'] ?? r.data['items'] ?? []);

      return List<Map<String, dynamic>>.from(list)
          .map(TransactionItem.fromJson)
          .toList();
    } catch (e, st) {
      print('❌ TransactionService.fetchAll lỗi: $e\n$st');
      rethrow;
    }
  }
}
