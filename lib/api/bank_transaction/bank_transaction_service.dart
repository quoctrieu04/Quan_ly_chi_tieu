import 'package:dio/dio.dart';
import 'bank_transaction_model.dart';

class BankTransactionService {
  final Dio _dio;
  BankTransactionService(this._dio);

  /// 📆 Lấy danh sách giao dịch theo tháng/năm
  Future<List<BankTransaction>> fetchByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final res = await _dio.get(
        '/bank-transactions',
        queryParameters: {'year': year, 'month': month},
      );

      final data = (res.data is List)
          ? res.data
          : (res.data['data'] ?? res.data['items'] ?? []);

      return List<Map<String, dynamic>>.from(data)
          .map((e) => BankTransaction.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Lỗi tải giao dịch theo tháng: $e');
    }
  }

  /// 📋 Lấy toàn bộ giao dịch (ít dùng, chỉ dùng cho debug)
  Future<List<BankTransaction>> fetchAll() async {
    try {
      final res = await _dio.get('/bank-transactions');
      final data = (res.data is List)
          ? res.data
          : (res.data['data'] ?? res.data['items'] ?? []);
      return List<Map<String, dynamic>>.from(data)
          .map((e) => BankTransaction.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Lỗi tải toàn bộ giao dịch: $e');
    }
  }

  /// ➕ Tạo mới một giao dịch ngân hàng
  Future<void> create(Map<String, dynamic> data) async {
  try {
    await _dio.post(
      '/bank-transactions',
      data: data,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  } catch (e) {
    throw Exception('Lỗi tạo giao dịch: $e');
  }
}

}
