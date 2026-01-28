import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class InvestmentService {
  final Dio dio;

  InvestmentService(this.dio);

  // =========================
  // FETCH INVESTMENTS
  // =========================
  Future<List<dynamic>> fetch() async {
    try {
      final res = await dio.get("investments");
      return (res.data is List) ? res.data : (res.data['data'] ?? []);
    } catch (e) {
      debugPrint("❌ FETCH INVESTMENTS ERROR: $e");
      rethrow;
    }
  }

  // =========================
  // FETCH BANK ACCOUNTS
  // =========================
  Future<List<dynamic>> fetchBankAccounts() async {
    try {
      final res = await dio.get("bankaccounts");
      return (res.data is List) ? res.data : (res.data['data'] ?? []);
    } catch (e) {
      debugPrint("❌ FETCH BANKACCOUNTS ERROR: $e");
      return [];
    }
  }

  // =========================
  // CREATE INVESTMENT
  // =========================
  Future<void> createRaw(Map<String, dynamic> data) async {
    try {
      await dio.post("investments", data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data['message'] ?? 'Lỗi không xác định';
        throw Exception(msg); // 🔥 NÉM LỖI LÊN UI
      }
      throw Exception('Không kết nối được server');
    }
  }

  // =========================
  // TOP UP BANK
  // =========================
  Future<bool> topUpBank({
    required int investmentId,
    required double amount,
    required int accountSourceId,
  }) async {
    try {
      final res = await dio.post(
        "investments/$investmentId/topup",
        data: {
          "amount": amount,
          "account_source_id": accountSourceId,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("❌ TOPUP ERROR: $e");
      return false;
    }
  }

  // =========================
  // ✅ WITHDRAW BANK (FIX CUỐI)
  // =========================
  Future<bool> withdrawBank({
    required int investmentId,
    required int receiveAccountId,
    required WithdrawType withdrawType,
    double? amount, // ✅ THÊM DÒNG NÀY
  }) async {
    try {
      final Map<String, dynamic> data = {
        'receive_account_id': receiveAccountId,
        'withdraw_type': withdrawType.name,
      };

      if (amount != null) {
        data['amount'] = amount;
      }

      final res = await dio.post(
        "investments/$investmentId/withdraw",
        data: data,
      );

      debugPrint('✅ WITHDRAW STATUS: ${res.statusCode}');
      debugPrint('✅ WITHDRAW RESPONSE: ${res.data}');

      return res.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ WITHDRAW ERROR: ${e.response?.data}');
      return false;
    }
  }

  // =========================
  // UPDATE STOCK PRICE
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
  // DELETE INVESTMENT
  // =========================
  Future<bool> delete(int id) async {
    try {
      final res = await dio.delete("investments/$id");
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint("❌ DELETE INVESTMENT ERROR: $e");
      return false;
    }
  }

  // =========================
  // REAL ESTATE COST
  // =========================
  Future<bool> addRealEstateCost(Map<String, dynamic> data) async {
    try {
      final res = await dio.post(
        "investments/real-estate-cost",
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("❌ REAL ESTATE COST ERROR: $e");
      return false;
    }
  }

  // =========================
  // 🔁 RENEW BANK INVESTMENT
  // =========================
  Future<bool> renewBankInvestment(int investmentId) async {
    try {
      final res = await dio.post(
        "investments/$investmentId/renew",
      );

      debugPrint('✅ RENEW STATUS: ${res.statusCode}');
      debugPrint('✅ RENEW RESPONSE: ${res.data}');

      return res.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ RENEW ERROR: ${e.response?.data}');
      final msg = e.response?.data['message'] ?? 'Gia hạn thất bại';
      throw Exception(msg);
    }
  }

  // =========================
// 🔒 CLOSE INVESTMENT (ĐÓNG KHOẢN CŨ)
// =========================
  Future<void> closeInvestment(int investmentId) async {
    try {
      await dio.post("investments/$investmentId/close");
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Không thể đóng khoản đầu tư';
      throw Exception(msg);
    }
  }
}
