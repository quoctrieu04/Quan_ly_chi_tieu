import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/widgets/create_bank_account_form.dart';
import 'package:chitieu/widgets/edit_bank_account_form.dart';
import 'package:intl/intl.dart';

String formatMoney(num v) {
  final f = NumberFormat('#,###', 'vi_VN');
  return f.format(v);
}

class AccountsListPage extends StatelessWidget {
  const AccountsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BankAccountProvider>();
    final items = prov.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
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
                builder: (_) => const CreateBankAccountForm(),
              );
              if (created == true && context.mounted) {
                prov.fetch();
              }
            },
          )
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Chưa có tài khoản'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final acc = items[i];
                return ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.account_balance_wallet),
                  title: Text(acc.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((acc.bankname ?? '').isNotEmpty)
                        Text(
                          acc.bankname!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Số dư: ${formatMoney(acc.balance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: acc.balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final updated = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => EditBankAccountForm(
                            accountId: acc.id,
                            initialName: acc.name,
                            initialBankName: acc.bankname,
                            initialBankNumber: acc.banknumber,
                            initialBalance: acc.balance,
                            initialCurrency: acc.currency,
                          ),
                        );
                        if (updated == true && context.mounted) {
                          prov.fetch();
                        }
                      }

                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xóa tài khoản'),
                            content: const Text(
                                'Bạn có chắc muốn xóa tài khoản này?'),
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
                          final success = await prov.deleteAccount(acc.id!);
                          if (success) {
                            await prov.fetchAccounts(); // hoặc prov.fetch()
                          }
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
