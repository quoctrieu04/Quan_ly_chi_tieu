class Category {
  final int id;
  final String name;       // map từ 'title' hoặc 'name'
  final bool isDeleted;    // map từ 'is_delete'
  final String type;       // 'out' | 'in'

  Category({
    required this.id,
    required this.name,
    this.isDeleted = false,
    this.type = 'out',
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? json['ID'] ?? 0) as int,
      name: (json['title'] ?? json['name'] ?? '') as String,
      isDeleted: json['is_delete'] == 1 || json['is_delete'] == true,
      type: (json['type'] ?? 'out') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': name,
        'is_delete': isDeleted,
        'type': type,
      };
}
