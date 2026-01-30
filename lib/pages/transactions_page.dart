import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chitieu/api/out_invoice/out_invoice_provider.dart';
import 'package:chitieu/api/in_invoice/in_invoice_provider.dart';
// import 'package:chitieu/api/out_invoice/out_invoice_model.dart';
// import 'package:chitieu/api/in_invoice/in_invoice_model.dart';

import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late int _year;
  late int _month;
  int? _day;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;

    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _day = null;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _year = (args['year'] as int?) ?? _year;
      _month = (args['month'] as int?) ?? _month;
      _day = args['day'] as int?;
    }

    _inited = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAll();
    });
  }

  /// 🔄 Gọi API lấy danh sách chi & thu theo năm/tháng/ngày
  Future<void> _fetchAll() async {
    debugPrint('🚀 Fetching transactions for $_day/$_month/$_year');
    await Future.wait([
      context.read<OutInvoiceProvider>().fetch(year: _year, month: _month, day: _day),
      context.read<InInvoiceProvider>().fetch(year: _year, month: _month, day: _day),
    ]);
  }

  /// 📅 Chọn lại ngày -> gọi API mới
  Future<void> _pickMonthDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, _day ?? 1),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Chọn ngày',
      cancelText: 'HUỶ',
      confirmText: 'OK',
    );

    if (picked == null) return;

    setState(() {
      _year = picked.year;
      _month = picked.month;
      _day = picked.day;
    });

    // 🟢 Gọi lại API sau khi chọn ngày
    await _fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final outProv = context.watch<OutInvoiceProvider>();
    final inProv = context.watch<InInvoiceProvider>();
    final settings = context.watch<MoneySettingsProvider>().settings;

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthLabel =
        DateFormat.yMMMM(localeTag).format(DateTime(_year, _month));
    final dayLabel = (_day != null)
        ? DateFormat('dd MMMM yyyy', localeTag)
            .format(DateTime(_year, _month, _day!))
        : null;

    // 🧾 Gộp danh sách chi & thu
    final List<_TxnRow> combined = [
      ...outProv.items.map((e) => _TxnRow(
            id: e.id,
            amount: e.amount,
            type: 'out',
            content: e.content,
            date: e.occurredAt ?? e.createdAt ?? DateTime.now(),
            label: e.categoryName ?? 'Chi: ${e.outcatId}',
          )),
      ...inProv.items.map((e) => _TxnRow(
            id: e.id,
            amount: e.amount,
            type: 'in',
            content: e.content,
            date: e.occurredAt ?? e.createdAt ?? DateTime.now(),
            label: e.categoryName ?? 'Thu: ${e.incatId}',
          )),
    ];

    // 🕓 Lọc theo ngày cụ thể (nếu có)
    final txs = (_day == null)
        ? combined
        : combined.where((t) =>
            t.date.year == _year &&
            t.date.month == _month &&
            t.date.day == _day);

    final loading = outProv.loading || inProv.loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _day == null
              ? 'Tất cả giao dịch • $monthLabel'
              : 'Tất cả giao dịch • $dayLabel',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Chọn ngày',
            onPressed: _pickMonthDay,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: Builder(
          builder: (context) {
            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (txs.isEmpty) {
              return const Center(child: Text('Chưa có dữ liệu'));
            }

            // 🔽 Sắp xếp mới nhất -> cũ nhất
            final sorted = txs.toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sorted.length,
              itemBuilder: (ctx, i) {
                final tx = sorted[i];
                final isOut = tx.type == 'out';
                final sign = isOut ? '-' : '+';
                final color =
                    isOut ? const Color(0xFFD64545) : const Color(0xFF1F9D4C);
                final dateStr =
                    DateFormat('dd/MM/yyyy HH:mm').format(tx.date);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(.15),
                    child: Icon(
                      isOut
                          ? Icons.call_made_rounded
                          : Icons.call_received_rounded,
                      color: color,
                    ),
                  ),
                  title: Text(
                    tx.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    (tx.content?.isNotEmpty == true)
                        ? tx.content!
                        : dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '$sign${MoneyFormatter(settings).format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TxnRow {
  final int id;
  final num amount;
  final String type; // "out" | "in"
  final String? content;
  final DateTime date;
  final String label;

  _TxnRow({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.label,
    this.content,
  });
}
