import 'package:chitieu/api/bankaccount/bank_account_model.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/widgets/investment/bank/bank_renew_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InvestmentDetailPage extends StatefulWidget {
  final Investment investment;

  const InvestmentDetailPage({
    super.key,
    required this.investment,
  });

  @override
  State<InvestmentDetailPage> createState() => _InvestmentDetailPageState();
}

class _InvestmentDetailPageState extends State<InvestmentDetailPage> {
  late Investment investment;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    investment = widget.investment;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankAccountProvider>().fetchAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');

    final profit = investment.profitLoss;
    final totalAmount = investment.totalInvested + profit;
    final maturityDate =
        _maturityDate(investment.startDate, investment.termMonths);

    final bool isClosed = investment.closedAt != null;
    final bool canWithdraw = investment.type == 'bank' &&
        !isClosed &&
        investment.totalInvested > 0 &&
        maturityDate != null &&
        !DateTime.now().isBefore(_dateOnly(maturityDate));
    final bool canWithdrawInterestAndRenew = canWithdraw;

    String moneyText(num value) => moneyFmt.format(value).replaceAll(',', '.');

    final contractCode = investment.id != null
        ? 'HD-${investment.id!.toString().padLeft(6, '0')}'
        : investment.name;
    final interestRateText =
        '${investment.interestRate?.toStringAsFixed(2) ?? '0'}% / năm';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: const Color(0xFF00323D),
        titleSpacing: 0,
        title: Text(
          'Chi tiết ${investment.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
        children: [
          Center(
            child: Column(
              children: [
                const Text(
                  'TỔNG GIÁ TRỊ',
                  style: TextStyle(
                    color: Color(0xFF68727C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      moneyText(totalAmount),
                      style: const TextStyle(
                        color: Color(0xFF00323D),
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'VND',
                        style: TextStyle(
                          color: Color(0xFF00323D),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _detailRow('Mã hợp đồng', contractCode),
                _detailDivider(),
                _detailRow(
                  'Gốc đầu tư',
                  '${moneyText(investment.totalInvested)} VND',
                ),
                _detailDivider(),
                _detailRow(
                  'Lãi hiện tại',
                  '${moneyText(profit)} VND',
                  valueColor:
                      profit >= 0 ? const Color(0xFF55B866) : Colors.red,
                  trailing: investment.type == 'bank'
                      ? _rateBadge(interestRateText)
                      : null,
                ),
                _detailDivider(),
                _detailRow(
                  'Ngày bắt đầu',
                  investment.startDate != null
                      ? dateFmt.format(investment.startDate!)
                      : '—',
                ),
                if (investment.type == 'bank') ...[
                  _detailDivider(),
                  _detailRow(
                    'Ngày đáo hạn',
                    maturityDate != null ? dateFmt.format(maturityDate) : '—',
                    valueColor: canWithdraw
                        ? const Color(0xFF55B866)
                        : const Color(0xFF68727C),
                    leadingValueIcon: Icons.event_available_rounded,
                  ),
                ],
                _detailDivider(),
                _detailRow(
                  'Hình thức',
                  isClosed ? 'Đã tất toán' : 'Gia hạn tự động',
                  valueColor: isClosed ? Colors.red : null,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(
        canWithdraw: canWithdraw,
        canWithdrawInterestAndRenew: canWithdrawInterestAndRenew,
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    Widget? trailing,
    IconData? leadingValueIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        crossAxisAlignment: trailing == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF68727C),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingValueIcon != null) ...[
                    Icon(
                      leadingValueIcon,
                      size: 16,
                      color: valueColor ?? const Color(0xFF1F2933),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? const Color(0xFF1F2933),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(height: 6),
                trailing,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, color: Color(0xFFE7EBEF)),
    );
  }

  Widget _rateBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFA8F0B2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF167A31),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _actionBar({
    required bool canWithdraw,
    required bool canWithdrawInterestAndRenew,
  }) {
    final canUsePrimaryActions = canWithdraw && !_busy;
    final canUseInterestRenew = canWithdrawInterestAndRenew && !_busy;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _bottomActionButton(
                icon: Icons.logout_rounded,
                label: 'RÚT TOÀN BỘ',
                onPressed: canUsePrimaryActions ? _openWithdrawSheet : null,
                outlined: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _bottomActionButton(
                icon: Icons.account_balance_wallet_outlined,
                label: 'RÚT LÃI &\nGIA HẠN GỐC',
                onPressed: canUseInterestRenew
                    ? _openWithdrawInterestAndRenewSheet
                    : null,
                backgroundColor: const Color(0xFF7CE5DF),
                foregroundColor: const Color(0xFF00646D),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _bottomActionButton(
                icon: Icons.refresh_rounded,
                label: 'GIA HẠN',
                onPressed: canUsePrimaryActions ? _openRenewDialog : null,
                backgroundColor: const Color(0xFF004A55),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool outlined = false,
    Color backgroundColor = Colors.white,
    Color foregroundColor = const Color(0xFF004A55),
  }) {
    final borderRadius = BorderRadius.circular(10);
    final disabledBackground =
        outlined ? Colors.white : const Color(0xFFE0E5E8);
    final disabledForeground = const Color(0xFF9AA4AC);

    return SizedBox(
      height: 57,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabledForeground,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: outlined
                ? BorderSide(
                    color: onPressed == null
                        ? const Color(0xFFD4DADE)
                        : const Color(0xFF9AA4AC),
                  )
                : BorderSide.none,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
                  color: Colors.white.withOpacity(0.18),
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

  Widget _accountDropdown(
    List<BankAccount> accounts,
    int? selectedId,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      value: selectedId,
      decoration: const InputDecoration(labelText: 'Tài khoản nhận tiền'),
      items: accounts
          .where((account) => !account.isDeleted)
          .map(
            (account) => DropdownMenuItem<int>(
              value: account.id,
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

  void _openWithdrawSheet() {
    final accounts = context.read<BankAccountProvider>().items;
    int? receiveAccountId;

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
              children: [
                const Text(
                  'Rút toàn bộ tiền gửi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _accountDropdown(
                  accounts,
                  receiveAccountId,
                  (value) => setModalState(() {
                    receiveAccountId = value;
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: receiveAccountId == null || _busy
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _busy = true);

                            try {
                              await context
                                  .read<InvestmentProvider>()
                                  .withdrawBank(
                                    investment.id!,
                                    receiveAccountId!,
                                    withdrawType: WithdrawType.all,
                                  );

                              if (!mounted) return;

                              _showSuccessSnackBar('Rút tiền thành công');

                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _busy = false);
                              }
                            }
                          },
                    child: const Text('Xác nhận rút toàn bộ'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openWithdrawInterestAndRenewSheet() {
    final accounts = context.read<BankAccountProvider>().items;
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    int? receiveAccountId;

    String moneyText(num value) => moneyFmt.format(value).replaceAll(',', '.');

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
              children: [
                const Text(
                  'Rút lãi và gia hạn gốc',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lãi chuyển về tài khoản'),
                  subtitle: Text(
                    '${moneyText(investment.profitLoss)} VND',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Số gốc tiếp tục gia hạn'),
                  subtitle: Text(
                    '${moneyText(investment.totalInvested)} VND',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (investment.termMonths != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kỳ hạn mới'),
                    subtitle: Text('${investment.termMonths} tháng'),
                  ),
                _accountDropdown(
                  accounts,
                  receiveAccountId,
                  (value) => setModalState(() {
                    receiveAccountId = value;
                  }),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lãi hiện tại sẽ được rút về tài khoản nhận tiền, '
                  'phần gốc sẽ được gia hạn sang kỳ mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: receiveAccountId == null || _busy
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _busy = true);

                            try {
                              await context
                                  .read<InvestmentProvider>()
                                  .withdrawBank(
                                    investment.id!,
                                    receiveAccountId!,
                                    withdrawType: WithdrawType.interestAndRenew,
                                  );

                              if (!mounted) return;

                              _showSuccessSnackBar(
                                'Rút lãi và gia hạn gốc thành công',
                              );

                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _busy = false);
                              }
                            }
                          },
                    child: const Text('Xác nhận rút lãi và gia hạn gốc'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openRenewDialog() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BankRenewForm(
        baseInvestment: investment,
      ),
    );

    if (created == true && mounted) {
      await context.read<InvestmentProvider>().fetch();
      Navigator.pop(context, true);
    }
  }

  DateTime? _maturityDate(DateTime? start, int? termMonths) {
    if (start == null || termMonths == null) return null;
    return DateTime(start.year, start.month + termMonths, start.day);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
