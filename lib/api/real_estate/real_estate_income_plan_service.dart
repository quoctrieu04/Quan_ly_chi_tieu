import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'real_estate_income_plan_model.dart';

class RealEstateIncomePlanService {
  final Dio dio;

  RealEstateIncomePlanService(this.dio);

  // =========================
  // FETCH INCOME PLAN
  // =========================
  Future<RealEstateIncomePlan?> fetchIncomePlan(int realEstateId) async {
    try {
      final res = await dio.get(
        "real-estates/$realEstateId/income-plan",
      );

      debugPrint("📥 FETCH INCOME PLAN RESPONSE: ${res.data}");

      if (res.data['data'] == null) return null;
      return RealEstateIncomePlan.fromJson(res.data['data']);
    } catch (e) {
      debugPrint("❌ FETCH INCOME PLAN ERROR: $e");
      rethrow;
    }
  }

  // =========================
  // CREATE INCOME PLAN
  // =========================
  Future<void> createIncomePlan({
    required int realEstateId,
    required double monthlyAmount,
    required DateTime startDate,
    required int bankAccountId, // 🔥 THÊM
  }) async {
    debugPrint(
      "🔥 CREATE INCOME PLAN → real-estates/$realEstateId/income-plan",
    );

    try {
      await dio.post(
        "real-estates/$realEstateId/income-plan",
        data: {
          'monthly_amount': monthlyAmount,
          'start_date': startDate.toIso8601String().substring(0, 10),
          'bank_account_id': bankAccountId, // 🔥 GỬI LÊN BACKEND
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Không thể tạo khoản thu';
      throw Exception(msg);
    }
  }

  // =========================
  // COLLECT INCOME PLAN
  // =========================
  Future<void> collectIncomePlan({
    required int incomePlanId,
    int? receiveAccountId,
    DateTime? collectedAt,
    bool early = false,
    int months = 1,
    double? partialAmount,
    String? notes,
  }) async {
    try {
      if (early) {
        final Map<String, dynamic> data = {
          if (receiveAccountId != null) 'receive_account_id': receiveAccountId,
          'months': months,
          if (partialAmount != null) 'amount': partialAmount,
          if (notes != null && notes.isNotEmpty) 'note': notes,
        };

        final res = await dio.post(
          "real-estate-income-plans/$incomePlanId/collect-early",
          data: data,
        );
        debugPrint("✅ COLLECT EARLY RAW RESPONSE: ${res.data}");
        return;
      }

      final Map<String, dynamic> data = {
        if (receiveAccountId != null) 'receive_account_id': receiveAccountId,
        if (collectedAt != null)
          'collected_at': collectedAt.toIso8601String().substring(0, 10),
        'months': months,
        if (partialAmount != null) 'partial_amount': partialAmount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final res = await dio.post(
        "real-estate-income-plans/$incomePlanId/collect",
        data: data,
      );

      debugPrint("✅ COLLECT RAW RESPONSE: ${res.data}");
    } on DioException catch (e) {
      debugPrint("❌ COLLECT DIO ERROR: ${e.response?.data}");
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] ?? 'Không thể thu tiền')
          : 'Không thể thu tiền';
      throw Exception(msg);
    }
  }

  // =========================
  // UPDATE INCOME PLAN (SỬA)
  // =========================
  Future<void> updateIncomePlan({
    required int incomePlanId,
    required double monthlyAmount,
    required DateTime nextDueDate,
  }) async {
    try {
      await dio.put(
        "real-estate-income-plans/$incomePlanId",
        data: {
          'monthly_amount': monthlyAmount,
          'next_due_date': nextDueDate.toIso8601String().substring(0, 10),
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Không thể cập nhật khoản thu';
      throw Exception(msg);
    }
  }

  // =========================
  // DELETE INCOME PLAN (XÓA)
  // =========================
  Future<void> deleteIncomePlan({
    required int incomePlanId,
  }) async {
    try {
      await dio.delete(
        "real-estate-income-plans/$incomePlanId",
      );
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Không thể xóa khoản thu';
      throw Exception(msg);
    }
  }
}
