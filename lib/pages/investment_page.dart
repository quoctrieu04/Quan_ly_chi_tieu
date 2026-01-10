import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/widgets/create_investment_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/investment/investment_summary_card.dart';
import '../../widgets/investment/investment_item_tile.dart';

class InvestmentListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();

    Future<void> _openCreateForm() async {
      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const CreateInvestmentForm(),
      );

      if (created == true && context.mounted) {
        await context.read<InvestmentProvider>().fetch();
      }
    }

    Widget _emptyHint({
      required String text,
      required VoidCallback onAdd,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
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
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Tổng quan =====
          InvestmentSummaryCard(),
          const SizedBox(height: 20),

          // ===== Tiền gửi ngân hàng =====
          const Text(
            "💰 Tiền gửi ngân hàng",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (provider.banks.isEmpty)
            _emptyHint(
              text: 'Chưa có khoản tiền gửi ngân hàng nào',
              onAdd: _openCreateForm,
            )
          else
            ...provider.banks.map(
              (e) => InvestmentItemTile(investment: e),
            ),

          const SizedBox(height: 20),

          // ===== Cổ phiếu =====
          const Text(
            "📈 Cổ phiếu",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (provider.stocks.isEmpty)
            _emptyHint(
              text: 'Chưa có cổ phiếu nào',
              onAdd: _openCreateForm,
            )
          else
            ...provider.stocks.map(
              (e) => InvestmentItemTile(investment: e),
            ),
          // ===== BẤT ĐỘNG SẢN =====
          const SizedBox(height: 20),
          const Text(
            "🏠 Bất động sản",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (provider.realEstates.isEmpty)
            _emptyHint(
              text: 'Chưa có bất động sản nào',
              onAdd: _openCreateForm,
            )
          else
            ...provider.realEstates.map(
              (e) => InvestmentItemTile(investment: e),
            ),
        ],
      ),

      // ===== FAB =====
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
