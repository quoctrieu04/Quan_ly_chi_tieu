class BankTransaction {
  final int id;
  final int userId;
  final int? docId; // có thể null (giao dịch hệ thống hoặc chưa liên kết invoice)
  final String docType;
  final int bankId;
  final num amount; // num để tránh lỗi float từ Laravel
  final num prebalance;
  final int operation; // 1: thu, -1: chi
  final String? description; // ✅ thêm để khớp cột "description" trong DB
  final DateTime createdAt;
  final DateTime updatedAt;

  BankTransaction({
    required this.id,
    required this.userId,
    this.docId,
    required this.docType,
    required this.bankId,
    required this.amount,
    required this.prebalance,
    required this.operation,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      docId: json['doc_id'],
      docType: json['doc_type'] ?? '',
      bankId: json['bank_id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      prebalance: (json['prebalance'] ?? 0).toDouble(),
      operation: json['operation'] ?? 0,
      description: json['description'], // ✅ parse thêm
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'doc_id': docId,
        'doc_type': docType,
        'bank_id': bankId,
        'amount': amount,
        'prebalance': prebalance,
        'operation': operation,
        if (description != null && description!.isNotEmpty)
          'description': description, // ✅ chỉ gửi khi có giá trị
      };

  /// 💡 Tiện ích hiển thị trong UI
  String get typeLabel => operation == 1 ? 'Thu' : 'Chi';
}
