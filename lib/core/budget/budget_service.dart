import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:chitieu/auth/auth_provider.dart';

class BudgetService {
  final Dio dio;
  final AuthProvider auth;

  BudgetService(this.dio, this.auth);

  /// Headers mặc định (gộp token nếu có)
  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${auth.token ?? ''}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// 🧾 Lấy danh sách ngân sách (summary)
  Future<Map<String, dynamic>> getBudgets({
    required int year,
    required int month,
  }) async {
    final res = await dio.get(
      'api/budgets/summary',
      queryParameters: {
        'month': month,
        'year': year,
      },
      options: Options(headers: _headers),
    );

    if (res.statusCode != 200) {
      throw Exception('Lỗi khi tải ngân sách: ${res.data}');
    }

    final data = res.data;
    return {
      'data': data['data'] ?? data['budgets'] ?? [],
      'total_assigned': data['total_assigned'] ?? data['total_allocated'] ?? 0,
    };
  }

  /// 💰 Phân bổ nhiều danh mục cùng lúc
  Future<void> assignMany({
    required int year,
    required int month,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      'month': month,
      'year': year,
      'allocations': items.map((e) {
        return {
          'category_id': e['category_id'],
          'amount': e['amount'],
        };
      }).toList(),
    };

    final res = await dio.post(
      'api/budgets/allocate',
      data: json.encode(body),
      options: Options(headers: _headers),
    );

    if (res.statusCode != 201) {
      throw Exception('Phân bổ thất bại: ${res.data}');
    }
  }

  /// 💵 Phân bổ 1 danh mục duy nhất (khi nhấn nút +)
  Future<void> setOne({
    required int year,
    required int month,
    required int categoryId,
    required num amount,
  }) async {
    final body = {
      'month': month,
      'year': year,
      'allocations': [
        {'category_id': categoryId, 'amount': amount}
      ],
    };

    final res = await dio.post(
      'api/budgets/allocate',
      data: json.encode(body),
      options: Options(headers: _headers),
    );

    if (res.statusCode != 201) {
      throw Exception('Không thể lưu phân bổ: ${res.data}');
    }
  }

  /// 📊 Lấy tổng chi tiêu thực tế theo danh mục
  Future<Map<int, num>> getSpentByCategory({
    required int year,
    required int month,
  }) async {
    final res = await dio.get(
      'api/transactions/spent-by-category',
      queryParameters: {
        'month': month,
        'year': year,
      },
      options: Options(headers: _headers),
    );

    if (res.statusCode != 200) return {};

    final data = res.data;
    final result = <int, num>{};

    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final catId = int.tryParse(item['category_id'].toString()) ?? 0;
          final spent = num.tryParse(item['spent'].toString()) ?? 0;
          if (catId > 0) result[catId] = spent;
        }
      }
    } else if (data is Map && data['data'] is List) {
      for (final item in (data['data'] as List)) {
        if (item is Map<String, dynamic>) {
          final catId = int.tryParse(item['category_id'].toString()) ?? 0;
          final spent = num.tryParse(item['spent'].toString()) ?? 0;
          if (catId > 0) result[catId] = spent;
        }
      }
    } else if (data is Map) {
      data.forEach((k, v) {
        final catId = int.tryParse(k.toString()) ?? 0;
        final spent = num.tryParse(v.toString()) ?? 0;
        if (catId > 0) result[catId] = spent;
      });
    }

    return result;
  }
}
