import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/widgets/create_income_form.dart';
import 'package:chitieu/widgets/edit_income_form.dart';
import 'package:chitieu/core/date/year_month_provider.dart';

class IncomeListPage extends StatelessWidget {
  const IncomeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<IncomeProvider>();
    final items = prov.items;
    final ym = context.read<YearMonthProvider>().ym;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nguồn tiền'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const CreateIncomeForm(),
              );
              if (created == true && context.mounted) {
                await prov.fetch(year: ym.year, month: ym.month);
              }
            },
          )
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Chưa có nguồn tiền'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final inc = items[i];
                return ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.attach_money),
                  title: Text(inc.title),
                  trailing: PopupMenuButton(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final updated = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => EditIncomeForm(
                            incomeId: inc.id!,
                            initialTitle: inc.title,
                            initialCurrency: inc.currency,
                          ),
                        );
                        if (updated == true && context.mounted) {
                          await prov.fetch(year: ym.year, month: ym.month);
                        }
                      }

                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xóa nguồn tiền'),
                            content: const Text(
                                'Bạn có chắc muốn xóa nguồn tiền này?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );

                        if (ok == true) {
                          final success =
                              await prov.deleteIncomeCategory(inc.id!);
                          if (success) {
                            await prov.fetch(year: ym.year, month: ym.month);
                          }
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
