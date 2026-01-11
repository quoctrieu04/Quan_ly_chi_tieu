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
      final rawList = await api.fetch();
      if (rawList is List) {
        _items
          ..clear()
          ..addAll(rawList.map((e) => Investment.fromJson(e)));

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
  // CREATE (RAW LEDGER)
  // =========================
  Future<bool> addRaw(Map<String, dynamic> payload) async {
    try {
      debugPrint("📤 addRaw payload: $payload");

      final ok = await api.createRaw(payload);

      debugPrint("📥 addRaw result: $ok");

      if (ok) {
        await fetch();
        return true;
      }

      return false;
    } catch (e, s) {
      debugPrint("🔥 addRaw exception: $e");
      debugPrint("📍 stacktrace: $s");
      return false;
    }
  }

  // =========================
  // UPDATE PRICE (STOCK)
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
  // SUMMARY (UI ONLY)
  // =========================
  double get totalInvested =>
      _items.fold(0, (sum, e) => sum + e.totalInvested);

  double get totalProfit =>
      _items.fold(0, (sum, e) => sum + e.profitLoss);

  double get totalProfitPercent {
    if (totalInvested == 0) return 0;
    return totalProfit / totalInvested * 100;
  }

  double get bankTotalInvested =>
      banks.fold(0, (sum, e) => sum + e.totalInvested);

  double get bankTotalProfit =>
      banks.fold(0, (sum, e) => sum + e.profitLoss);

  double get stockTotalInvested =>
      stocks.fold(0, (sum, e) => sum + e.totalInvested);

  double get stockTotalProfit =>
      stocks.fold(0, (sum, e) => sum + e.profitLoss);
}
