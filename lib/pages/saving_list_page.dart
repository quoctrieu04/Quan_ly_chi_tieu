import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/saving/saving_provider.dart';
import 'package:chitieu/widgets/create_saving_form.dart';
import 'package:chitieu/widgets/saving_transaction_form.dart';
import 'package:chitieu/core/date/year_month_provider.dart';

class SavingListPage extends StatelessWidget {
  const SavingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SavingProvider>();
    final items = prov.items;
    final ym = context.read<YearMonthProvider>().ym;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiết kiệm'),
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
                builder: (_) => const CreateSavingForm(),
              );
              if (created == true && context.mounted) {
                await prov.fetch(year: ym.year, month: ym.month);
              }
            },
          )
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Chưa có kế hoạch tiết kiệm'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = items[i];
                return ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.savings),
                  title: Text(s.title),
                  subtitle: Text(
                      '${s.currentAmount} / ${s.targetAmount}'),
                  trailing: PopupMenuButton(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final updated =
                            await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) =>
                              SavingTransactionForm(saving: s),
                        );
                        if (updated == true && context.mounted) {
                          await prov.fetch(
                              year: ym.year, month: ym.month);
                        }
                      }

                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xóa tiết kiệm'),
                            content: const Text(
                                'Bạn có chắc muốn xóa kế hoạch này?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );

                        if (ok == true) {
                          await prov.remove(s.id!);
                          await prov.fetch(
                              year: ym.year, month: ym.month);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Cập nhật')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
