import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/widgets/investment/create_investment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/investment/investment_summary_card.dart';
import '../../widgets/investment/investment_item_tile.dart';
import 'real_estate_detail_page.dart';

class InvestmentListPage extends StatelessWidget {
  const InvestmentListPage({super.key});

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

    Widget _emptyBox(String text) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.black38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _sectionCard({
      required IconData icon,
      required Color iconColor,
      required String title,
      required int count,
      required Widget child,
      bool initiallyExpanded = true,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                _CountPill(count: count),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _openCreateForm,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text("Thêm"),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
            children: [child],
          ),
        ),
      );
    }

    final bankItems = investmentProv.banks;
    final stockItems = investmentProv.stocks;
    final realEstateItems = realEstateProv.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đầu tư"),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: const [
                  InvestmentSummaryCard(),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _sectionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF2E7D32),
                    title: "Tiền gửi ngân hàng",
                    count: bankItems.length,
                    child: bankItems.isEmpty
                        ? _emptyBox("Chưa có khoản tiền gửi ngân hàng nào.")
                        : Column(
                            children: [
                              ...bankItems.map((e) => InvestmentItemTile(investment: e)),
                            ],
                          ),
                  ),

                  _sectionCard(
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF1565C0),
                    title: "Cổ phiếu",
                    count: stockItems.length,
                    child: stockItems.isEmpty
                        ? _emptyBox("Chưa có cổ phiếu nào.")
                        : Column(
                            children: [
                              ...stockItems.map((e) => InvestmentItemTile(investment: e)),
                            ],
                          ),
                  ),

                  _sectionCard(
                    icon: Icons.home_work_outlined,
                    iconColor: Colors.orange,
                    title: "Bất động sản",
                    count: realEstateItems.length,
                    child: realEstateItems.isEmpty
                        ? _emptyBox("Chưa có bất động sản nào.")
                        : Column(
                            children: [
                              ...realEstateItems.map((e) => RealEstateItemTile(item: e)),
                            ],
                          ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),

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

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class RealEstateItemTile extends StatelessWidget {
  final dynamic item;

  const RealEstateItemTile({super.key, required this.item});

  String _money(num v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
  }

  String _safeText(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? '' : s;
  }

  String _subtitle() {
    final type = _safeText(item.propertyType);
    final address = _safeText(item.address);

    if (type.isEmpty && address.isEmpty) return '—';
    if (type.isEmpty) return address;
    if (address.isEmpty) return type;
    return '$type • $address';
  }

  @override
  Widget build(BuildContext context) {
    final price = (item.totalCost ?? item.purchasePrice ?? 0) as num;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RealEstateDetailPage(item: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_outlined, color: Colors.orange),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeText(item.name).isEmpty ? 'Bất động sản' : item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(price),
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
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
          ],
        ),
      ),
    );
  }
}