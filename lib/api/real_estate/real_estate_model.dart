import 'real_estate_income_plan_model.dart';

class RealEstate {
  final int id;
  final String name;
  final String propertyType;
  final String? address;

  // ===== GIÁ MUA =====
  final double purchasePrice;
  final DateTime purchaseDate;

  // ===== CHI PHÍ =====
  final double totalCost;

  // ===== THU VÀO =====
  final double totalIncome;

  // ===== LÃI / LỖ =====
  final double profit;

  // ===== KẾ HOẠCH THU (MỚI) =====
  final List<RealEstateIncomePlan> incomePlans;

  // ===== TRẠNG THÁI =====
  final DateTime? soldAt;
  final String? note;

  bool get isSold => soldAt != null;

  RealEstate({
    required this.id,
    required this.name,
    required this.propertyType,
    required this.purchasePrice,
    required this.totalCost,
    required this.purchaseDate,
    required this.totalIncome,
    required this.profit,

    // 🔥 MỚI
    this.incomePlans = const [],

    this.address,
    this.soldAt,
    this.note,
  });

  factory RealEstate.fromJson(Map<String, dynamic> json) {
    return RealEstate(
      id: json['id'],
      name: json['name'],
      propertyType: json['property_type'],
      address: json['address'],

      purchasePrice:
          double.parse(json['purchase_price'].toString()),
      totalCost:
          double.parse((json['total_cost'] ?? 0).toString()),
      purchaseDate:
          DateTime.parse(json['purchase_date']),

      totalIncome:
          double.parse((json['total_income'] ?? 0).toString()),
      profit:
          double.parse((json['profit'] ?? 0).toString()),

      // 🔥 PARSE KẾ HOẠCH THU
      incomePlans: (json['income_plans'] as List?)
              ?.map((e) =>
                  RealEstateIncomePlan.fromJson(e))
              .toList() ??
          [],

      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'])
          : null,

      note: json['note'],
    );
  }
}
