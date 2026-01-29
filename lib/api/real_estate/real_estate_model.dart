class RealEstateInvestment {
  final int id;
  final String name;
  final String propertyType;
  final String? address;
  final double purchasePrice;
  final DateTime purchaseDate;
  final int accountSourceId;
  final String status;
  final String? notes;

  RealEstateInvestment({
    required this.id,
    required this.name,
    required this.propertyType,
    this.address,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.accountSourceId,
    required this.status,
    this.notes,
  });

  factory RealEstateInvestment.fromJson(Map<String, dynamic> json) {
    return RealEstateInvestment(
      id: json['id'],
      name: json['name'],
      propertyType: json['property_type'],
      address: json['address'],
      purchasePrice:
          (json['purchase_price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchase_date']),
      accountSourceId: json['account_source_id'],
      status: json['status'],
      notes: json['notes'],
    );
  }
}
