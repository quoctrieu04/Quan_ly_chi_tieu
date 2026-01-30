import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RealEstateService {
  final Dio dio;

  RealEstateService(this.dio);

  // =========================
  // FETCH REAL ESTATES
  // =========================
  Future<List<dynamic>> fetch() async {
    try {
      final res = await dio.get("real-estates");
      return (res.data is List) ? res.data : [];
    } catch (e) {
      debugPrint("❌ FETCH REAL ESTATES ERROR: $e");
      rethrow;
    }
  }

  // =========================
  // CREATE REAL ESTATE
  // =========================
  Future<void> create(Map<String, dynamic> data) async {
    try {
      await dio.post("real-estates", data: data);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Không thể tạo BĐS';
      throw Exception(msg);
    }
  }

  // =========================
  // ADD REAL ESTATE COST ✅ (CHUẨN BACKEND)
  // =========================
  Future<void> addCost({
    required int realEstateId,
    required double amount,
    required int accountSourceId,
    String? note,
    DateTime? costDate,
  }) async {
    try {
      await dio.post(
        "real-estates/$realEstateId/costs",
        data: {
          'amount': amount,
          'account_source_id': accountSourceId,
          'note': note,
          'cost_date':
              costDate?.toIso8601String().substring(0, 10),
        },
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data['message'] ?? 'Không thể thêm chi phí BĐS';
      throw Exception(msg);
    }
  }

  // =========================
  // SELL REAL ESTATE
  // =========================
  Future<double> sell({
    required int realEstateId,
    required double sellPrice,
    DateTime? sellDate,
    String? note,
  }) async {
    try {
      final res = await dio.post(
        "real-estates/$realEstateId/sell",
        data: {
          'sell_price': sellPrice,
          'sell_date': sellDate?.toIso8601String(),
          'note': note,
        },
      );

      return double.parse(res.data['profit'].toString());
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Không thể bán BĐS';
      throw Exception(msg);
    }
  }
}
