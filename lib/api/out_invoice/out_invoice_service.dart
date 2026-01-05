import 'package:dio/dio.dart';
import 'out_invoice_model.dart';

class OutInvoiceService {
  final Dio _dio;
  OutInvoiceService(this._dio);

  /// 📆 Lấy danh sách phiếu chi theo tháng/năm/ngày
  Future<dynamic> fetchByMonth({
    required int year,
    required int month,
    int? day, // 🆕 lọc theo ngày
  }) async {
    try {
      final res = await _dio.get(
        '/out-invoices',
        queryParameters: {
          'year': year,
          'month': month,
          if (day != null) 'day': day, // 🟢 lọc theo ngày thực tế phát sinh
        },
      );

      // 🟢 Backend trả {data: [...], total: ..., message: ...}
      return res.data;
    } catch (e) {
      throw Exception('Lỗi tải danh sách phiếu chi: $e');
    }
  }

  /// ➕ Tạo phiếu chi mới (có ngày phát sinh thực tế)
  Future<void> create(Map<String, dynamic> data) async {
    try {
      // ✅ Chuẩn hóa dữ liệu gửi lên
      final payload = {
        'bank_id': data['bank_id'] ?? data['bankId'],
        'outcat_id': data['outcat_id'] ??
            data['outcatId'] ??
            data['category_id'] ??
            data['categoryId'],
        'amount': data['amount'],
        'content': data['content'],
        'month': data['month'],
        'year': data['year'],
        if (data['occurred_at'] != null)
          'occurred_at': data['occurred_at'], // 🟢 thêm ngày phát sinh thực tế
      };

      await _dio.post(
        '/out-invoices',
        data: payload,
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } catch (e) {
      throw Exception('Lỗi tạo phiếu chi: $e');
    }
  }
}
