import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'budget_model.dart';
import 'budget_service.dart';

class BudgetsProvider extends ChangeNotifier {
  final BudgetService service;
  BudgetsProvider(this.service);

  int _gen = 0;
  void _bumpGen() => _gen++;

  final List<BudgetItem> _items = <BudgetItem>[];
  UnmodifiableListView<BudgetItem> get items => UnmodifiableListView(_items);

  String? _currentUserId;
  int? _currentYear;
  int? _currentMonth;

  String? get currentUserId => _currentUserId;
  int? get currentYear => _currentYear;
  int? get currentMonth => _currentMonth;

  bool loading = false;
  String? error;

  int _totalAssigned = 0;
  int get totalAssigned => _totalAssigned;

  int _totalBalance = 0;
  int _unallocated = 0;

  int get totalBalance => _totalBalance;
  int get unallocated => _unallocated;

  // 🧹 Reset toàn bộ dữ liệu khi logout
  void clear() {
    _items.clear();
    _currentUserId = null;
    _currentYear = null;
    _currentMonth = null;
    loading = false;
    error = null;
    _totalAssigned = 0;
    _totalBalance = 0;
    _unallocated = 0;
    _bumpGen();
    notifyListeners();
  }

  void setScope({
    required String userId,
    required int year,
    required int month,
  }) {
    final changed = (_currentUserId != userId) ||
        (_currentYear != year) ||
        (_currentMonth != month);

    _currentUserId = userId;
    _currentYear = year;
    _currentMonth = month;

    if (changed) {
      _items.clear();
      error = null;
      loading = false;
      _bumpGen();
      notifyListeners();
    }
  }

  /// 🧩 Load ngân sách + chi tiêu thực tế
  Future<void> loadForMonth({
    required int year,
    required int month,
  }) async {
    _currentYear = year;
    _currentMonth = month;

    final g = _gen;
    loading = true;
    error = null;
    notifyListeners();

    try {
      // 1️⃣ Gọi API lấy danh sách ngân sách
      final res = await service.getBudgets(year: year, month: month);
      if (g != _gen) return;

      final data = (res['data'] as List?) ?? const [];
      _totalAssigned = (res['total_assigned'] as num?)?.toInt() ?? 0;

      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is num) return value.toInt();
        if (value is String) {
          final cleaned = value.split('.').first;
          return int.tryParse(cleaned) ?? 0;
        }
        return 0;
      }

      final List<BudgetItem> loaded = data.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return BudgetItem.fromJson({
          'id': m['id'],
          'userId': m['user_id'],
          'categoryId': m['category_id'],
          'name': m['name'] ?? '',
          'year': m['year'],
          'month': m['month'],
          'amount': parseInt(m['amount']),
          'spent': parseInt(m['spent'] ?? m['used_amount']),
        });
      }).toList();

      final txMap = await service.getSpentByCategory(year: year, month: month);

      final Map<int, BudgetItem> merged = {
        for (final it in loaded) it.categoryId: it
      };

      txMap.forEach((catId, spentValue) {
        final spent = (spentValue is num)
            ? spentValue.toInt()
            : int.tryParse(spentValue.toString()) ?? 0;
        if (spent <= 0) return;
        if (merged.containsKey(catId)) {
          final old = merged[catId]!;
          merged[catId] = old.copyWith(spent: spent);
        } else {
          merged[catId] = BudgetItem(
            id: 0,
            userId: 0,
            categoryId: catId,
            name: 'Danh mục #$catId',
            year: year,
            month: month,
            amount: 0,
            spent: spent,
          );
        }
      });

      _items
        ..clear()
        ..addAll(merged.values);

      if (kDebugMode) {
        print('✅ [BudgetsProvider] Loaded ${_items.length} budgets '
            '(month=$month, year=$year)');
      }
    } catch (e, st) {
      if (g != _gen) return;
      error = 'Không tải được ngân sách: $e';
      if (kDebugMode) print('❌ BudgetsProvider.loadForMonth error: $e\n$st');
      _items.clear();
      _totalAssigned = 0;
    } finally {
      if (g == _gen) {
        loading = false;
        notifyListeners();
      }
    }
  }

  /// 💸 Phân bổ nhiều danh mục cùng lúc
  Future<void> assignMany({
    required int year,
    required int month,
    required Map<int, double> allocations,
  }) async {
    final g = _gen;

    final items = allocations.entries
        .map((e) => {'category_id': e.key, 'amount': e.value.round()})
        .toList();

    await service.assignMany(
      year: year,
      month: month,
      items: items,
    );

    if (g != _gen) return;
    await loadForMonth(year: year, month: month);
  }

  /// 💵 Phân bổ một danh mục riêng
  Future<void> setOne({
    required int categoryId,
    required num amount,
  }) async {
    final year = _currentYear ?? DateTime.now().year;
    final month = _currentMonth ?? DateTime.now().month;

    await service.setOne(
      year: year,
      month: month,
      categoryId: categoryId,
      amount: amount,
    );

    await loadForMonth(year: year, month: month);
  }
}
