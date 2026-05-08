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
  }

  String _money(num v) {
    return NumberFormat('#,###', 'vi').format(v);
  }

  @override
  Widget build(BuildContext context) {
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
            value: _money(realEstate.totalIncome ?? 0),
            valueColor: Colors.green,
          ),
          _InfoRow(
            label: 'Lãi / Lỗ',
            value: _money(realEstate.profit ?? 0),
            valueColor:
                (realEstate.profit ?? 0) >= 0 ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 24),

          // ===== ACTION =====
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Thêm chi phí phát sinh'),
            onPressed: () async {
              final created = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddRealEstateCostSheet(
                  realEstateId: realEstate.id,
                ),
              );

              // 🔥 CẬP NHẬT LẠI OBJECT SAU KHI LƯU
              if (created == true && context.mounted) {
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
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.trending_up),
            label: const Text('Thêm thu nhập'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            onPressed: () async {
              final incomeProv = context.read<RealEstateIncomePlanProvider>();

              // 🔥 BẮT BUỘC LOAD PLAN TRƯỚC
              await incomeProv.load(realEstate.id);

              if (!context.mounted) return;

              // =========================
              // CHƯA CÓ KHOẢN THU
              // =========================
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
                }

                return;
              }

              // =========================
              // ĐÃ CÓ KHOẢN THU
              // =========================
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RealEstateIncomePlanDetailPage(
                    realEstate: realEstate,
                  ),
                ),
              );

              // quay lại thì reload lại plan
              await incomeProv.load(realEstate.id);
            },
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            icon: const Icon(Icons.sell),
            label: const Text('Đánh dấu đã bán'),
            onPressed: () async {
              // đảm bảo có danh sách tài khoản để chọn
              final bankProv = context.read<BankAccountProvider>();
              if (bankProv.items.isEmpty && !bankProv.loading) {
                await bankProv.fetchAccounts();
              }
              if (!context.mounted) return;

              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => SellRealEstateSheet(
                  realEstateId: realEstate.id,
                  realEstateName: realEstate.name ?? 'Bất động sản',
                ),
              );

              if (result == null || !context.mounted) return;

              try {
                final prov = context.read<RealEstateProvider>();
                final profit = await prov.sell(
                  realEstateId: realEstate.id,
                  sellPrice: (result['sell_price'] as double),
                  sellDate: (result['sell_date'] as DateTime),
                  accountTargetId: (result['account_target_id'] as int),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Đã bán. Lãi/Lỗ: ${profit.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );

                // index() chỉ show whereNull(sold_at) -> quay lại list
                Navigator.pop(context, true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
