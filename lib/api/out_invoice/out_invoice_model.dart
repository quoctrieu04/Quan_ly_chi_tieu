class OutInvoice {
  final int id;
  final int userId;
  final int outcatId;
  final int? banktransId;
  final int amount;
  final String docType;
  final int? doctransId;
  final String? content;
  final int? month;
  final int? year;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? occurredAt; // 🟢 ngày phát sinh giao dịch
  final String? categoryName; // 🟢 tên danh mục chi
  final String? walletName;   // 🟢 tên ví
  final String? currency;

  // 👉 Getter tiện lợi cho UI
  String? get note => content;

  OutInvoice({
    required this.id,
    required this.userId,
    required this.outcatId,
    this.banktransId,
    required this.amount,
    required this.docType,
    this.doctransId,
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

  factory OutInvoice.fromJson(Map<String, dynamic> json) {
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

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      return int.tryParse(v.split('.').first); // loại bỏ .00 nếu có
    }
    return null;
  }

  return OutInvoice(
    id: _toInt(json['id']) ?? 0,
    userId: _toInt(json['user_id'] ?? json['userId']) ?? 0,
    outcatId: _toInt(json['outcat_id'] ?? json['outcatId']) ?? 0,
    banktransId: _toInt(json['banktrans_id'] ?? json['banktransId']),
    amount: _toInt(json['amount']) ?? 0,
    docType: json['doc_type'] ?? json['docType'] ?? 'OUT',
    doctransId: _toInt(json['doctrans_id'] ?? json['doctransId']),
    content: json['content']?.toString(),
    month: _toInt(json['month']),
    year: _toInt(json['year']),
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
    occurredAt: _parseDate(json['occurred_at']),
    categoryName: json['category_name'] ??
        json['categoryName'] ??
        json['out_category'] ??
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
        'outcat_id': outcatId,
        'banktrans_id': banktransId,
        'amount': amount,
        'doc_type': docType,
        'doctrans_id': doctransId,
        'content': content,
        'month': month,
        'year': year,
        'occurred_at': occurredAt?.toIso8601String(), // ✅ gửi ngày phát sinh
      };
}
