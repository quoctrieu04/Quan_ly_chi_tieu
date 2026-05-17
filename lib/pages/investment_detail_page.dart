import 'package:chitieu/api/bankaccount/bank_account_model.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/widgets/investment/bank/bank_renew_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/utils/error_handler.dart';
import 'package:chitieu/utils/safe_ui.dart';

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

    final termProfit = investment.profitLoss;
    final maturityDate =
        _maturityDate(investment.startDate, investment.termMonths);

    final bool isClosed = investment.closedAt != null;
    final bool isActiveBank = investment.type == 'bank' &&
        !isClosed &&
        investment.totalInvested > 0 &&
        maturityDate != null;
    final bool isBeforeMaturity =
        isActiveBank && DateTime.now().isBefore(_dateOnly(maturityDate));
    final bool canWithdraw =
        isActiveBank && !DateTime.now().isBefore(_dateOnly(maturityDate));
    final bool canWithdrawInterestAndRenew = canWithdraw;
    final earlyProfit =
        isBeforeMaturity ? _earlyWithdrawInterest() : termProfit;
    final displayProfit = investment.type == 'bank' ? earlyProfit : termProfit;
    final totalAmount = investment.totalInvested + displayProfit;

    int withdrawableMonths = 0;
    if (isActiveBank) {
      final lastDate = investment.lastInterestDate ?? investment.startDate;
      if (lastDate != null) {
        final now = DateTime.now();
        int monthsPassed = 0;
        DateTime temp = DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
        while (temp.isBefore(now) || temp.isAtSameMomentAs(now)) {
          monthsPassed++;
          temp = DateTime(temp.year, temp.month + 1, temp.day);
        }
        withdrawableMonths = monthsPassed;
      }
    }

    String moneyText(num value) => moneyFmt.format(value).replaceAll(',', '.');

    final interestRateText =
        '${investment.interestRate?.toStringAsFixed(2) ?? '0'}% / năm';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        titleSpacing: 0,
        title: Text(
          'Chi tiết ${investment.name}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'TỔNG GIÁ TRỊ',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
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
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'VND',
                        style: TextStyle(
                          color: cs.onSurface,
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
              color: isDark ? cs.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _detailRow(
                  'Gốc đầu tư',
                  '${moneyText(investment.totalInvested)} VND',
                  cs,
                ),
                _detailDivider(),
                _detailRow(
                  isBeforeMaturity ? 'Lãi tạm tính trước hạn' : 'Lãi hiện tại',
                  '${moneyText(displayProfit)} VND',
                  cs,
                  valueColor:
                      displayProfit >= 0 ? const Color(0xFF55B866) : Colors.red,
                  trailing: investment.type == 'bank'
                      ? _rateBadge(isBeforeMaturity ? '0.1% / năm' : interestRateText)
                      : null,
                ),
                _detailDivider(),
                _detailRow(
                  'Ngày bắt đầu',
                  investment.startDate != null
                      ? dateFmt.format(investment.startDate!)
                      : '—',
                  cs,
                ),
                if (investment.type == 'bank') ...[
                  _detailDivider(),
                  _detailRow(
                    'Ngày đáo hạn',
                    maturityDate != null ? dateFmt.format(maturityDate) : '—',
                    cs,
                    valueColor: canWithdraw
                        ? const Color(0xFF55B866)
                        : (isDark ? cs.onSurface.withOpacity(0.6) : const Color(0xFF68727C)),
                    leadingValueIcon: Icons.event_available_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(
        cs: cs,
        isDark: isDark,
        canWithdraw: canWithdraw,
        canWithdrawInterestAndRenew: canWithdrawInterestAndRenew,
        isBeforeMaturity: isBeforeMaturity,
        withdrawableMonths: withdrawableMonths,
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    ColorScheme cs, {
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
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
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
                      color: valueColor ?? cs.onSurface,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? cs.onSurface,
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
    required ColorScheme cs,
    required bool isDark,
    required bool canWithdraw,
    required bool canWithdrawInterestAndRenew,
    required bool isBeforeMaturity,
    required int withdrawableMonths,
  }) {
    final canUsePrimaryActions = canWithdraw && !_busy;
    final canUseInterestRenew = canWithdrawInterestAndRenew && !_busy;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: isBeforeMaturity
            ? Row(
                children: [
                  Expanded(
                    child: _bottomActionButton(
                      cs: cs,
                      isDark: isDark,
                      icon: Icons.warning_amber_rounded,
                      label: 'RÚT TRƯỚC HẠN',
                      onPressed: _busy ? null : _openEarlyWithdrawInfoSheet,
                      outlined: true,
                    ),
                  ),
                  if (withdrawableMonths >= 1 && investment.interestPaymentMethod == 'Trả lãi hàng tháng') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _bottomActionButton(
                        cs: cs,
                        isDark: isDark,
                        icon: Icons.payments_outlined,
                        label: 'RÚT LÃI ĐỊNH KỲ\n($withdrawableMonths tháng)',
                        onPressed: _busy ? null : () => _openMonthlyWithdrawInfoSheet(withdrawableMonths),
                        backgroundColor: const Color(0xFF7CE5DF),
                        foregroundColor: const Color(0xFF00646D),
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _bottomActionButton(
                      cs: cs,
                      isDark: isDark,
                      icon: Icons.logout_rounded,
                      label: 'RÚT TOÀN BỘ',
                      onPressed:
                          canUsePrimaryActions ? _openWithdrawSheet : null,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bottomActionButton(
                      cs: cs,
                      isDark: isDark,
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
                      cs: cs,
                      isDark: isDark,
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

  void _openMonthlyWithdrawInfoSheet(int months) {
    final accounts = context.read<BankAccountProvider>().items;
    int? receiveAccountId;
    String? errorMsg;

    final double interestAmount = investment.totalInvested * (investment.interestRate! / 100) * (months / 12);
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    final formattedInterest = moneyFmt.format(interestAmount.round()).replaceAll(',', '.');

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
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Rút lãi định kỳ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bạn đang rút lãi của $months tháng đã gửi. Hệ thống sẽ cộng phần tiền lãi này vào tài khoản của bạn.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số tiền lãi thực nhận:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF68727C)),
                        ),
                        Text(
                          '$formattedInterest VND',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1F9D55)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _accountDropdown(
                    accounts,
                    receiveAccountId,
                    (value) => setModalState(() {
                      receiveAccountId = value;
                    }),
                  ),
                  const SizedBox(height: 14),
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
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
                                    withdrawType: WithdrawType.monthlyInterest,
                                  );

                              if (!mounted) return;
                              showAppSnackBar(context, 'Rút lãi định kỳ thành công', icon: Icons.check_circle_rounded);
                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;
                              showAppSnackBar(context, getFriendlyError(e), isError: true);
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004A55),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Xác nhận Rút lãi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bottomActionButton({
    required ColorScheme cs,
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool outlined = false,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    backgroundColor ??= isDark ? cs.surfaceContainerHigh : Colors.white;
    foregroundColor ??= isDark ? cs.onSurface : const Color(0xFF004A55);

    final borderRadius = BorderRadius.circular(10);
    final disabledBackground =
        outlined ? Colors.transparent : (isDark ? cs.surfaceContainer : const Color(0xFFE0E5E8));
    final disabledForeground = isDark ? cs.onSurface.withOpacity(0.4) : const Color(0xFF9AA4AC);

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
                        ? (isDark ? cs.outlineVariant.withOpacity(0.3) : const Color(0xFFD4DADE))
                        : (isDark ? cs.outlineVariant : const Color(0xFF9AA4AC)),
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
    showAppSnackBar(context, message, icon: Icons.check_circle_rounded);
  }

  Widget _accountDropdown(
    List<BankAccount> accounts,
    int? selectedId,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: 'Tài khoản nhận tiền',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
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

  double _earlyWithdrawInterest() {
    const demandRate = 0.1;
    if (investment.startDate == null) return 0;

    final start = _dateOnly(investment.startDate!);
    final today = _dateOnly(DateTime.now());
    final holdingDays = today.difference(start).inDays.clamp(0, 36500);
    return investment.totalInvested * (demandRate / 100) * (holdingDays / 365);
  }

  void _openEarlyWithdrawInfoSheet() {
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
                'Điều kiện rút trước hạn',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Khoản gửi chưa đến ngày đáo hạn. Nếu rút bây giờ, lãi kỳ hạn sẽ không được áp dụng như khi rút đúng hạn.',
                style: TextStyle(height: 1.35),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lãi dự kiến sẽ được tính lại theo lãi suất không kỳ hạn. Phần lãi kỳ hạn đang hiển thị chỉ là số tham khảo nếu giữ đến ngày đáo hạn.',
                style: TextStyle(height: 1.35),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openEarlyWithdrawSheet();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004A55),
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

  void _openEarlyWithdrawSheet() {
    final accounts = context.read<BankAccountProvider>().items;
    final moneyFmt = NumberFormat('#,###', 'vi_VN');
    final maturityDate = _maturityDate(investment.startDate, investment.termMonths);
    
    int? receiveAccountId;
    bool isPartialWithdraw = false;
    
    final partialAmountCtrl = TextEditingController();
    final overrideAmountCtrl = TextEditingController();
    final demandRateCtrl = TextEditingController(text: '0.1');

    double calculateEarlyInterestFor(double amount, double rate) {
      if (investment.startDate == null) return 0;
      final start = _dateOnly(investment.startDate!);
      final today = _dateOnly(DateTime.now());
      final holdingDays = today.difference(start).inDays.clamp(0, 36500);
      return amount * (rate / 100) * (holdingDays / 365);
    }

    final defaultEarlyInterest = calculateEarlyInterestFor(investment.totalInvested, 0.1);
    final defaultTotal = investment.totalInvested + defaultEarlyInterest;
    
    String moneyText(num value) => moneyFmt.format(value).replaceAll(',', '.');
    
    overrideAmountCtrl.text = moneyText(defaultTotal.round());

    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Rút trước hạn',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    maturityDate == null
                        ? 'Khoản gửi này chưa đủ thông tin ngày đáo hạn.'
                        : 'Khoản gửi chưa đến ngày đáo hạn ${DateFormat('dd/MM/yyyy').format(maturityDate)}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF68727C)),
                  ),
                  const SizedBox(height: 14),
                  
                  // Lựa chọn Hình thức rút
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Rút toàn bộ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          contentPadding: EdgeInsets.zero,
                          value: false,
                          groupValue: isPartialWithdraw,
                          onChanged: (val) {
                            setModalState(() {
                              isPartialWithdraw = val!;
                              final rate = double.tryParse(demandRateCtrl.text.replaceAll(',', '.')) ?? 0.1;
                              final interest = calculateEarlyInterestFor(investment.totalInvested, rate);
                              overrideAmountCtrl.text = moneyText((investment.totalInvested + interest).round());
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Rút 1 phần', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          contentPadding: EdgeInsets.zero,
                          value: true,
                          groupValue: isPartialWithdraw,
                          onChanged: (val) {
                            setModalState(() {
                              isPartialWithdraw = val!;
                              partialAmountCtrl.clear();
                              overrideAmountCtrl.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  if (isPartialWithdraw) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: partialAmountCtrl,
                      decoration: InputDecoration(
                        labelText: 'Số tiền gốc muốn rút (VND)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setModalState(() => errorMsg = null);
                        final rawStr = val.replaceAll(RegExp(r'[^0-9]'), '');
                        if (rawStr.isEmpty) {
                          partialAmountCtrl.clear();
                          overrideAmountCtrl.clear();
                          return;
                        }

                        final amount = double.tryParse(rawStr) ?? 0;
                        final formatted = moneyText(amount);

                        partialAmountCtrl.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );

                        final rate = double.tryParse(demandRateCtrl.text.replaceAll(',', '.')) ?? 0.1;
                        final interest = calculateEarlyInterestFor(amount, rate);
                        final totalFormatted = moneyText((amount + interest).round());
                        overrideAmountCtrl.value = TextEditingValue(
                          text: totalFormatted,
                          selection: TextSelection.collapsed(offset: totalFormatted.length),
                        );
                      },
                    ),
                  ] else ...[
                    TextFormField(
                      initialValue: moneyText(investment.totalInvested),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Gốc nhận lại (VND)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: demandRateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Lãi suất không kỳ hạn (%/năm)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      suffixText: '%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      final rateStr = val.replaceAll(',', '.');
                      final rate = double.tryParse(rateStr) ?? 0;
                      
                      final amountRaw = isPartialWithdraw 
                          ? partialAmountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')
                          : investment.totalInvested.toString();
                          
                      final amount = double.tryParse(amountRaw) ?? 0;
                      
                      if (amount > 0) {
                        final interest = calculateEarlyInterestFor(amount, rate);
                        final totalFormatted = moneyText((amount + interest).round());
                        overrideAmountCtrl.value = TextEditingValue(
                          text: totalFormatted,
                          selection: TextSelection.collapsed(offset: totalFormatted.length),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: overrideAmountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tổng tiền thực nhận (Ghi đè)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      helperText: 'Nhập chính xác số tiền NH trả để khớp số dư.',
                      helperMaxLines: 2,
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF55B866)),
                    onChanged: (val) {
                      final rawStr = val.replaceAll(RegExp(r'[^0-9]'), '');
                      if (rawStr.isEmpty) {
                        overrideAmountCtrl.clear();
                        return;
                      }
                      final amount = double.tryParse(rawStr) ?? 0;
                      final formatted = moneyText(amount);
                      
                      overrideAmountCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _accountDropdown(
                    accounts,
                    receiveAccountId,
                    (value) => setModalState(() {
                      receiveAccountId = value;
                    }),
                  ),
                  const SizedBox(height: 14),
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: receiveAccountId == null || _busy
                        ? null
                        : () async {
                            final rawOverride = overrideAmountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                            final rawPartial = partialAmountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

                            final overrideAmount = double.tryParse(rawOverride) ?? 0;
                            final withdrawAmount = isPartialWithdraw 
                                ? (double.tryParse(rawPartial) ?? 0)
                                : investment.totalInvested;

                            if (overrideAmount <= 0 || withdrawAmount <= 0) {
                                setModalState(() => errorMsg = 'Vui lòng nhập số tiền lớn hơn 0');
                                return;
                            }
                            
                            if (withdrawAmount > investment.totalInvested) {
                                setModalState(() => errorMsg = 'Số gốc muốn rút không được vượt quá số dư (${moneyText(investment.totalInvested)} VND)');
                                return;
                            }

                            Navigator.pop(ctx);
                            setState(() => _busy = true);

                            try {
                              await context
                                  .read<InvestmentProvider>()
                                  .withdrawBank(
                                    investment.id!,
                                    receiveAccountId!,
                                    withdrawType: isPartialWithdraw ? WithdrawType.earlyPartial : WithdrawType.earlyAll,
                                    amount: withdrawAmount,
                                    overrideReceivedAmount: overrideAmount,
                                  );

                              if (!mounted) return;
                              showAppSnackBar(context, 'Rút trước hạn thành công', icon: Icons.check_circle_rounded);
                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;
                              showAppSnackBar(context, getFriendlyError(e), isError: true);
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                    child: const Text('Xác nhận rút trước hạn'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _earlyWithdrawPreviewRow(
    String label,
    String value, {
    Color? valueColor,
    bool isStrong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF68727C),
                fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF1F2933),
              fontWeight: isStrong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
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

                              showAppSnackBar(context, 'Rút tiền thành công', icon: Icons.check_circle_rounded);

                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;

                              showAppSnackBar(context, getFriendlyError(e), isError: true);
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

                              showAppSnackBar(context, 'Rút lãi và gia hạn gốc thành công', icon: Icons.check_circle_rounded);

                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;

                              showAppSnackBar(context, getFriendlyError(e), isError: true);
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
      if (!mounted) return;
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
