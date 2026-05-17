import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_income_plan_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/pages/real_estate_income_plan_detail_page.dart';
import 'package:chitieu/widgets/investment/real_estate/add_real_estate_cost_sheet.dart';
import 'package:chitieu/widgets/investment/real_estate/add_real_estate_income_sheet.dart';
import 'package:chitieu/widgets/investment/real_estate/sell_real_estate_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/utils/safe_ui.dart';

class RealEstateDetailPage extends StatefulWidget {
  final dynamic item;

  const RealEstateDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<RealEstateDetailPage> createState() => _RealEstateDetailPageState();
}

class _RealEstateDetailPageState extends State<RealEstateDetailPage> {
  late dynamic realEstate;

  @override
  void initState() {
    super.initState();
    realEstate = widget.item;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RealEstateIncomePlanProvider>().load(realEstate.id);
      }
    });
  }

  String _money(num v) {
    return NumberFormat('#,###', 'vi').format(v);
  }

  Future<void> _addCost() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddRealEstateCostSheet(
        realEstateId: realEstate.id,
      ),
    );

    if (created == true && mounted) {
      final prov = context.read<RealEstateProvider>();
      await prov.fetch();

      final updated = prov.items.firstWhere(
        (e) => e.id == realEstate.id,
        orElse: () => realEstate,
      );

      setState(() {
        realEstate = updated;
      });
    }
  }

  Future<void> _addIncome() async {
    final incomeProv = context.read<RealEstateIncomePlanProvider>();

    await incomeProv.load(realEstate.id);
    if (!mounted) return;

    if (incomeProv.plan == null) {
      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddRealEstateIncomePlanSheet(
          realEstateId: realEstate.id,
        ),
      );

      if (created == true) {
        await incomeProv.load(realEstate.id);
        
        // Cập nhật lại danh sách chính để hiện badge
        if (mounted) {
          final prov = context.read<RealEstateProvider>();
          await prov.fetch();
          final updated = prov.items.firstWhere(
            (e) => e.id == realEstate.id,
            orElse: () => realEstate,
          );
          setState(() {
            realEstate = updated;
          });
        }
      }

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RealEstateIncomePlanDetailPage(
          realEstate: realEstate,
        ),
      ),
    );

    if (!mounted) return;
    await incomeProv.load(realEstate.id);

    final prov = context.read<RealEstateProvider>();
    await prov.fetch();
    final updated = prov.items.firstWhere(
      (e) => e.id == realEstate.id,
      orElse: () => realEstate,
    );
    setState(() {
      realEstate = updated;
    });
  }

  Future<void> _sellRealEstate() async {
    final bankProv = context.read<BankAccountProvider>();
    if (bankProv.items.isEmpty && !bankProv.loading) {
      await bankProv.fetchAccounts();
    }
    
    final incomeProv = context.read<RealEstateIncomePlanProvider>();
    if (incomeProv.plan == null || incomeProv.plan!.realEstateId != realEstate.id) {
      await incomeProv.load(realEstate.id);
    }
    
    if (!mounted) return;

    if (incomeProv.plan != null && incomeProv.plan!.canCollectToday) {
      showAppSnackBar(
        context,
        'Vui lòng thu tiền hoặc xóa khoản thu nhập định kỳ đang quá hạn trước khi bán!',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SellRealEstateSheet(
        realEstateId: realEstate.id,
        realEstateName: realEstate.name ?? 'Bất động sản',
      ),
    );

    if (result == null || !mounted) return;

    final sellPrice = result['sell_price'] as double;
    final sellDate = result['sell_date'] as DateTime;
    final accountTargetId = result['account_target_id'] as int;

    _showSellConfirmDialog(sellPrice, sellDate, accountTargetId);
  }

  Future<void> _executeSell(double sellPrice, DateTime sellDate, int accountTargetId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final prov = context.read<RealEstateProvider>();
      await prov.sell(
        realEstateId: realEstate.id,
        sellPrice: sellPrice,
        sellDate: sellDate,
        accountTargetId: accountTargetId,
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading
      Navigator.pop(context, true); // close detail page

      showAppSnackBar(
        context,
        'Đã ghi nhận bán BĐS thành công!',
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      showAppSnackBar(context, e.toString(), isError: true);
    }
  }

  double _getActualTotalIncome() {
    double base = (realEstate.totalIncome ?? 0).toDouble();
    final planProv = context.read<RealEstateIncomePlanProvider>();
    if (planProv.plan != null && planProv.plan!.realEstateId == realEstate.id) {
      base += planProv.plan!.totalCollected;
    }
    return base;
  }

  void _showSellConfirmDialog(double sellPrice, DateTime sellDate, int accountTargetId) {
    final purchasePrice = (realEstate.purchasePrice ?? 0).toDouble();
    final totalCost = (realEstate.totalCost ?? purchasePrice).toDouble();
    final totalIncome = _getActualTotalIncome();
    final sellProfit = sellPrice - totalCost;
    final finalProfit = sellProfit + totalIncome;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.blue, size: 56),
              ),
              const SizedBox(height: 20),
              Text(
                'Xác nhận bán BĐS',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHigh : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _DialogRow(
                        label: 'Ngày mua',
                        value: DateFormat('dd/MM/yyyy')
                            .format(realEstate.purchaseDate)),
                    const SizedBox(height: 8),
                    _DialogRow(
                        label: 'Giá mua ban đầu',
                        value: '${_money(purchasePrice)} ₫'),
                    const SizedBox(height: 8),
                    _DialogRow(
                        label: 'Tổng chi phí',
                        value: '${_money(totalCost)} ₫'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1, thickness: 1),
                    ),
                    _DialogRow(
                        label: 'Giá bán',
                        value: '${_money(sellPrice)} ₫',
                        valueColor: Colors.blue),
                    const SizedBox(height: 8),
                    _DialogRow(
                        label: sellProfit >= 0 ? 'Lãi vốn' : 'Lỗ vốn',
                        value: '${_money(sellProfit.abs())} ₫',
                        valueColor: sellProfit >= 0 ? Colors.green : Colors.red),
                    const SizedBox(height: 8),
                    _DialogRow(
                        label: 'Thu nhập cho thuê',
                        value: '${_money(totalIncome)} ₫',
                        valueColor: totalIncome > 0 ? Colors.green : null),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1, thickness: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            finalProfit >= 0 ? 'TỔNG LỢI NHUẬN' : 'TỔNG LỖ VỐN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_money(finalProfit.abs())} ₫',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: finalProfit >= 0 ? Colors.green : Colors.red,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Hủy',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _executeSell(sellPrice, sellDate, accountTargetId);
                      },
                      child: const Text('Xác nhận',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProv = context.watch<RealEstateIncomePlanProvider>();
    final showIncomeBadge = planProv.plan != null &&
        planProv.plan!.realEstateId == realEstate.id &&
        planProv.plan!.canCollectToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bất động sản'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: chỉnh sửa BĐS
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== HEADER =====
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: Colors.orange,
                ),
              ),
              title: Text(
                realEstate.name ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${realEstate.propertyType} • ${realEstate.address}',
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ===== THÔNG TIN =====
          _InfoRow(
            label: 'Giá mua',
            value: _money(realEstate.purchasePrice ?? 0),
          ),
          _InfoRow(
            label: 'Tổng chi phí',
            value: _money(
              realEstate.totalCost ?? realEstate.purchasePrice ?? 0,
            ),
          ),
          _InfoRow(
            label: 'Ngày mua',
            value: DateFormat('dd/MM/yyyy').format(realEstate.purchaseDate),
          ),

          const Divider(height: 32),

          // ===== HIỆU QUẢ =====
          _InfoRow(
            label: 'Giá trị hiện tại',
            value: _money(realEstate.totalCost ?? 0),
            valueColor: Colors.green,
          ),
          _InfoRow(
            label: 'Tổng thu',
            value: _money(_getActualTotalIncome()),
            valueColor: Colors.green,
          ),
          _InfoRow(
            label: 'Lãi / Lỗ',
            value: _money((realEstate.profit ?? 0) + (_getActualTotalIncome() - (realEstate.totalIncome ?? 0))),
            valueColor:
                (realEstate.profit ?? 0) >= 0 ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 24),

          // ===== ACTION =====
          Row(
            children: [
              Expanded(
                child: _DetailActionButton(
                  icon: Icons.add_rounded,
                  label: 'Chi phí',
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _addCost,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailActionButton(
                  icon: Icons.trending_up_rounded,
                  label: 'Thu nhập',
                  color: Colors.green.shade600,
                  onPressed: _addIncome,
                  showBadge: showIncomeBadge,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailActionButton(
                  icon: Icons.sell_rounded,
                  label: 'Bán',
                  color: Colors.blueGrey,
                  filled: false,
                  onPressed: _sellRealEstate,
                ),
              ),
            ],
          ),
        ],
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
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = true,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool filled;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : color;

    Widget btn = SizedBox(
      width: double.infinity,
      height: 44,
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: foreground,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: color.withOpacity(.35)),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );

    if (showBadge) {
      return Badge(
        label: const Text('1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        offset: const Offset(4, -4),
        child: btn,
      );
    }

    return btn;
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DialogRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? cs.onSurface),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
