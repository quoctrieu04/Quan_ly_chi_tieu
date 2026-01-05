class IncomeCategory {
  final int id;
  final String title;
  final String currency;
  final num balance;
  final int? month;
  final int? year;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  IncomeCategory({
    required this.id,
    required this.title,
    required this.currency,
    required this.balance,
    this.month,
    this.year,
    this.createdAt,
    this.updatedAt,
  });

  factory IncomeCategory.fromJson(Map<String, dynamic> j) => IncomeCategory(
        id: j['id'] is String ? int.tryParse(j['id']) ?? 0 : (j['id'] ?? 0),
        title: (j['title'] ?? '').toString(),
        currency: (j['currency'] ?? 'VND').toString(),
        balance: (j['balance'] ?? 0) is String
            ? num.tryParse(j['balance']) ?? 0
            : (j['balance'] ?? 0),
        month: j['month'] != null ? int.tryParse(j['month'].toString()) : null,
        year: j['year'] != null ? int.tryParse(j['year'].toString()) : null,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'])
            : null,
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'currency': currency,
        'balance': balance,
        'month': month,
        'year': year,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  IncomeCategory copyWith({
    int? id,
    String? title,
    String? currency,
    num? balance,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
