import 'dart:convert';
import 'package:dio/dio.dart';
import 'financial_transaction_model.dart';

class FinancialTransactionService {
  final Dio dio;

  FinancialTransactionService(this.dio);

  Future<List<FinancialTransaction>> fetchHistory({
    required int year,
    required int month,
    int? day,
    String category = 'investment',
    int limit = 200,
  }) async {
    final params = <String, dynamic>{
      'year': year,
      'month': month,
      'category': category,
      'limit': limit,
      if (day != null) 'day': day,
    };

    final res = await dio.get(
      '/transactions/history',
      queryParameters: params,
    );

    final code = res.statusCode ?? 0;
    if (code >= 400) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'Fetch history failed ($code)',
        type: DioExceptionType.badResponse,
      );
    }

    final decoded = _normalizeJson(res.data);

    final List raw = (decoded is Map && decoded['data'] is List)
        ? (decoded['data'] as List)
        : (decoded is List ? decoded : const []);

    return raw
        .whereType<Map>()
        .map((e) => FinancialTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  dynamic _normalizeJson(dynamic data) {
    if (data == null) return null;
    if (data is Map || data is List) return data;
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}