/// 1 bản ghi ngân sách cho 1 danh mục trong 1 tháng
class BudgetItem {
  final int id;           // id bản ghi budgets
  final int userId;       // user_id
  final int categoryId;   // category_id
  final int year;         // 1970..2100
  final int month;        // 1..12
  final int amount;       // số tiền phân bổ (VND, integer)
  final int spent;        // số tiền đã tiêu (VND, integer) <-- thêm
  final String? name;     // tên danh mục (nếu backend có join, bằng null nếu không)

  const BudgetItem({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.amount,
    required this.spent,   // <-- thêm
    this.name,
  });

  /// copyWith để cập nhật từng field mà giữ nguyên phần còn lại
  BudgetItem copyWith({
    int? id,
    int? userId,
    int? categoryId,
    int? year,
    int? month,
    int? amount,
    int? spent,   // <-- thêm
    String? name,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,  // <-- thêm
      name: name ?? this.name,
    );
  }

  // Parse linh hoạt: chấp nhận cả snake_case (Laravel) lẫn camelCase
  factory BudgetItem.fromJson(Map<String, dynamic> j) {
    int _i(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse(v.toString()) ?? 0;
    }

    return BudgetItem(
      id: _i(j['id']),
      userId: _i(j['user_id'] ?? j['userId']),
      categoryId: _i(j['category_id'] ?? j['categoryId']),
      year: _i(j['year']),
      month: _i(j['month']),
      amount: _i(j['amount']),
      spent: _i(j['spent']), // <-- thêm
      name: (j['name'] ?? j['category_name'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'year': year,
        'month': month,
        'amount': amount,
        'spent': spent, // <-- thêm
        if (name != null) 'name': name,
      };

  @override
  String toString() =>
      'BudgetItem(catId=$categoryId, ym=$year-$month, amount=$amount, spent=$spent, name=$name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          categoryId == other.categoryId &&
          year == other.year &&
          month == other.month &&
          amount == other.amount &&
          spent == other.spent && // <-- thêm
          name == other.name;

  @override
  int get hashCode =>
      Object.hash(id, userId, categoryId, year, month, amount, spent, name);
}

/// Kết quả trang /budgets (index/assign-many)
class BudgetsPage {
  final List<BudgetItem> items;
  final int totalAssigned;

  const BudgetsPage({
    required this.items,
    required this.totalAssigned,
  });

  factory BudgetsPage.fromIndexJson(Map<String, dynamic> j) {
    final list = (j['data'] as List? ?? [])
        .map((e) => BudgetItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    int _i(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse('$v') ?? 0;
    }

    return BudgetsPage(
      items: list,
      totalAssigned: _i(j['total_assigned']),
    );
  }
}
