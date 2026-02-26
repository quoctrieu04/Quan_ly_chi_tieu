class FinancialTransaction {
  final int id;
  final int userId;
  final String direction; // in | out
  final num amount;

  final String category; // income_expense | investment_bank | real_estate | ...
  final String action;   // expense_created | income_created | real_estate_cost | ...

  final DateTime occurredAt;

  final String title;
  final String? description;

  final String? refType;
  final int? refId;

  final Map<String, dynamic>? meta;

  FinancialTransaction({
    required this.id,
    required this.userId,
    required this.direction,
    required this.amount,
    required this.category,
    required this.action,
    required this.occurredAt,
    required this.title,
    this.description,
    this.refType,
    this.refId,
    this.meta,
  });

  static num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.parse(v.toString());
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    final occurredRaw = json['occurred_at']?.toString();
    return FinancialTransaction(
      id: (json['id'] as int?) ?? 0,
      userId: (json['user_id'] as int?) ?? 0,
      direction: (json['direction'] ?? '') as String,
      amount: _parseNum(json['amount']),
      category: (json['category'] ?? '') as String,
      action: (json['action'] ?? '') as String,
      occurredAt: occurredRaw != null && occurredRaw.isNotEmpty
          ? DateTime.parse(occurredRaw)
          : DateTime.now(),
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      refType: json['ref_type'] as String?,
      refId: _parseInt(json['ref_id']),
      meta: (json['meta'] is Map<String, dynamic>)
          ? (json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}