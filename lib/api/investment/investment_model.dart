class Investment {
  final int? id;

  /// Tên khoản đầu tư
  final String name;

  /// 'bank' | 'stock'
  final String type;

  /// Giá mua (bank = số tiền gửi)
  final double buyPrice;

  /// Giá hiện tại (bank = buyPrice)
  final double currentPrice;

  /// Số lượng (bank = 1)
  final double quantity;

  /// Ngân hàng (%/năm)
  final double? interestRate;

  /// Ngày bắt đầu gửi (bank)
  final DateTime? startDate;

  /// Thời điểm tạo bản ghi
  final DateTime createdAt;
  final String? bankName;


  Investment({
    this.id,
    required this.name,
    required this.type,
    required this.buyPrice,
    required this.currentPrice,
    required this.quantity,
    this.interestRate,
    this.startDate,
    required this.createdAt,
    this.bankName,

  });

  // ===================================================
  // JSON
  // ===================================================

  /// Map JSON → Model
  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'],
      buyPrice: (json['buy_price'] ?? 0).toDouble(),
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1).toDouble(),
      interestRate: json['interest_rate']?.toDouble(),
      startDate: json['start_date'] != null && json['start_date'] != ''
          ? DateTime.parse(json['start_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      bankName: json['bank_name'],
    );
  }

  /// Model → Map JSON (gửi lên API)
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

  /// Lãi ngân hàng – lãi đơn theo ngày
  double get _bankProfit {
    if (interestRate == null || startDate == null) return 0;

    final days = DateTime.now().difference(startDate!).inDays;
    if (days <= 0) return 0;

    return totalInvested *
        (interestRate! / 100) *
        (days / 365);
  }
}
