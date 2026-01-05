
class SavingTransaction {
  final int id;
  final int userId;
  final int savingId;
  final int? bankId;
  final double amount;
  final String date;
  final String? note;

  SavingTransaction({
    required this.id,
    required this.userId,
    required this.savingId,
    this.bankId,
    required this.amount,
    required this.date,
    this.note,
  });

  factory SavingTransaction.fromJson(Map<String, dynamic> json) {
    return SavingTransaction(
      id: json['id'],
      userId: json['user_id'],
      savingId: json['saving_id'],
      bankId: json['bank_id'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'],
      note: json['note'],
    );
  }
}
