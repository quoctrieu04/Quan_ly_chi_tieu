import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/widgets/edit_bank_account_form.dart';
import 'package:chitieu/widgets/create_bank_account_form.dart';

import 'package:intl/intl.dart';

String formatMoney(num v) {
  final f = NumberFormat('#,###', 'vi_VN');
  return f.format(v);
}

class AccountsListPage extends StatefulWidget {
  const AccountsListPage({super.key});

  @override
  State<AccountsListPage> createState() => _AccountsListPageState();
}

class _AccountsListPageState extends State<AccountsListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<BankAccountProvider>().fetchAccounts();
    });
  }

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
              final created = await safeShowModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const CreateBankAccountForm(),
              );

              if (created == true && mounted) {
                await context.read<BankAccountProvider>().fetchAccounts();
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
                return _buildItem(context, acc);
              },
            ),
    );
  }

  Widget _buildItem(BuildContext context, acc) {
    final prov = context.read<BankAccountProvider>();

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
            Text(acc.bankname!, style: const TextStyle(fontSize: 13)),
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
          if (v == 'delete') {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Xóa tài khoản'),
                content: const Text('Bạn có chắc muốn xóa tài khoản này?'),
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
              await prov.deleteAccount(acc.id!);
              await prov.fetchAccounts();
            }
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Sửa')),
          PopupMenuItem(value: 'delete', child: Text('Xóa')),
        ],
      ),
    );
  }
}
