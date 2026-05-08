import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/widgets/investment/create_investment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../widgets/investment/investment_summary_card.dart';
import '../../widgets/investment/investment_item_tile.dart';
import 'real_estate_detail_page.dart';

class InvestmentListPage extends StatefulWidget {
  const InvestmentListPage({super.key});

  @override
  State<InvestmentListPage> createState() => _InvestmentListPageState();
}

class _InvestmentListPageState extends State<InvestmentListPage> {
  bool _bankExpanded = true;
  bool _stockExpanded = true;
  bool _reExpanded = true;

  Future<void> _openCreateForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateInvestmentSheet(),
    );

    if (created == true && mounted) {
      await context.read<InvestmentProvider>().fetch();
      await context.read<RealEstateProvider>().fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final investmentProv = context.watch<InvestmentProvider>();
    final realEstateProv = context.watch<RealEstateProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : AppColors.background;
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    String money(num v) => '${moneyFmt.format(v).replaceAll(',', '.')}đ';

    final bankItems = investmentProv.banks;
    final stockItems = investmentProv.stocks;
    final realEstateItems = realEstateProv.items;
    final totalCount =
        bankItems.length + stockItems.length + realEstateItems.length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Đầu tư',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? cs.outlineVariant.withOpacity(.1)
                : const Color(0xFFEEEFF3),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 3,
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          const InvestmentSummaryCard(),
          const SizedBox(height: 24),
          if (bankItems.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Tiền gửi ngân hàng',
              count: bankItems.length,
              color: cs.primary,
              isExpanded: _bankExpanded,
              onToggle: () => setState(() => _bankExpanded = !_bankExpanded),
              cs: cs,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              firstChild: Column(
                children: bankItems
                    .map((e) => InvestmentItemTile(investment: e))
                    .toList(),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _bankExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOut,
            ),
            const SizedBox(height: 18),
          ],
          if (stockItems.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Cổ phiếu',
              count: stockItems.length,
              color: const Color(0xFF3B82F6),
              isExpanded: _stockExpanded,
              onToggle: () => setState(() => _stockExpanded = !_stockExpanded),
              cs: cs,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              firstChild: Column(
                children: stockItems
                    .map((e) => InvestmentItemTile(investment: e))
                    .toList(),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _stockExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOut,
            ),
            const SizedBox(height: 18),
          ],
          if (realEstateItems.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Bất động sản',
              count: realEstateItems.length,
              color: const Color(0xFFF59E0B),
              isExpanded: _reExpanded,
              onToggle: () => setState(() => _reExpanded = !_reExpanded),
              cs: cs,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              firstChild: Column(
                children: realEstateItems
                    .map((e) => _RealEstateTile(
                          item: e,
                          cs: cs,
                          isDark: isDark,
                          money: money,
                        ))
                    .toList(),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _reExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOut,
            ),
          ],
          if (totalCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 40,
                      color: cs.onSurface.withOpacity(.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có khoản đầu tư',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          AnimatedRotation(
            turns: isExpanded ? 0 : -0.25,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: cs.onSurface.withOpacity(.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealEstateTile extends StatelessWidget {
  final dynamic item;
  final ColorScheme cs;
  final bool isDark;
  final String Function(num) money;

  const _RealEstateTile({
    required this.item,
    required this.cs,
    required this.isDark,
    required this.money,
  });

  String _safeText(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? '' : s;
  }

  @override
  Widget build(BuildContext context) {
    final price = (item.totalCost ?? item.purchasePrice ?? 0) as num;
    final name = _safeText(item.name).isEmpty ? 'Bất động sản' : item.name;
    final type = _safeText(item.propertyType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withOpacity(.08)
              : const Color(0xFFECEDF2),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RealEstateDetailPage(item: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '100%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá trị',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurface.withOpacity(.4),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          money(price),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurface.withOpacity(.4),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Đang giữ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
