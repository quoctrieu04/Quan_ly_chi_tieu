import 'package:flutter/material.dart';
import 'real_estate_service.dart';
import 'real_estate_income_plan_service.dart';
import 'real_estate_model.dart';

class RealEstateProvider extends ChangeNotifier {
  final RealEstateService service;
  final RealEstateIncomePlanService incomePlanService;

  RealEstateProvider({
    required this.service,
    required this.incomePlanService,
  });

  bool _loading = false;
  String? _error;
  List<RealEstate> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  List<RealEstate> get items => _items;

  // ===============================
  // SUMMARY (UI)
  // ===============================
  double get totalInvested => _items
      .where((e) => !e.isSold)
      .fold(0.0, (sum, e) => sum + (e.totalCost > 0 ? e.totalCost : e.purchasePrice));

  double get totalProfit => _items
      .where((e) => !e.isSold)
      .fold(0.0, (sum, e) => sum + e.profit);

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  // ===============================
  // FETCH LIST
  // ===============================
  Future<void> fetch() async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await service.fetch();
      final parsedItems = data.map((e) => RealEstate.fromJson(e)).toList();

      // Tạm thời fetch income plan cho từng BĐS để hỗ trợ hiển thị Badge
      // (Cách tốt nhất là Backend trả về luôn mảng income_plans trong API danh sách)
      for (var item in parsedItems) {
        if (!item.isSold) {
          try {
            final plan = await incomePlanService.fetchIncomePlan(item.id);
            if (plan != null) {
              item.incomePlans = [plan];
            }
          } catch (e) {
            debugPrint("Lỗi lấy khoản thu cho BĐS ${item.id}: $e");
          }
        }
      }

      _items = parsedItems;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ===============================
  // CREATE REAL ESTATE
  // ===============================
  Future<void> create({
    required String name,
    required String propertyType,
    required String address,
    required double purchasePrice,
    required DateTime purchaseDate,
    required int accountSourceId,
    String? notes,
  }) async {
    _setError(null);
    try {
      await service.create({
        'name': name,
        'property_type': propertyType,
        'address': address,
        'purchase_price': purchasePrice,
        'purchase_date': purchaseDate.toIso8601String().substring(0, 10),
        'account_source_id': accountSourceId,
        'note': notes,
      });

      await fetch();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // ===============================
  // ADD COST
  // ===============================
  Future<void> addCost({
    required int realEstateId,
    required double amount,
    required int accountSourceId,
    String? note,
    DateTime? costDate,
  }) async {
    _setError(null);
    try {
      await service.addCost(
        realEstateId: realEstateId,
        amount: amount,
        accountSourceId: accountSourceId,
        note: note,
        costDate: costDate,
      );

      await fetch();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

    // ===============================
  // SELL REAL ESTATE
  // ===============================
  Future<double> sell({
    required int realEstateId,
    required double sellPrice,
    required DateTime sellDate,
    required int accountTargetId,
  }) async {
    _setError(null);
    try {
      final profit = await service.sell(
        realEstateId: realEstateId,
        sellPrice: sellPrice,
        sellDate: sellDate,
        accountTargetId: accountTargetId,
      );

      await fetch();
      return profit;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }
  
}
