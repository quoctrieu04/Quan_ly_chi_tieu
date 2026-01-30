class RealEstate {
  final int id;
  final String name;
  final String propertyType;
  final String? address;
  final double purchasePrice;
  final double totalCost;
  final DateTime purchaseDate;
  final DateTime? soldAt;
  final String? note;

  RealEstate({
    required this.id,
    required this.name,
    required this.propertyType,
    required this.purchasePrice,
    required this.totalCost,
    required this.purchaseDate,
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
      purchasePrice: double.parse(json['purchase_price'].toString()),
      totalCost: double.parse(json['total_cost'].toString()),
      purchaseDate: DateTime.parse(json['purchase_date']),
      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'])
          : null,
      note: json['note'],
    );
  }
}
