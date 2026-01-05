class TransactionItem {
  final int id;
  final int userId;
  final int? docId;
  final String docType; // in_invoice | out_invoice
  final int bankId;
  final num amount;
  final num prebalance;
  final int operation; // 1: thu, -1: chi
  final DateTime createdAt;

  const TransactionItem({
    required this.id,
    required this.userId,
    this.docId,
    required this.docType,
    required this.bankId,
    required this.amount,
    required this.prebalance,
    required this.operation,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> j) {
    num _n(v) {
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? 0;
    }

    return TransactionItem(
      id: j['id'] ?? 0,
      userId: j['user_id'] ?? 0,
      docId: j['doc_id'],
      docType: j['doc_type'] ?? '',
      bankId: j['bank_id'] ?? 0,
      amount: _n(j['amount']),
      prebalance: _n(j['prebalance']),
      operation: _n(j['operation']).toInt(),
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'doc_id': docId,
        'doc_type': docType,
        'bank_id': bankId,
        'amount': amount,
        'prebalance': prebalance,
        'operation': operation,
        'created_at': createdAt.toIso8601String(),
      };
}
