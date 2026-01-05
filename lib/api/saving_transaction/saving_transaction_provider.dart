import 'package:flutter/material.dart';
import 'saving_transaction_service.dart';
import 'saving_transaction_model.dart';

class SavingTransactionProvider with ChangeNotifier {
  final SavingTransactionService api;

  SavingTransactionProvider({required this.api});

  List<SavingTransaction> items = [];
  bool loading = false;

  Future<void> load(int savingId) async {
    loading = true;
    notifyListeners();

    try {
      items = await api.index(savingId);
    } catch (e) {
      print("SavingTransaction load error: $e");
    }

    loading = false;
    notifyListeners();
  }

  Future<bool> create(int savingId, Map<String, dynamic> data) async {
    try {
      final tran = await api.create(savingId, data);
      items.insert(0, tran);
      notifyListeners();
      return true;
    } catch (e) {
      print("SavingTransaction create error: $e");
      return false;
    }
  }
}
