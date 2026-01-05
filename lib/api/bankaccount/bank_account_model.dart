double _numToDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) {
    final s = v.trim()
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }
  return 0;
}

class BankAccount {
  final int id;
  final String name;
  final String? bankname;
  final String? banknumber;
  final double initialAmount;
  final double balance;
  final String currency;
  final bool isDefault;
  final bool isDeleted; // ✅ Thêm field này để hỗ trợ soft delete

  BankAccount({
    required this.id,
    required this.name,
    this.bankname,
    this.banknumber,
    required this.initialAmount,
    required this.balance,
    required this.currency,
    this.isDefault = false,
    this.isDeleted = false, // ✅ Mặc định chưa bị xóa
  });

  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
        id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
        name: j['title']?.toString() ?? j['name']?.toString() ?? '',
        bankname: j['bankname']?.toString(),
        banknumber: j['banknumber']?.toString(),
        initialAmount: _numToDouble(j['initamount'] ?? j['initial_amount']),
        balance: _numToDouble(j['balance']),
        currency: j['currency']?.toString() ?? 'VND',
        isDefault: j['is_default'] == 1 || j['is_default'] == true,
        isDeleted: j['is_deleted'] == 1 || j['is_deleted'] == true, // ✅ thêm parse
      );

  get title => null;

  get amount => null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': name,
        'bankname': bankname,
        'banknumber': banknumber,
        'initial_amount': initialAmount,
        'balance': balance,
        'currency': currency,
        'is_default': isDefault,
        'is_deleted': isDeleted, // ✅ thêm export
      };

  BankAccount copyWith({
    int? id,
    String? name,
    String? bankname,
    String? banknumber,
    double? initialAmount,
    double? balance,
    String? currency,
    bool? isDefault,
    bool? isDeleted,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      bankname: bankname ?? this.bankname,
      banknumber: banknumber ?? this.banknumber,
      initialAmount: initialAmount ?? this.initialAmount,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
