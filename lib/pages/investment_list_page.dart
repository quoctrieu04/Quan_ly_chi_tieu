import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/widgets/create_investment_form.dart';

class InvestmentListPage extends StatelessWidget {
  const InvestmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InvestmentProvider>();
    final items = prov.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đầu tư'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const CreateInvestmentForm(),
              );
              if (created == true && context.mounted) {
                await prov.fetch();
              }
            },
          )
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Chưa có khoản đầu tư'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final inv = items[i];
                return ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.trending_up),
                  title: Text(inv.name),
                  subtitle: Text(
                      'Đã đầu tư: ${inv.totalInvested}'),
                );
              },
            ),
    );
  }
}
