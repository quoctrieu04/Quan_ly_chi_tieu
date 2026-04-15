import 'package:flutter/material.dart';

import 'investment_service.dart';
import 'investment_model.dart';
import '../bankaccount/bank_account_model.dart';

/// 🔹 Kiểu rút tiền
enum WithdrawType {
  interest, // rút lãi
  all, // rút toàn bộ (vốn + lãi)
  interestAndRenew, // rút lãi + gia hạn lại gốc
}

class InvestmentProvider extends ChangeNotifier {
  final InvestmentService api;

  InvestmentProvider({required this.api});

  // =========================
  // STATE
  // =========================
  final List<Investment> _items = [];
  final List<BankAccount> _bankAccounts = [];

  bool loading = false;

  List<Investment> get items => _items;
  List<BankAccount> get bankAccounts => _bankAccounts;

  // =========================
  // FILTER
  // =========================
  List<Investment> get banks => _items.where((e) => e.type == 'bank').toList();

  List<Investment> get stocks =>
      _items.where((e) => e.type == 'stock').toList();

  List<Investment> get realEstates =>
      _items.where((e) => e.type == 'real_estate').toList();

  // =========================
  // FETCH INVESTMENTS
  // =========================
  Future<void> fetch() async {
    loading = true;
    notifyListeners();

    try {
      final raw = await api.fetch();
      if (raw is List) {
        _items
          ..clear()
          ..addAll(
            raw
                .map((e) => Investment.fromJson(e))
                .where((i) => i.closedAt == null),
          );
      }
    } catch (e) {
      debugPrint('❌ fetch investments error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // FETCH BANK ACCOUNTS
  // =========================
  Future<void> fetchBankAccounts() async {
    try {
      final raw = await api.fetchBankAccounts();
      if (raw is List) {
        _bankAccounts
          ..clear()
          ..addAll(raw.map((e) => BankAccount.fromJson(e)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ fetch bank accounts error: $e');
    }
  }

  // =========================
  // CREATE INVESTMENT
  // =========================
  Future<void> addRaw(Map<String, dynamic> payload) async {
    try {
      await api.createRaw(payload);
      await fetch();
      await fetchBankAccounts();
    } catch (e) {
      rethrow;
    }
  }

  // =========================
  // TOP UP (BANK)
  // =========================
  Future<bool> topUpBank(
    int investmentId,
    double amount,
    int accountSourceId,
  ) async {
    try {
      final ok = await api.topUpBank(
        investmentId: investmentId,
        amount: amount,
        accountSourceId: accountSourceId,
      );

      if (ok) {
        await fetch();
        await fetchBankAccounts();
      }
      return ok;
    } catch (e) {
      debugPrint('❌ topUpBank error: $e');
      return false;
    }
  }

  // =========================
  // WITHDRAW (BANK)
  // =========================
  Future<void> withdrawBank(
    int investmentId,
    int receiveAccountId, {
    required WithdrawType withdrawType,
    double? amount,
  }) async {
    try {
      await api.withdrawBank(
        investmentId: investmentId,
        receiveAccountId: receiveAccountId,
        withdrawType: withdrawType,
        amount: amount,
      );

      await fetch();
      await fetchBankAccounts();
    } catch (e) {
      rethrow;
    }
  }

  // =========================
  // REAL ESTATE COST
  // =========================
  Future<bool> addRealEstateCost(
    int investmentId,
    double amount,
    int accountSourceId,
    String note,
  ) async {
    try {
      final ok = await api.addRealEstateCost({
        'investment_id': investmentId,
        'amount': amount,
        'accountSource': accountSourceId,
        'note': note,
      });

      if (ok) {
        await fetch();
        await fetchBankAccounts();
      }
      return ok;
    } catch (e) {
      debugPrint('❌ addRealEstateCost error: $e');
      return false;
    }
  }

  // =========================
  // UPDATE STOCK PRICE
  // =========================
  Future<bool> updatePrice(int id, double price) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return false;

    final inv = _items[idx];
    if (inv.type != 'stock') return false;

    final ok = await api.updatePrice(id, price);
    if (ok) {
      _items[idx] = inv.copyWith(currentPrice: price);
      notifyListeners();
    }
    return ok;
  }

  // =========================
  // DELETE INVESTMENT
  // =========================
  Future<bool> remove(int id) async {
    try {
      final ok = await api.delete(id);
      if (ok) {
        _items.removeWhere((e) => e.id == id);
        notifyListeners();
        await fetchBankAccounts();
      }
      return ok;
    } catch (e) {
      debugPrint('❌ remove investment error: $e');
      return false;
    }
  }

  // =========================
  // SUMMARY (UI)
  // =========================
  double get totalInvested => _items
      .where((e) => e.closedAt == null)
      .fold(0, (sum, e) => sum + e.totalInvested);

  double get totalProfit => _items
      .where((e) => e.closedAt == null)
      .fold(0, (sum, e) => sum + e.profitLoss);

  double get totalProfitPercent {
    if (totalInvested == 0) return 0;
    return totalProfit / totalInvested * 100;
  }

  // =========================
  // RENEW BANK INVESTMENT
  // =========================
  Future<void> renewBankInvestment(int investmentId) async {
    try {
      await api.renewBankInvestment(investmentId);
      await fetch();
      await fetchBankAccounts();
    } catch (e) {
      rethrow;
    }
  }
}