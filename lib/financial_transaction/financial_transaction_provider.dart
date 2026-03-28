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
    String? category,
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

  num get totalIncome => items.fold<num>(
        0,
        (sum, tx) => sum + (tx.direction == 'in' ? tx.amount : 0),
      );

  num get totalExpense => items.fold<num>(
        0,
        (sum, tx) => sum + (tx.direction == 'out' ? tx.amount : 0),
      );

  void clear() {
    items = [];
    loading = false;
    notifyListeners();
  }
}