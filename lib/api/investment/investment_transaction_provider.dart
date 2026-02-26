import 'package:flutter/material.dart';
import 'investment_transaction_model.dart';
import 'investment_transaction_service.dart';

class InvestmentTransactionProvider extends ChangeNotifier {
  final InvestmentTransactionService service;
  InvestmentTransactionProvider(this.service);

  bool loading = false;
  String? error;
  List<InvestmentTransaction> items = [];

  Future<void> fetchByMonth({
    required int year,
    required int month,
    int? day,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      items = await service.getByMonth(
        year: year,
        month: month,
        day: day,
      );
    } catch (e) {
      error = e.toString();
      items = [];
    }

    loading = false;
    notifyListeners();
  }

  void clear() {
    items = [];
    error = null;
    loading = false;
    notifyListeners();
  }
}
