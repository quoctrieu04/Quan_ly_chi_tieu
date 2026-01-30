import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/widgets/investment/create_investment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/investment/investment_summary_card.dart';
import '../../widgets/investment/investment_item_tile.dart';
import 'real_estate_detail_page.dart';

class InvestmentListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final investmentProv = context.watch<InvestmentProvider>();
    final realEstateProv = context.watch<RealEstateProvider>();

    Future<void> _openCreateForm() async {
      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const CreateInvestmentSheet(),
      );

      if (created == true && context.mounted) {
        await investmentProv.fetch();
        await realEstateProv.fetch();
      }
    }

    Widget _emptyHint({
      required String text,
      required VoidCallback onAdd,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: onAdd,
              child: const Text('Thêm'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đầu tư"),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // ===== TỔNG QUAN =====
          InvestmentSummaryCard(),
          const SizedBox(height: 20),

          // ===== TIỀN GỬI NGÂN HÀNG =====
          const Text(
            "💰 Tiền gửi ngân hàng",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (investmentProv.banks.isEmpty)
            _emptyHint(
              text: 'Chưa có khoản tiền gửi ngân hàng nào',
              onAdd: _openCreateForm,
            )
          else
            ...investmentProv.banks.map(
              (e) => InvestmentItemTile(investment: e),
            ),

          const SizedBox(height: 20),

          // ===== CỔ PHIẾU =====
          const Text(
            "📈 Cổ phiếu",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (investmentProv.stocks.isEmpty)
            _emptyHint(
              text: 'Chưa có cổ phiếu nào',
              onAdd: _openCreateForm,
            )
          else
            ...investmentProv.stocks.map(
              (e) => InvestmentItemTile(investment: e),
            ),

          const SizedBox(height: 24),

          // ===== BẤT ĐỘNG SẢN =====
          Row(
            children: const [
              Icon(Icons.home_work_outlined,
                  color: Colors.orange, size: 18),
              SizedBox(width: 6),
              Text(
                "Bất động sản",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (realEstateProv.items.isEmpty)
            _emptyHint(
              text: 'Chưa có bất động sản nào',
              onAdd: _openCreateForm,
            )
          else
            ...realEstateProv.items.map(
              (e) => RealEstateItemTile(item: e),
            ),
        ],
      ),

      // ===== FAB =====
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
          onPressed: _openCreateForm,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class RealEstateItemTile extends StatelessWidget {
  final dynamic item;

  const RealEstateItemTile({super.key, required this.item});

  String _money(num v) {
    return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RealEstateDetailPage(item: item),
          ),
        );
      },
      child: Card(
        elevation: 1.5,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: Colors.orange,
            ),
          ),

          title: Text(
            item.name ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${item.propertyType} • ${item.address}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),

          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(item.totalCost ?? item.purchasePrice ?? 0),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Giá mua',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
