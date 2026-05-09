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
  final DateTime? lastInterestDate;
  
  // Bank new fields
  final String? interestPaymentMethod;
  final String? rolloverMethod;

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
    this.lastInterestDate,
    this.interestPaymentMethod,
    this.rolloverMethod,
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
      lastInterestDate: json['last_interest_date'] != null
          ? DateTime.parse(json['last_interest_date'])
          : null,
      interestPaymentMethod: json['interest_payment_method']?.toString(),
      rolloverMethod: json['rollover_method']?.toString(),
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
      'interest_payment_method': interestPaymentMethod,
      'rollover_method': rolloverMethod,

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
    DateTime? lastInterestDate,
    String? interestPaymentMethod,
    String? rolloverMethod,
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
      lastInterestDate: lastInterestDate ?? this.lastInterestDate,
      interestPaymentMethod: interestPaymentMethod ?? this.interestPaymentMethod,
      rolloverMethod: rolloverMethod ?? this.rolloverMethod,
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

    final start = startDate!;
    final lastDate = lastInterestDate ?? start;
    
    // Tính số tháng đã trôi qua kể từ ngày bắt đầu đến lần rút lãi cuối cùng
    int monthsPassedTotal = 0;
    DateTime temp = DateTime(start.year, start.month + 1, start.day);
    while (temp.isBefore(lastDate) || temp.isAtSameMomentAs(lastDate)) {
      monthsPassedTotal++;
      temp = DateTime(temp.year, temp.month + 1, temp.day);
    }

    // Số tháng còn lại sẽ sinh lãi
    int remainingMonths = termMonths! - monthsPassedTotal;
    if (remainingMonths < 0) remainingMonths = 0;

    return totalInvested * (interestRate! / 100) * (remainingMonths / 12);
  }
}
