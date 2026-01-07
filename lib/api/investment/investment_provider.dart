import 'package:flutter/material.dart';
import 'investment_service.dart';
import 'investment_model.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentService api;

  InvestmentProvider({required this.api});

  final List<Investment> _items = [];
  bool loading = false;

  List<Investment> get items => _items;

  List<Investment> get banks => _items.where((e) => e.type == 'bank').toList();

  List<Investment> get stocks =>
      _items.where((e) => e.type == 'stock').toList();

  // =========================
  // FETCH
  // =========================
  Future<void> fetch() async {
    loading = true;
    notifyListeners();

    try {
      final rawList = await api.fetch(); // List<dynamic>

      _items
        ..clear()
        ..addAll(
          rawList.map((e) => Investment.fromJson(e)),
        );
    } catch (e) {
      debugPrint("❌ Fetch investment error: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // CREATE
  // =========================
  Future<bool> add(Investment inv) async {
    final ok = await api.create(inv.toJson());
    if (ok) {
      await fetch(); // reload từ server cho chắc
    }
    return ok;
  }

  // =========================
  // UPDATE PRICE (STOCK)
  // =========================
  Future<bool> updatePrice(int id, double price) async {
    final ok = await api.updatePrice(id, price);
    if (ok) {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _items[idx] = _items[idx].copyWith(currentPrice: price);
        notifyListeners();
      }
    }
    return ok;
  }

  // =========================
  // DELETE
  // =========================
  Future<bool> remove(int id) async {
    final ok = await api.delete(id);
    if (ok) {
      _items.removeWhere((e) => e.id == id);
      notifyListeners();
    }
    return ok;
  }
  // =========================
  // SUMMARY
  // =========================

  double get totalInvested {
    return _items.fold(0, (sum, e) => sum + e.totalInvested);
  }

  double get totalProfit {
    return _items.fold(0, (sum, e) => sum + e.profitLoss);
  }

  double get totalProfitPercent {
    if (totalInvested == 0) return 0;
    return totalProfit / totalInvested * 100;
  }
}
