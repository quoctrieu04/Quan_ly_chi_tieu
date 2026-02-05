import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'real_estate_income_plan_model.dart';
import 'real_estate_income_plan_service.dart';

class RealEstateIncomePlanProvider extends ChangeNotifier {
  final RealEstateIncomePlanService _service;

  RealEstateIncomePlanProvider(Dio dio)
      : _service = RealEstateIncomePlanService(dio);

  RealEstateIncomePlan? plan;

  bool loading = false;      // load / create / update / delete
  bool collecting = false;  // riêng cho thu tiền

  // ==========================
  // LOAD PLAN
  // ==========================
  Future<void> load(int realEstateId) async {
    loading = true;
    notifyListeners();

    plan = await _service.fetchIncomePlan(realEstateId);

    loading = false;
    notifyListeners();
  }

  // ==========================
  // CREATE PLAN
  // ==========================
  Future<void> createPlan({
  required int realEstateId,
  required double monthlyAmount,
  required DateTime startDate,
  required int bankAccountId, // 🔥 THÊM
}) async {
  loading = true;
  notifyListeners();

  await _service.createIncomePlan(
    realEstateId: realEstateId,
    monthlyAmount: monthlyAmount,
    startDate: startDate,
    bankAccountId: bankAccountId, // 🔥 TRUYỀN XUỐNG
  );

  plan = await _service.fetchIncomePlan(realEstateId);

  loading = false;
  notifyListeners();
}


  // ==========================
  // COLLECT (THU TIỀN)
  // ==========================
  Future<void> collect() async {
    if (plan == null || collecting) return;

    collecting = true;
    notifyListeners();

    await _service.collectIncomePlan(
      incomePlanId: plan!.id,
    );

    // 🔥 bắt buộc reload lại plan từ backend
    plan = await _service.fetchIncomePlan(plan!.realEstateId);

    collecting = false;
    notifyListeners();
  }

  // ==========================
  // UPDATE PLAN
  // ==========================
  Future<void> updatePlan({
    required double monthlyAmount,
    required DateTime nextDueDate,
  }) async {
    if (plan == null) return;

    loading = true;
    notifyListeners();

    await _service.updateIncomePlan(
      incomePlanId: plan!.id,
      monthlyAmount: monthlyAmount,
      nextDueDate: nextDueDate,
    );

    plan = await _service.fetchIncomePlan(plan!.realEstateId);

    loading = false;
    notifyListeners();
  }

  // ==========================
  // DELETE PLAN
  // ==========================
  Future<void> deletePlan() async {
    if (plan == null) return;

    loading = true;
    notifyListeners();

    await _service.deleteIncomePlan(
      incomePlanId: plan!.id,
    );

    plan = null;

    loading = false;
    notifyListeners();
  }
}
