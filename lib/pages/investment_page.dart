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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đầu tư"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InvestmentSummaryCard(),
          const SizedBox(height: 20),
          const Text("💰 Tiền gửi ngân hàng",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...provider.banks.map(
            (e) => InvestmentItemTile(investment: e),
          ),
          const SizedBox(height: 20),
          const Text("📈 Cổ phiếu",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...provider.stocks.map(
            (e) => InvestmentItemTile(investment: e),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const CreateInvestmentForm(),
          );

          if (created == true && context.mounted) {
            await context.read<InvestmentProvider>().fetch();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
