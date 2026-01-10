import 'package:flutter/material.dart';
import 'investment_service.dart';
import 'investment_model.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentService api;

  InvestmentProvider({required this.api});

  final List<Investment> _items = [];
  bool loading = false;

  List<Investment> get items => _items;

  // =========================
  // FILTER
  // =========================
  List<Investment> get banks =>
      _items.where((e) => e.type == 'bank').toList();

  List<Investment> get stocks =>
      _items.where((e) => e.type == 'stock').toList();
  List<Investment> get realEstates =>
    _items.where((e) => e.type == 'real_estate').toList();
  // =========================
  // FETCH
  // =========================
  Future<void> fetch() async {
    loading = true;
    notifyListeners();

    try {
      final rawList = await api.fetch(); // List<dynamic>

      if (rawList is List) {
        _items
          ..clear()
          ..addAll(
            rawList.map((e) => Investment.fromJson(e)),
          );

        // Sort mới nhất lên trên
        _items.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
      }
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
    try {
      final ok = await api.create(inv.toJson());
      if (ok) {
        await fetch(); // reload từ server cho chắc
      }
      return ok;
    } catch (e) {
      debugPrint("❌ Error when adding investment: $e");
      return false;
    }
  }

  // =========================
  // UPDATE PRICE (CHỈ STOCK)
  // =========================
  Future<bool> updatePrice(int id, double price) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return false;

    final inv = _items[idx];
    if (inv.type != 'stock') return false; // ⛔ bank không update giá

    final ok = await api.updatePrice(id, price);
    if (ok) {
      _items[idx] = inv.copyWith(currentPrice: price);
      notifyListeners();
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

  double get totalInvested =>
      _items.fold(0, (sum, e) => sum + e.totalInvested);

  double get totalProfit =>
      _items.fold(0, (sum, e) => sum + e.profitLoss);

  double get totalProfitPercent {
    if (totalInvested == 0) return 0;
    return totalProfit / totalInvested * 100;
  }

  // =========================
  // OPTIONAL (RẤT HAY DÙNG)
  // =========================

  double get bankTotalInvested =>
      banks.fold(0, (sum, e) => sum + e.totalInvested);

  double get bankTotalProfit =>
      banks.fold(0, (sum, e) => sum + e.profitLoss);

  double get stockTotalInvested =>
      stocks.fold(0, (sum, e) => sum + e.totalInvested);

  double get stockTotalProfit =>
      stocks.fold(0, (sum, e) => sum + e.profitLoss);
}
