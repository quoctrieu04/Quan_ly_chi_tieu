import 'package:flutter/foundation.dart';
import 'financial_transaction_model.dart';
import 'financial_transaction_service.dart';

class FinancialTransactionProvider extends ChangeNotifier {
  final FinancialTransactionService api;

  FinancialTransactionProvider(this.api);

  bool loading = false;
  List<FinancialTransaction> items = [];

  Future<void> fetchByMonth({
    required int year,
    required int month,
    int? day,
    String category = 'investment',
  }) async {
    loading = true;
    notifyListeners();

    try {
      items = await api.fetchHistory(
        year: year,
        month: month,
        day: day,
        category: category,
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    items = [];
    loading = false;
    notifyListeners();
  }
}