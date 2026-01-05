class Investment {
  final int? id;
  final int userId;

  final String name;
  final String type; // gold / crypto / stock / custom

  final double buyPrice;
  final double currentPrice;
  final double quantity;

  final double totalInvested;
  final double profitLoss;

  // 🔥 Auto update fields
  final bool autoUpdate;
  final String? symbol;
  final String? apiSource;
  final String? apiField;
  final String? apiPath;

  final DateTime createdAt;

  Investment({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.buyPrice,
    required this.currentPrice,
    required this.quantity,
    required this.totalInvested,
    required this.profitLoss,
    required this.autoUpdate,
    this.symbol,
    this.apiSource,
    this.apiField,
    this.apiPath,
    required this.createdAt,
  });

  factory Investment.fromJson(Map<String, dynamic> j) {
    return Investment(
      id: j["id"],
      userId: j["user_id"],
      name: j["name"],
      type: j["type"] ?? "custom",

      buyPrice: (j["buy_price"] as num).toDouble(),
      currentPrice: (j["current_price"] ?? 0).toDouble(),
      quantity: (j["quantity"] as num).toDouble(),

      totalInvested: (j["total_invested"] as num).toDouble(),
      profitLoss: (j["profit_loss"] ?? 0).toDouble(),

      autoUpdate: j["auto_update"] == 1 || j["auto_update"] == true,
      symbol: j["symbol"],
      apiSource: j["api_source"],
      apiField: j["api_field"],
      apiPath: j["api_path"],

      createdAt: DateTime.parse(j["created_at"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,

      "name": name,
      "type": type,

      "buy_price": buyPrice,
      "current_price": currentPrice,
      "quantity": quantity,

      "total_invested": totalInvested,
      "profit_loss": profitLoss,

      "auto_update": autoUpdate,
      "symbol": symbol,
      "api_source": apiSource,
      "api_field": apiField,
      "api_path": apiPath,
    };
  }
}
