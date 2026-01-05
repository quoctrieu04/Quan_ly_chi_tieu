import 'package:dio/dio.dart';

class InInvoiceService {
  final Dio _dio;
  InInvoiceService(this._dio);

  /// 📆 Lấy danh sách phiếu thu theo tháng/năm (hoặc ngày)
  Future<dynamic> fetchByMonth({
    required int year,
    required int month,
    int? day, // 🆕 lọc theo ngày
  }) async {
    try {
      final res = await _dio.get(
        '/in-invoices',
        queryParameters: {
          'year': year,
          'month': month,
          if (day != null) 'day': day,
        },
      );

      // 🟢 Trả nguyên JSON, vì backend trả {data: [...], total, month, year}
      return res.data;
    } catch (e) {
      throw Exception('Lỗi tải danh sách phiếu thu: $e');
    }
  }

  /// ➕ Gửi yêu cầu tạo phiếu thu mới (có ngày phát sinh)
  Future<void> create(Map<String, dynamic> data) async {
    try {
      // ✅ Chuẩn hóa payload theo backend Laravel
      final payload = {
        'bank_id': data['bank_id'] ?? data['bankId'],
        'incat_id': data['incat_id'] ??
            data['incatId'] ??
            data['category_id'] ??
            data['categoryId'],
        'amount': data['amount'],
        'content': data['content'],
        'month': data['month'],
        'year': data['year'],
        if (data['occurred_at'] != null)
          'occurred_at': data['occurred_at'], // 🟢 ngày phát sinh thực tế
      };

      await _dio.post(
        '/in-invoices',
        data: payload,
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } catch (e) {
      throw Exception('Lỗi tạo phiếu thu: $e');
    }
  }
}
