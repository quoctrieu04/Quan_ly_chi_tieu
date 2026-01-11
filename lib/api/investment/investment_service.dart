import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class InvestmentService {
  final Dio dio;

  InvestmentService(this.dio);

  // =========================
  // FETCH LIST
  // =========================
  Future<List<dynamic>> fetch() async {
    try {
      final res = await dio.get("investments");
      return res.data;
    } catch (e) {
      debugPrint("❌ FETCH INVESTMENTS ERROR: $e");
      rethrow;
    }
  }

  // =========================
  // CREATE INVESTMENT (LEDGER)
  // =========================
  Future<bool> createRaw(Map<String, dynamic> data) async {
    try {
      debugPrint("📤 POST /investments");
      debugPrint("📦 PAYLOAD: $data");

      final res = await dio.post(
        "investments",
        data: data,
      );

      debugPrint("📥 STATUS: ${res.statusCode}");
      debugPrint("📥 RESPONSE: ${res.data}");

      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      debugPrint("🔥 DIO ERROR: ${e.response?.statusCode}");
      debugPrint("🔥 BODY: ${e.response?.data}");
      return false;
    } catch (e) {
      debugPrint("🔥 UNKNOWN ERROR: $e");
      return false;
    }
  }

  // =========================
  // UPDATE PRICE (STOCK ONLY)
  // =========================
  Future<bool> updatePrice(int id, double newPrice) async {
    try {
      final res = await dio.put(
        "investments/$id",
        data: {"current_price": newPrice},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("❌ UPDATE PRICE ERROR: $e");
      return false;
    }
  }

  // =========================
  // DELETE
  // =========================
  Future<bool> delete(int id) async {
    try {
      final res = await dio.delete("investments/$id");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("❌ DELETE INVESTMENT ERROR: $e");
      return false;
    }
  }
}
