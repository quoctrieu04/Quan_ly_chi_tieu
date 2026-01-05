import 'package:dio/dio.dart';
import 'income_model.dart';

class IncomeService {
  final Dio _dio;
  IncomeService(this._dio);

  /// 📁 Lấy danh sách tất cả danh mục thu nhập (category)
  Future<List<IncomeCategory>> fetchAll({int? year, int? month}) async {
  final res = await _dio.get(
    'in-categories',
    queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    },
  );
  final body = res.data;
  final List raw = (body is List) ? body : (body['data'] ?? []);
  return raw
      .map((e) => IncomeCategory.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}


  /// 📅 Lấy danh sách nguồn thu trong tháng (in-invoices)
  Future<List<IncomeCategory>> fetchByMonth({
    required int year,
    required int month,
  }) async {
    final res = await _dio.get(
      'in-invoices',
      queryParameters: {'year': year, 'month': month},
    );
    final body = res.data;
    final List raw = (body is List) ? body : (body['data'] ?? []);
    return raw
        .map((e) => IncomeCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// ➕ Tạo danh mục thu nhập
 Future<IncomeCategory> create(
  String title, {
  String currency = 'VND',
  required int year,
  required int month,
}) async {
  final res = await _dio.post('in-categories', data: {
    'title': title,
    'currency': currency,
    'year': year,
    'month': month,
  });
  return IncomeCategory.fromJson(Map<String, dynamic>.from(res.data ?? {}));
}


  /// ✏️ Cập nhật danh mục thu nhập
  Future<IncomeCategory> update(int id,
      {required String title, String? currency}) async {
    final res = await _dio.patch('in-categories/$id', data: {
      'title': title,
      if (currency != null) 'currency': currency,
    });
    return IncomeCategory.fromJson(Map<String, dynamic>.from(res.data ?? {}));
  }

  /// ❌ Xóa danh mục thu nhập
  Future<void> delete(int id) async {
    await _dio.delete('in-categories/$id');
  }
}
