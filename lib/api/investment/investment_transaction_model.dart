class InvestmentTransaction {
  final int id;
  final int investmentId;
  final int operation; // 1: nhận vốn | -1: rút/tất toán | 0: gia hạn
  final double amount;
  final String description;
  final DateTime createdAt;

  InvestmentTransaction({
    required this.id,
    required this.investmentId,
    required this.operation,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory InvestmentTransaction.fromJson(Map<String, dynamic> json) {
    return InvestmentTransaction(
      id: json['id'],
      investmentId: json['investment_id'],
      operation: json['operation'] ?? 0,
      amount: _toDouble(json['amount']),
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
