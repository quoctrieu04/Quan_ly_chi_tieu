import 'package:flutter/material.dart';
import 'real_estate_service.dart';
import 'real_estate_model.dart';

class RealEstateProvider extends ChangeNotifier {
  final RealEstateService service;

  RealEstateProvider({required this.service});

  bool _loading = false;
  String? _error;
  List<RealEstateInvestment> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  List<RealEstateInvestment> get items => _items;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  /// ===============================
  /// FETCH LIST (OPTIONAL)
  /// ===============================
  Future<void> fetch() async {
    _setLoading(true);
    _setError(null);
    try {
      _items = await service.getAll();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// ===============================
  /// CREATE INVESTMENT
  /// ===============================
  Future<RealEstateInvestment?> create({
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
      final item = await service.createInvestment(
        name: name,
        propertyType: propertyType,
        address: address,
        purchasePrice: purchasePrice,
        purchaseDate: purchaseDate,
        accountSourceId: accountSourceId,
        notes: notes,
      );

      _items = [item, ..._items];
      notifyListeners();
      return item;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
}
