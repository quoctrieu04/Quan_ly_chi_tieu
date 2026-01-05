class InInvoice {
  final int id;
  final int userId;
  final int incatId;
  final int? banktransId;
  final num amount;
  final String? content;
  final int? month;
  final int? year;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? occurredAt;
  final String? categoryName;
  final String? walletName;
  final String? currency;

  String? get note => content;

  InInvoice({
    required this.id,
    required this.userId,
    required this.incatId,
    this.banktransId,
    required this.amount,
    this.content,
    this.month,
    this.year,
    this.createdAt,
    this.updatedAt,
    this.occurredAt,
    this.categoryName,
    this.walletName,
    this.currency,
  });

  factory InInvoice.fromJson(Map<String, dynamic> json) {
    // Helper: parse int safely
    int _parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Helper: parse num safely
    num _parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    // Helper: parse DateTime safely
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return InInvoice(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id'] ?? json['userId']),
      incatId: _parseInt(json['incat_id'] ?? json['incatId']),
      banktransId: _parseInt(json['banktrans_id'] ?? json['banktransId']),
      amount: _parseNum(json['amount']),
      content: json['content'],
      month: _parseInt(json['month']),
      year: _parseInt(json['year']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      occurredAt: _parseDate(json['occurred_at']),
      categoryName: json['category_name'] ??
          json['categoryName'] ??
          json['in_category'] ??
          json['category_title'],
      walletName: json['bank_name'] ??
          json['wallet_name'] ??
          json['bank_title'] ??
          json['account_name'],
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'incat_id': incatId,
        'banktrans_id': banktransId,
        'amount': amount,
        'content': content,
        'month': month,
        'year': year,
        'occurred_at': occurredAt?.toIso8601String(),
      };
}
