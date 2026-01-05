import 'package:flutter/material.dart';
import 'bank_transaction_model.dart';
import 'bank_transaction_service.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class BankTransactionProvider with ChangeNotifier {
  final BankTransactionService api;
  BankAccountProvider? _bankAccounts;

  BankTransactionProvider({
    required this.api,
    required BankAccountProvider? bankAccounts,
  }) : _bankAccounts = bankAccounts;

  List<BankTransaction> _items = [];
  bool _loading = false;

  List<BankTransaction> get items => _items;
  bool get loading => _loading;

  void updateDeps({BankAccountProvider? bankAccounts}) {
    if (bankAccounts != null) _bankAccounts = bankAccounts;
  }

  /// 📆 Lấy giao dịch theo tháng/năm
  Future<void> fetch({int? year, int? month}) async {
    _loading = true;
    notifyListeners();

    try {
      final y = year ?? DateTime.now().year;
      final m = month ?? DateTime.now().month;
      _items = await api.fetchByMonth(year: y, month: m);
    } catch (e) {
      debugPrint('❌ BankTransactionProvider.fetch error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ➕ Tạo giao dịch mới (thu hoặc chi)
  Future<void> create(BankTransaction tx) async {
    try {
      await api.create(tx.toJson());
      final now = DateTime.now();
      await fetch(year: now.year, month: now.month);
      await _bankAccounts?.fetchAccounts();
    } catch (e) {
      debugPrint('❌ BankTransactionProvider.create error: $e');
    }
  }
}
