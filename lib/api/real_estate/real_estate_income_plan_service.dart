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
    final msg =
        e.response?.data['message'] ?? 'Không thể tạo khoản thu';
    throw Exception(msg);
  }
}


  // =========================
  // COLLECT INCOME PLAN
  // =========================
  Future<void> collectIncomePlan({
    required int incomePlanId,
  }) async {
    try {
      await dio.post(
        "real-estate-income-plans/$incomePlanId/collect",
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data['message'] ?? 'Không thể thu tiền';
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
          'next_due_date':
              nextDueDate.toIso8601String().substring(0, 10),
        },
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data['message'] ?? 'Không thể cập nhật khoản thu';
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
      final msg =
          e.response?.data['message'] ?? 'Không thể xóa khoản thu';
      throw Exception(msg);
    }
  }
}
