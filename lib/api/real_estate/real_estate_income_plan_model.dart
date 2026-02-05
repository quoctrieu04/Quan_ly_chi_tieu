class RealEstateIncomePlan {
  final int id;
  final int realEstateId;
  final double monthlyAmount;
  final double totalCollected;
  final int collectedCount;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? lastCollectedAt;
  final bool isActive;

  RealEstateIncomePlan({
    required this.id,
    required this.realEstateId,
    required this.monthlyAmount,
    required this.totalCollected,
    required this.collectedCount,
    required this.startDate,
    required this.nextDueDate,
    required this.isActive,
    this.lastCollectedAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  factory RealEstateIncomePlan.fromJson(Map<String, dynamic> json) {
    return RealEstateIncomePlan(
      id: json['id'],
      realEstateId: json['real_estate_id'],
      monthlyAmount: _toDouble(json['monthly_amount']),
      totalCollected: _toDouble(json['total_collected']),
      collectedCount: json['collected_count'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      nextDueDate: DateTime.parse(json['next_due_date']),
      lastCollectedAt: json['last_collected_at'] != null
          ? DateTime.parse(json['last_collected_at'])
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  /// tiện cho UI
  bool get canCollectToday {
    final today = DateTime.now();
    return isActive &&
        !today.isBefore(
          DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day),
        );
  }
}
