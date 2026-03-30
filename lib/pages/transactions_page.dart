import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:chitieu/api/out_invoice/out_invoice_provider.dart';
import 'package:chitieu/api/in_invoice/in_invoice_provider.dart';

import 'package:chitieu/core/money/money_formatter.dart';
import 'package:chitieu/core/money/money_settings_provider.dart';
import 'package:chitieu/core/money/money_settings.dart';

import 'package:chitieu/financial_transaction/financial_transaction_model.dart';
import 'package:chitieu/financial_transaction/financial_transaction_provider.dart';

enum HistoryTab { transaction, investment }

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

  HistoryTab _tab = HistoryTab.transaction;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentTab();
    });
  }

  Future<void> _fetchCurrentTab() async {
    if (_tab == HistoryTab.transaction) {
      await Future.wait([
        context.read<OutInvoiceProvider>().fetch(
              year: _year,
              month: _month,
              day: _day,
            ),
        context.read<InInvoiceProvider>().fetch(
              year: _year,
              month: _month,
              day: _day,
            ),
      ]);
    } else {
      await context.read<FinancialTransactionProvider>().fetchByMonth(
            year: _year,
            month: _month,
            day: _day,
            category: 'investment',
          );
    }
  }

  Future<void> _pickMonthDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, _day ?? 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      _year = picked.year;
      _month = picked.month;
      _day = picked.day;
    });

    await _fetchCurrentTab();
  }

  @override
  Widget build(BuildContext context) {
    final MoneySettings settings =
        context.watch<MoneySettingsProvider>().settings;

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthLabel =
        DateFormat.yMMMM(localeTag).format(DateTime(_year, _month));
    final dayLabel = (_day != null)
        ? DateFormat('dd MMMM yyyy', localeTag)
            .format(DateTime(_year, _month, _day!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _day == null ? 'Lịch sử • $monthLabel' : 'Lịch sử • $dayLabel',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickMonthDay,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabSwitcher(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCurrentTab,
              child: _tab == HistoryTab.transaction
                  ? _buildTransactionList(settings)
                  : _buildInvestmentList(settings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _tabBtn('Giao dịch', HistoryTab.transaction),
          const SizedBox(width: 8),
          _tabBtn('Đầu tư', HistoryTab.investment),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, HistoryTab tab) {
    final active = _tab == tab;
    const color = Color(0xFF8B5E00);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_tab == tab) return;
          setState(() => _tab = tab);
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _fetchCurrentTab());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
            color: active ? color.withOpacity(.15) : null,
          ),
          child: Center(
            child: Text(
              label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(MoneySettings settings) {
    final outProv = context.watch<OutInvoiceProvider>();
    final inProv = context.watch<InInvoiceProvider>();

    if (outProv.loading || inProv.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rows = [
      ...outProv.items.map(
        (e) => _TxnRow(
          amount: e.amount,
          type: 'out',
          date: e.occurredAt ?? e.createdAt ?? DateTime.now(),
          label: e.categoryName ?? 'Chi',
          content: e.content,
          photoUrl: e.photoUrl,
          photoPath: e.photoPath,
        ),
      ),
      ...inProv.items.map(
        (e) => _TxnRow(
          amount: e.amount,
          type: 'in',
          date: e.occurredAt ?? e.createdAt ?? DateTime.now(),
          label: e.categoryName ?? 'Thu',
          content: e.content,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (rows.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (_, i) => _transactionTile(rows[i], settings),
    );
  }

  Widget _transactionTile(_TxnRow tx, MoneySettings settings) {
    final isOut = tx.type == 'out';
    final color = isOut ? const Color(0xFFD64545) : const Color(0xFF1F9D4C);
    final sign = isOut ? '-' : '+';

    final hasPhoto = (tx.photoUrl != null && tx.photoUrl!.trim().isNotEmpty);
    final amountText = '$sign${MoneyFormatter(settings).format(tx.amount)}';

    final noteText = (tx.content != null && tx.content!.trim().isNotEmpty)
        ? tx.content!.trim()
        : DateFormat('dd/MM/yyyy HH:mm').format(tx.date);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.15),
        child: Icon(
          isOut ? Icons.call_made_rounded : Icons.call_received_rounded,
          color: color,
        ),
      ),
      title: Text(
        tx.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amountText,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              noteText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      trailing: hasPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: tx.photoUrl!,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                memCacheWidth: 160,
                maxWidthDiskCache: 320,
                fadeInDuration: Duration.zero,
                placeholder: (_, __) => Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                errorWidget: (_, error, __) {
                  debugPrint('IMAGE LOAD ERROR: $error');
                  debugPrint('IMAGE URL: ${tx.photoUrl}');
                  return Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_not_supported_outlined),
                  );
                },
              ),
            )
          : SizedBox(
              width: 68,
              child: Text(
                DateFormat('dd/MM').format(tx.date),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildInvestmentList(MoneySettings settings) {
    final prov = context.watch<FinancialTransactionProvider>();

    if (prov.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.items.isEmpty) {
      return const Center(child: Text('Chưa có lịch sử đầu tư'));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: prov.items.length,
      itemBuilder: (_, i) => _investmentTile(prov.items[i], settings),
    );
  }

  Widget _investmentTile(FinancialTransaction tx, MoneySettings settings) {
    final isOut = tx.direction == 'out';
    final color = isOut ? const Color(0xFFD64545) : const Color(0xFF1F9D4C);
    final sign = isOut ? '-' : '+';

    final subtitle =
        (tx.description != null && tx.description!.trim().isNotEmpty)
            ? tx.description!
            : DateFormat('dd/MM/yyyy HH:mm').format(tx.occurredAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.15),
        child: Icon(
          isOut ? Icons.call_made_rounded : Icons.call_received_rounded,
          color: color,
        ),
      ),
      title: Text(
        tx.title.isNotEmpty ? tx.title : 'Giao dịch',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$sign${MoneyFormatter(settings).format(tx.amount)}',
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _TxnRow {
  final num amount;
  final String type;
  final DateTime date;
  final String label;
  final String? content;
  final String? photoUrl;
  final String? photoPath;

  _TxnRow({
    required this.amount,
    required this.type,
    required this.date,
    required this.label,
    this.content,
    this.photoUrl,
    this.photoPath,
  });
}