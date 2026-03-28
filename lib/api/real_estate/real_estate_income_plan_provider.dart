import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'real_estate_income_plan_model.dart';
import 'real_estate_income_plan_service.dart';

class RealEstateIncomePlanProvider extends ChangeNotifier {
  final RealEstateIncomePlanService _service;

  RealEstateIncomePlanProvider(Dio dio)
      : _service = RealEstateIncomePlanService(dio);

  RealEstateIncomePlan? plan;

  bool loading = false;
  bool collecting = false;

  // ==========================
  // LOAD PLAN
  // ==========================
  Future<void> load(int realEstateId) async {
    loading = true;
    notifyListeners();

    try {
      plan = await _service.fetchIncomePlan(realEstateId);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ==========================
  // CREATE PLAN
  // ==========================
  Future<void> createPlan({
    required int realEstateId,
    required double monthlyAmount,
    required DateTime startDate,
    required int bankAccountId,
  }) async {
    loading = true;
    notifyListeners();

    try {
      await _service.createIncomePlan(
        realEstateId: realEstateId,
        monthlyAmount: monthlyAmount,
        startDate: startDate,
        bankAccountId: bankAccountId,
      );

      plan = await _service.fetchIncomePlan(realEstateId);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ==========================
  // COLLECT (THU TIỀN)
  // ==========================
  Future<void> collect() async {
  if (plan == null || collecting) return;

  final currentPlan = plan!;

  collecting = true;
  notifyListeners();

  try {
    await _service.collectIncomePlan(
      incomePlanId: currentPlan.id,
    );

    plan = await _service.fetchIncomePlan(currentPlan.realEstateId);
    debugPrint("✅ PLAN AFTER COLLECT FETCH: ${plan?.nextDueDate}");
  } finally {
    collecting = false;
    notifyListeners();
  }
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

    try {
      await _service.updateIncomePlan(
        incomePlanId: plan!.id,
        monthlyAmount: monthlyAmount,
        nextDueDate: nextDueDate,
      );

      plan = await _service.fetchIncomePlan(plan!.realEstateId);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ==========================
  // DELETE PLAN
  // ==========================
  Future<void> deletePlan() async {
    if (plan == null) return;

    loading = true;
    notifyListeners();

    try {
      await _service.deleteIncomePlan(
        incomePlanId: plan!.id,
      );

      plan = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}