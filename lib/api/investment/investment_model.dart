class Investment {
  final int? id;
  final String name;
  final String type;

  final double buyPrice;
  final double currentPrice;
  final double quantity;

  // Bank fields
  final double? interestRate;
  final DateTime? startDate;
  final String? bankName;
  final int? termMonths;

  final DateTime createdAt;

  // ✅ FIX: accountSource nên là int? (id tài khoản)
  final int? accountSource;
  final DateTime? closedAt;

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
    this.closedAt,
  });

  // ===================================================
  // JSON
  // ===================================================
  factory Investment.fromJson(Map<String, dynamic> json) {
    final dynamic acc = json['accountSource'] ?? json['account_source'];

    return Investment(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      buyPrice: (json['buy_price'] ?? 0).toDouble(),
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1).toDouble(),
      interestRate: json['interest_rate'] != null
          ? (json['interest_rate'] as num).toDouble()
          : null,
      startDate: json['start_date'] != null && json['start_date'] != ''
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      bankName: (json['bank_name'] ?? json['bankName'])?.toString(),
      termMonths: json['term_months'] is int
          ? json['term_months']
          : int.tryParse((json['term_months'] ?? '').toString()),
      createdAt: json['created_at'] != null && json['created_at'] != ''
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      accountSource: acc == null ? null : int.tryParse(acc.toString()),
      closedAt:
          json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
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

      // ✅ FIX: gửi int
      'accountSource': accountSource,
    };
  }

  // ===================================================
  // COPY
  // ===================================================
  Investment copyWith({
    double? currentPrice,
    double? buyPrice,
    double? quantity,
    double? interestRate,
    DateTime? startDate,
    String? bankName,
    int? termMonths,
    int? accountSource,
    DateTime? closedAt,
  }) {
    return Investment(
      id: id,
      name: name,
      type: type,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      quantity: quantity ?? this.quantity,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      bankName: bankName ?? this.bankName,
      termMonths: termMonths ?? this.termMonths,
      createdAt: createdAt,
      accountSource: accountSource ?? this.accountSource,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  // ===================================================
  // CALCULATION (KHÔNG LƯU DB)
  // ===================================================

  /// Tổng vốn bỏ ra
  double get totalInvested => buyPrice * quantity;

  /// Lãi / lỗ
  double get profitLoss {
    if (type == 'bank') return _bankProfit;
    return (currentPrice - buyPrice) * quantity;
  }

  /// % lãi
  double get profitPercent {
    if (totalInvested == 0) return 0;
    return profitLoss / totalInvested * 100;
  }

  /// Lãi ngân hàng – lãi đơn theo kỳ hạn (termMonths)
  double get _bankProfit {
    if (interestRate == null || startDate == null || termMonths == null)
      return 0;

    final months = termMonths!;
    return totalInvested * (interestRate! / 100) * (months / 12);
  }
}
