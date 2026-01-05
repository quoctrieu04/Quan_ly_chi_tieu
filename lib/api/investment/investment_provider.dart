import 'package:flutter/material.dart';
import 'investment_service.dart';
import 'investment_model.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentService api;

  InvestmentProvider({required this.api});

  List<Investment> items = [];
  bool loading = false;

  Future<void> fetch() async {
    loading = true;
    notifyListeners();
    try {
      final data = await api.fetch();
      items = data.map<Investment>((e) => Investment.fromJson(e)).toList();
    } catch (_) {
      items = [];
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> add(Investment inv) async {
    final ok = await api.create(inv.toJson());
    if (ok) {
      await fetch();
    }
    return ok;
  }

  Future<bool> updatePrice(int id, double price) async {
    final ok = await api.updatePrice(id, price);
    if (ok) {
      await fetch();
    }
    return ok;
  }

  Future<bool> remove(int id) async {
    final ok = await api.delete(id);
    if (ok) {
      items.removeWhere((i) => i.id == id);
      notifyListeners();
    }
    return ok;
  }
}
