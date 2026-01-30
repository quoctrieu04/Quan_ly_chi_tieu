import 'package:flutter/material.dart';
import 'real_estate_service.dart';
import 'real_estate_model.dart';

class RealEstateProvider extends ChangeNotifier {
  final RealEstateService service;

  RealEstateProvider({required this.service});

  bool _loading = false;
  String? _error;
  List<RealEstate> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  List<RealEstate> get items => _items;

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
      _items = data.map((e) => RealEstate.fromJson(e)).toList();
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
        'purchase_date':
            purchaseDate.toIso8601String().substring(0, 10),
        'account_source_id': accountSourceId,
        'note': notes,
      });

      await fetch(); // backend là source of truth
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // ===============================
  // ADD REAL ESTATE COST ✅ (CHUẨN)
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

      await fetch(); // reload lại danh sách & chi tiết
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }
}
