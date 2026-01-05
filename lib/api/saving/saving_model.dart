class SavingModel {
  final int id;
  final int userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double monthlyAmount;
  final String startDate;
  final String status;

  SavingModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyAmount,
    required this.startDate,
    required this.status,
  });

  factory SavingModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return SavingModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      targetAmount: toDouble(json['target_amount']),
      currentAmount: toDouble(json['current_amount']),
      monthlyAmount: toDouble(json['monthly_amount']),
      startDate: json['start_date'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
