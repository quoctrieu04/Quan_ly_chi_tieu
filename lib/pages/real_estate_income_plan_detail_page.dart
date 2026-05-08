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

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isBeforeDue(DateTime dueDate) {
    return _dateOnly(DateTime.now()).isBefore(_dateOnly(dueDate));
  }

  bool _isOverdue(DateTime dueDate) {
    return _dateOnly(DateTime.now()).isAfter(_dateOnly(dueDate));
  }

  int _daysBetweenTodayAnd(DateTime dueDate) {
    return _dateOnly(dueDate).difference(_dateOnly(DateTime.now())).inDays;
  }

  // ==========================
  // EDIT DIALOG
  // ==========================
  void _openEditDialog(BuildContext context, dynamic plan) {
    final amountCtrl =
        TextEditingController(text: _money(plan.monthlyAmount));
    DateTime dueDate = plan.nextDueDate;

    amountCtrl.addListener(() {
      final text = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        final value = double.parse(text);
        final formatted = _money(value);
        if (amountCtrl.text != formatted) {
          amountCtrl.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                  trailing: const Icon(Icons.edit_calendar, color: Colors.blue),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setModalState(() {
                        dueDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (dueDate != plan.nextDueDate) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận đổi kỳ thu'),
                            content: const Text(
                              'Nếu bạn đẩy lùi kỳ thu khi chưa thu tiền, hệ thống sẽ bỏ qua tháng hiện tại và không ghi nhận doanh thu.\n\nBạn có chắc chắn muốn bỏ qua và đổi sang kỳ thu mới không?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Đồng ý đổi'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      }

                      final incomeProv =
                          context.read<RealEstateIncomePlanProvider>();
                      
                      final textVal = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

                      await incomeProv.updatePlan(
                        monthlyAmount: double.tryParse(textVal) ?? 0.0,
                        nextDueDate: dueDate,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        _showSuccessSnackBar('Đã cập nhật khoản thu');
                      }
                    },
                    child: const Text('Lưu thay đổi'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================
  // DELETE CONFIRM
  // ==========================
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa khoản thu'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa khoản thu này?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng Dialog

              final incomeProv = context.read<RealEstateIncomePlanProvider>();
              await incomeProv.deletePlan();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Đã xóa khoản thu thành công'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                // Thoát khỏi trang chi tiết khoản thu
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _accountDropdown(
    List<dynamic> accounts,
    int? selectedId,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: selectedId,
      decoration: const InputDecoration(labelText: 'Tài khoản nhận tiền'),
      items: accounts
          .where((account) => account.isDeleted != true)
          .map<DropdownMenuItem<int>>(
            (account) => DropdownMenuItem<int>(
              value: account.id as int,
              child: Text(
                account.bankname != null && account.bankname!.isNotEmpty
                    ? '${account.name} • ${account.bankname}'
                    : account.name,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  void _openCollectSheet(dynamic plan, {bool isEarly = false}) {
    final bankProv = context.read<BankAccountProvider>();
    final accounts = bankProv.items;
    
    int? receiveAccountId;
    int months = 1;
    final amountCtrl = TextEditingController(text: _money(plan.monthlyAmount));
    final notesCtrl = TextEditingController();
    
    amountCtrl.addListener(() {
      final text = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        final value = double.parse(text);
        final formatted = _money(value);
        if (amountCtrl.text != formatted) {
          amountCtrl.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    });

    final daysEarly = _daysBetweenTodayAnd(plan.nextDueDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final expectedTotal = plan.monthlyAmount * months;
          
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEarly ? 'Thu trước hạn' : 'Thu tiền',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEarly 
                      ? "Khoản thu này dự kiến đến hạn vào ${DateFormat('dd/MM/yyyy').format(plan.nextDueDate)}.${daysEarly > 0 ? ' Bạn đang thu sớm $daysEarly ngày.' : ''}"
                      : "Xác nhận thu tiền kỳ ${DateFormat('dd/MM/yyyy').format(plan.nextDueDate)}.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Text('Số tháng thu:', style: TextStyle(color: Colors.black54))),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: months > 1 ? () {
                              setModalState(() {
                                months--;
                                amountCtrl.text = _money(plan.monthlyAmount * months);
                              });
                            } : null,
                          ),
                          Text('$months', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setModalState(() {
                                months++;
                                amountCtrl.text = _money(plan.monthlyAmount * months);
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền thực thu (VND)',
                      helperText: 'Dự kiến: ${_money(expectedTotal)} VND',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _accountDropdown(
                    accounts,
                    receiveAccountId,
                    (value) => setModalState(() {
                      receiveAccountId = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú (Tùy chọn)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEarly 
                      ? 'App sẽ dời lịch thu lên $months tháng tính từ kỳ thu tiếp theo.'
                      : 'Đánh dấu đã thu xong $months kỳ và lùi lịch thu tiếp theo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: receiveAccountId == null ||
                            amountCtrl.text.isEmpty ||
                            context.read<RealEstateIncomePlanProvider>().collecting
                        ? null
                        : () async {
                            final text = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                            final actualAmount = double.tryParse(text) ?? 0.0;
                            
                            Navigator.pop(ctx);
                            final incomeProv = context.read<RealEstateIncomePlanProvider>();
                            final bankProv = context.read<BankAccountProvider>();
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              await incomeProv.collect(
                                receiveAccountId: receiveAccountId,
                                collectedAt: DateTime.now(),
                                early: isEarly,
                                months: months,
                                partialAmount: actualAmount,
                                notes: notesCtrl.text,
                              );
                              await bankProv.fetchAccounts();

                              if (!mounted) return;

                              final updatedPlan = incomeProv.plan!;
                              _showSuccessDialog(
                                isEarly ? 'Thu trước hạn thành công!' : 'Thu tiền thành công!',
                                actualAmount,
                                updatedPlan.nextDueDate,
                              );
                            } catch (e) {
                              if (!mounted) return;

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                ),
                              );
                            }
                          },
                    child: Text(isEarly ? 'Xác nhận thu trước' : 'Xác nhận thu tiền'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          backgroundColor: const Color(0xFF1F9D55),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showSuccessDialog(String title, double amount, DateTime newDueDate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số tiền đã thu', style: TextStyle(color: Colors.black54)),
                        Text('${_money(amount)} ₫', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1, thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kỳ thu tiếp theo', style: TextStyle(color: Colors.black54)),
                        Text(DateFormat('dd/MM/yyyy').format(newDueDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hoàn tất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEarlyCollectInfoSheet(dynamic plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Điều kiện thu trước hạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thu trước hạn dùng khi bạn đã nhận tiền trước ngày đến hạn theo hợp đồng.',
                style: TextStyle(height: 1.35),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khác với gửi tiết kiệm, khoản thu BĐS thường không bị giảm tiền. App chỉ cần lưu ngày đến hạn, ngày thu thực tế, tài khoản nhận tiền và trạng thái đã thu.',
                style: TextStyle(height: 1.35),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khi xác nhận, app gửi yêu cầu thu trước hạn để backend ghi nhận tiền về tài khoản và chuyển sang kỳ thu tiếp theo.',
                style: TextStyle(
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openCollectSheet(plan, isEarly: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Đã hiểu và Tiếp tục', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
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

    final isBeforeDue = _isBeforeDue(plan.nextDueDate);
    final isDue = _isDue(plan.nextDueDate);
    final isOverdue = _isOverdue(plan.nextDueDate);
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
                      value: DateFormat('dd/MM/yyyy').format(plan.nextDueDate),
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
                      : isOverdue
                          ? Icons.warning_amber_rounded
                          : isDue
                              ? Icons.schedule
                              : Icons.hourglass_bottom,
                  color: isCollectedThisPeriod
                      ? Colors.blue
                      : isOverdue
                          ? Colors.red
                          : isDue
                              ? Colors.green
                              : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isCollectedThisPeriod
                      ? 'Kỳ này đã thu rồi'
                      : isOverdue
                          ? 'Khoản thu đã quá hạn'
                          : isDue
                              ? 'Đã đến hạn thu tiền'
                              : 'Chưa đến hạn thu',
                  style: TextStyle(
                    color: isCollectedThisPeriod
                        ? Colors.blue
                        : isOverdue
                            ? Colors.red
                            : isDue
                                ? Colors.green
                                : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (!isCollectedThisPeriod && isBeforeDue)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _openEarlyCollectInfoSheet(plan),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Thu trước hạn'),
                ),
              )
            else if (!isCollectedThisPeriod && isDue)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: incomeProv.collecting
                      ? null
                      : () => _openCollectSheet(plan, isEarly: false),
                  child: incomeProv.collecting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isOverdue ? 'Thu tiền quá hạn' : 'Thu tiền'),
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
