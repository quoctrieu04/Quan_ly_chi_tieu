import 'dart:io';

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

  Future<void> fetch({int? year, int? month, int? day}) async {
    _loading = true;
    notifyListeners();

    try {
      final y = year ?? DateTime.now().year;
      final m = month ?? DateTime.now().month;

      final res = await api.fetchByMonth(year: y, month: m, day: day);

      debugPrint('📦 OutInvoiceProvider response: $res');

      if (res is Map && res['data'] is List) {
        final list = res['data'] as List<dynamic>;
        _items = list
            .whereType<Map>()
            .map((e) => OutInvoice.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (res is List) {
        _items = res
            .whereType<Map>()
            .map((e) => OutInvoice.fromJson(Map<String, dynamic>.from(e)))
            .toList();
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

  Future<bool> create(
    BuildContext context,
    OutInvoice invoice, {
    File? photoFile,
  }) async {
    try {
      final selectedYear = _budgets?.currentYear ?? DateTime.now().year;
      final selectedMonth = _budgets?.currentMonth ?? DateTime.now().month;

      final payload = <String, dynamic>{
        ...invoice.toJson(),
        'month': selectedMonth,
        'year': selectedYear,
        if (invoice.occurredAt != null)
          'occurred_at': invoice.occurredAt!.toIso8601String(),
      };

      await api.create(
        payload,
        photoFile: photoFile,
      );

      await fetch(year: selectedYear, month: selectedMonth);
      await _bankAccounts?.fetchAccounts();
      await _budgets?.loadForMonth(
        year: selectedYear,
        month: selectedMonth,
      );

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

  Future<void> createDirect(
    Map<String, dynamic> data, {
    File? photoFile,
  }) async {
    final selectedYear = _budgets?.currentYear ?? DateTime.now().year;
    final selectedMonth = _budgets?.currentMonth ?? DateTime.now().month;

    await api.create(
      {
        ...data,
        'month': selectedMonth,
        'year': selectedYear,
      },
      photoFile: photoFile,
    );

    await fetch(year: selectedYear, month: selectedMonth);
    notifyListeners();
  }

  num get totalAmount => items.fold<num>(0, (sum, e) => sum + e.amount);
}