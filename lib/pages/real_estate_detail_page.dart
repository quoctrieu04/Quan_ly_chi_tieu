import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/widgets/investment/real_estate/add_real_estate_cost_sheet.dart';
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
            label: 'Lãi / Lỗ',
            value: '0',
            valueColor: Colors.grey,
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

          const SizedBox(height: 10),

          OutlinedButton.icon(
            icon: const Icon(Icons.sell),
            label: const Text('Đánh dấu đã bán'),
            onPressed: () {
              // TODO: nghiệp vụ bán BĐS
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
