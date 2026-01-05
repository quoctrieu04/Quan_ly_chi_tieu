import 'package:flutter/material.dart';
import 'out_invoice_model.dart';
import 'out_invoice_service.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';

class OutInvoiceProvider with ChangeNotifier {
  final OutInvoiceService api;
  BankAccountProvider? _bankAccounts;
  BudgetsProvider? _budgets;

  OutInvoiceProvider({
    required this.api,
    required BankAccountProvider? bankAccounts,
    required BudgetsProvider? budgets,
  })  : _bankAccounts = bankAccounts,
        _budgets = budgets;

  List<OutInvoice> _items = [];
  bool _loading = false;

  List<OutInvoice> get items => _items;
  bool get loading => _loading;

  void updateDeps({
    BankAccountProvider? bankAccounts,
    BudgetsProvider? budgets,
  }) {
    if (bankAccounts != null) _bankAccounts = bankAccounts;
    if (budgets != null) _budgets = budgets;
  }

  /// 📆 Lấy danh sách phiếu chi theo tháng/năm/ngày
  Future<void> fetch({int? year, int? month, int? day}) async {
    _loading = true;
    notifyListeners();

    try {
      final y = year ?? DateTime.now().year;
      final m = month ?? DateTime.now().month;

      // 🟢 Gọi API (trả về {data: [...], total, message, ...})
      final res = await api.fetchByMonth(year: y, month: m, day: day);

      // 📦 Debug log để xem thực tế API trả về
      debugPrint('📦 OutInvoiceProvider response: $res');

      if (res is Map && res['data'] is List) {
        final list = res['data'] as List<dynamic>;
        _items = list.map((e) => OutInvoice.fromJson(e)).toList();
      } else if (res is List) {
        _items = res.map((e) => OutInvoice.fromJson(e)).toList();
      } else {
        _items = [];
      }

      debugPrint('✅ OutInvoiceProvider.fetch loaded ${_items.length} items');
    } catch (e, st) {
      debugPrint('❌ OutInvoiceProvider.fetch error: $e\n$st');
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ➕ Tạo phiếu chi mới (có ngày phát sinh occurred_at)
  Future<bool> create(BuildContext context, OutInvoice invoice) async {
    try {
      final selectedYear = _budgets?.currentYear ?? DateTime.now().year;
      final selectedMonth = _budgets?.currentMonth ?? DateTime.now().month;

      final payload = {
        ...invoice.toJson(),
        'month': selectedMonth,
        'year': selectedYear,
        if (invoice.occurredAt != null)
          'occurred_at': invoice.occurredAt!.toIso8601String(), // 🟢 gửi ngày thực tế
      };

      await api.create(payload);

      // 🔁 Sau khi thêm mới: refresh danh sách
      await fetch(year: selectedYear, month: selectedMonth);
      await _bankAccounts?.fetchAccounts();
      await _budgets?.loadForMonth(year: selectedYear, month: selectedMonth);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm phiếu chi thành công')),
        );
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ OutInvoiceProvider.create error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm phiếu chi: $e')),
        );
      }
      return false;
    }
  }

  /// ➕ Tạo nhanh (không cần context)
  Future<void> createDirect(Map<String, dynamic> data) async {
    final selectedYear = _budgets?.currentYear ?? DateTime.now().year;
    final selectedMonth = _budgets?.currentMonth ?? DateTime.now().month;

    await api.create({
      ...data,
      'month': selectedMonth,
      'year': selectedYear,
    });

    await fetch(year: selectedYear, month: selectedMonth);
    notifyListeners();
  }
}
