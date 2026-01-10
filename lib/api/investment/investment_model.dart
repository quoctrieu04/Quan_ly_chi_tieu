class Investment {
  final int? id;
  final String name;
  final String type;
  final double buyPrice;
  final double currentPrice;
  final double quantity;
  final double? interestRate;
  final DateTime? startDate;
  final String? bankName;
  final int? termMonths;
  final DateTime createdAt;
  final String? accountSource;

  Investment({
    this.id,
    required this.name,
    required this.type,
    required this.buyPrice,
    required this.currentPrice,
    required this.quantity,
    this.interestRate,
    this.startDate,
    this.bankName,
    this.termMonths,
    required this.createdAt,
    this.accountSource,
  });

  // ===================================================
  // JSON
  // ===================================================

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'],
      buyPrice: (json['buy_price'] ?? 0).toDouble(),
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1).toDouble(),
      interestRate: json['interest_rate'] != null
          ? (json['interest_rate'] as num).toDouble()
          : null,
      startDate: json['start_date'] != null && json['start_date'] != ''
          ? DateTime.parse(json['start_date'])
          : null,
      bankName: json['bank_name'],
      termMonths: json['term_months'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      accountSource: json['accountSource'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'buy_price': buyPrice,
      'current_price': currentPrice,
      'quantity': quantity,
      'interest_rate': interestRate,
      'start_date': startDate?.toIso8601String(),
      'bank_name': bankName,
      'term_months': termMonths,
      'accountSource': accountSource,
    };
  }

  // ===================================================
  // COPY
  // ===================================================

  Investment copyWith({
    double? currentPrice,
  }) {
    return Investment(
      id: id,
      name: name,
      type: type,
      buyPrice: buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      quantity: quantity,
      interestRate: interestRate,
      startDate: startDate,
      bankName: bankName,
      termMonths: termMonths,
      createdAt: createdAt,
    );
  }

  // ===================================================
  // CALCULATION (KHÔNG LƯU DB)
  // ===================================================

  /// Tổng vốn bỏ ra
  double get totalInvested => buyPrice * quantity;

  /// Lãi / lỗ
  double get profitLoss {
    if (type == 'bank') {
      return _bankProfit;
    }
    return (currentPrice - buyPrice) * quantity;
  }

  /// % lãi
  double get profitPercent {
    if (totalInvested == 0) return 0;
    return profitLoss / totalInvested * 100;
  }

  /// Lãi ngân hàng – lãi đơn theo tháng (theo công thức bạn đưa)
  double get _bankProfit {
    if (interestRate == null || startDate == null || termMonths == null) return 0;

    // Tính số tháng gửi
    final months = termMonths!;

    // Tính lãi đơn theo công thức
    return totalInvested *
        (interestRate! / 100) *
        (months / 12);  // Lãi suất theo tháng
  }
}
