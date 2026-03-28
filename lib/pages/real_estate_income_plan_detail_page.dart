import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/real_estate/real_estate_income_plan_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';

class RealEstateIncomePlanDetailPage extends StatefulWidget {
  final dynamic realEstate;

  const RealEstateIncomePlanDetailPage({
    super.key,
    required this.realEstate,
  });

  @override
  State<RealEstateIncomePlanDetailPage> createState() =>
      _RealEstateIncomePlanDetailPageState();
}

class _RealEstateIncomePlanDetailPageState
    extends State<RealEstateIncomePlanDetailPage> {
  String _money(num v) {
    return NumberFormat('#,###', 'vi').format(v);
  }

  bool _isDue(DateTime dueDate) {
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return !due.isAfter(current);
  }

  // ==========================
  // EDIT DIALOG
  // ==========================
  void _openEditDialog(BuildContext context, dynamic plan) {
    final amountCtrl =
        TextEditingController(text: plan.monthlyAmount.toString());
    DateTime dueDate = plan.nextDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sửa khoản thu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền / tháng',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kỳ thu tiếp theo'),
                subtitle: Text(DateFormat('MM/yyyy').format(dueDate)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dueDate = DateTime(picked.year, picked.month);
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final incomeProv =
                        context.read<RealEstateIncomePlanProvider>();

                    await incomeProv.updatePlan(
                      monthlyAmount: double.parse(amountCtrl.text.trim()),
                      nextDueDate: dueDate,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã cập nhật khoản thu'),
                        ),
                      );
                    }
                  },
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================
  // DELETE CONFIRM
  // ==========================
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa khoản thu'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa khoản thu này?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final incomeProv = context.read<RealEstateIncomePlanProvider>();
              await incomeProv.deletePlan();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa khoản thu'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeProv = context.watch<RealEstateIncomePlanProvider>();
    final plan = incomeProv.plan;

    // 🔥 QUAN TRỌNG: plan đã bị xóa → tự thoát
    if (plan == null) {
      return const Scaffold(
        body: Center(
          child: Text('Khoản thu đã bị xóa'),
        ),
      );
    }

    final isDue = plan.canCollectToday;
    final isCollectedThisPeriod = plan.isCurrentPeriodCollected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khoản thu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditDialog(context, plan),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thu tiền cho thuê',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Số tiền / tháng',
                      value: _money(plan.monthlyAmount),
                    ),
                    _InfoRow(
                      label: 'Kỳ hiện tại',
                      value: DateFormat('MM/yyyy').format(plan.nextDueDate),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  isCollectedThisPeriod
                      ? Icons.check_circle
                      : isDue
                          ? Icons.schedule
                          : Icons.hourglass_bottom,
                  color: isCollectedThisPeriod
                      ? Colors.blue
                      : isDue
                          ? Colors.green
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isCollectedThisPeriod
                      ? 'Kỳ này đã thu rồi'
                      : isDue
                          ? 'Đã đến hạn thu tiền'
                          : 'Chưa đến hạn thu',
                  style: TextStyle(
                    color: isCollectedThisPeriod
                        ? Colors.blue
                        : isDue
                            ? Colors.green
                            : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (plan.canCollectToday)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: incomeProv.collecting
                      ? null
                      : () async {
                          final bankProv = context.read<BankAccountProvider>();

                          try {
                            await incomeProv.collect();
                            await bankProv.fetchAccounts();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã thu tiền thành công'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceFirst('Exception: ', '')),
                              ),
                            );
                          }
                        },
                  child: incomeProv.collecting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Thu tiền'),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// ==========================
// INFO ROW
// ==========================
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
