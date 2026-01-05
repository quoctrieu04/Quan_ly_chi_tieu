import 'package:flutter/material.dart';
import 'in_invoice_model.dart';
import 'in_invoice_service.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class InInvoiceProvider with ChangeNotifier {
  final InInvoiceService api;
  BankAccountProvider? _bankAccounts;

  InInvoiceProvider({
    required this.api,
    required BankAccountProvider? bankAccounts,
  }) : _bankAccounts = bankAccounts;

  List<InInvoice> _items = [];
  bool _loading = false;

  List<InInvoice> get items => _items;
  bool get loading => _loading;

  void updateDeps({BankAccountProvider? bankAccounts}) {
    if (bankAccounts != null) _bankAccounts = bankAccounts;
  }

  /// 🧾 Lấy danh sách phiếu thu theo tháng/năm hoặc ngày
  Future<void> fetch({int? year, int? month, int? day}) async {
    _loading = true;
    notifyListeners();

    try {
      final y = year ?? DateTime.now().year;
      final m = month ?? DateTime.now().month;

      // 🟢 Gọi API — backend trả {data: [...], total, message, ...}
      final res = await api.fetchByMonth(year: y, month: m, day: day);

      // 🧩 Debug log để xem thực tế backend trả về gì
      debugPrint('📦 InInvoiceProvider response: $res');

      if (res is Map && res['data'] is List) {
        final list = res['data'] as List<dynamic>;
        _items = list.map((e) => InInvoice.fromJson(e)).toList();
      } else if (res is List) {
        _items = res.map((e) => InInvoice.fromJson(e)).toList();
      } else {
        _items = [];
      }

      debugPrint('✅ InInvoiceProvider.fetch loaded ${_items.length} items');
    } catch (e, st) {
      debugPrint('❌ InInvoiceProvider.fetch error: $e\n$st');
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ➕ Tạo phiếu thu mới (có ngày phát sinh)
  Future<bool> create(BuildContext context, InInvoice invoice) async {
    try {
      final now = DateTime.now();

      final payload = {
        ...invoice.toJson(),
        'month': now.month,
        'year': now.year,
        if (invoice.occurredAt != null)
          'occurred_at': invoice.occurredAt!.toIso8601String(),
      };

      await api.create(payload);

      // 🔁 Làm mới danh sách
      await fetch(year: now.year, month: now.month);
      await _bankAccounts?.fetchAccounts();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm phiếu thu thành công')),
        );
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ InInvoiceProvider.create error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm phiếu thu: $e')),
        );
      }
      return false;
    }
  }

  /// ➕ Tạo trực tiếp (dùng cho auto sync)
  Future<void> createDirect(Map<String, dynamic> data) async {
    final now = DateTime.now();
    await api.create({
      ...data,
      'month': now.month,
      'year': now.year,
    });
    await fetch(year: now.year, month: now.month);
    notifyListeners();
  }
}
