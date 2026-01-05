import 'dart:convert';
import 'package:chitieu/api/investment/investment_model.dart';
import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CreateInvestmentForm extends StatefulWidget {
  const CreateInvestmentForm({super.key});

  @override
  State<CreateInvestmentForm> createState() => _CreateInvestmentFormState();
}

class _CreateInvestmentFormState extends State<CreateInvestmentForm> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _buy = TextEditingController();
  final _current = TextEditingController();
  final _qty = TextEditingController();
  final _symbol = TextEditingController();

  String _assetType = "custom";
  bool _autoUpdate = false;

  String apiSource = "";
  String apiField = "";
  String apiPath = "";

  @override
  void dispose() {
    _name.dispose();
    _buy.dispose();
    _current.dispose();
    _qty.dispose();
    _symbol.dispose();
    super.dispose();
  }

  // =============================
  // Parse tiền (loại dấu ,)
  // =============================
  double _parseMoney(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 0;
  }

  // =============================
  // Format tiền khi nhập
  // =============================
  TextInputFormatter _moneyFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
      final number = int.tryParse(digits) ?? 0;
      final formatted = NumberFormat("#,##0", "vi_VN").format(number);
      return newValue.copyWith(text: formatted);
    });
  }

  // =============================
  // Cấu hình API theo loại tài sản
  // =============================
  void _updateApiConfig() {
    apiSource = "";
    apiField = "";
    apiPath = "";

    switch (_assetType) {
      case "gold":
        apiSource = "https://sjc.azurewebsites.net/json/sjc.json";
        apiPath = "cities.HCM.buy";
        break;

      case "crypto":
        final symbol = _symbol.text.trim().toLowerCase();
        apiSource =
            "https://api.coingecko.com/api/v3/simple/price?ids=$symbol&vs_currencies=vnd";
        apiPath = "$symbol.vnd";
        break;

      case "stock":
        final symbol = _symbol.text.trim().toUpperCase();
        apiSource =
            "https://finfo-api.vndirect.com.vn/v4/stock_prices/?symbol=$symbol";
        apiPath = "data.0.adjClose";
        break;

      case "custom":
      default:
        break;
    }
  }

  // =============================
  // Fetch giá từ API (có fallback)
  // =============================
  Future<double> fetchAutoPrice(double buyPrice) async {
    if (!_autoUpdate) {
      return _parseMoney(_current.text);
    }

    try {
      final res = await http.get(Uri.parse(apiSource));
      if (res.statusCode != 200) return buyPrice;

      final json = jsonDecode(res.body);
      dynamic data = json;

      for (final key in apiPath.split(".")) {
        data = (key == "0") ? data[0] : data[key];
      }

      final price = double.tryParse(data.toString());
      return (price != null && price > 0) ? price : buyPrice;
    } catch (_) {
      return buyPrice; // fallback an toàn
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Thêm khoản đầu tư",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Tên
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: "Tên khoản đầu tư",
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Không được bỏ trống"
                    : null,
              ),
              const SizedBox(height: 12),

              // Loại tài sản
              DropdownButtonFormField<String>(
                value: _assetType,
                decoration: const InputDecoration(
                  labelText: "Loại tài sản",
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: "gold", child: Text("Vàng SJC")),
                  DropdownMenuItem(value: "crypto", child: Text("Crypto")),
                  DropdownMenuItem(value: "stock", child: Text("Cổ phiếu VN")),
                  DropdownMenuItem(value: "custom", child: Text("Tuỳ chỉnh")),
                ],
                onChanged: (v) {
                  setState(() {
                    _assetType = v!;
                    _autoUpdate = _assetType != "custom";
                  });
                },
              ),
              const SizedBox(height: 12),

              // Symbol
              if (_assetType == "crypto" || _assetType == "stock")
                TextFormField(
                  controller: _symbol,
                  decoration: const InputDecoration(
                    labelText: "Mã tài sản (BTC, ETH, FPT...)",
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (v) {
                    if (_assetType == "crypto" || _assetType == "stock") {
                      return (v == null || v.trim().isEmpty)
                          ? "Không được bỏ trống"
                          : null;
                    }
                    return null;
                  },
                ),

              if (_assetType == "crypto" || _assetType == "stock")
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "Giá sẽ được cập nhật tự động từ API",
                    style: TextStyle(fontSize: 12),
                  ),
                ),

              const SizedBox(height: 12),

              // Giá mua
              TextFormField(
                controller: _buy,
                keyboardType: TextInputType.number,
                inputFormatters: [_moneyFormatter()],
                decoration: const InputDecoration(
                  labelText: "Giá mua (VND)",
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (v) =>
                    _parseMoney(v ?? "") <= 0 ? "Nhập số hợp lệ" : null,
              ),
              const SizedBox(height: 12),

              // Giá hiện tại (custom)
              if (_assetType == "custom")
                TextFormField(
                  controller: _current,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_moneyFormatter()],
                  decoration: const InputDecoration(
                    labelText: "Giá hiện tại (VND)",
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  validator: (v) =>
                      _parseMoney(v ?? "") <= 0 ? "Nhập số hợp lệ" : null,
                ),
              if (_assetType == "custom") const SizedBox(height: 12),

              // Số lượng
              TextFormField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Số lượng",
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) =>
                    double.tryParse(v ?? "") == null ? "Nhập số hợp lệ" : null,
              ),
              const SizedBox(height: 24),

              // Lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text("Lưu"),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    _updateApiConfig();

                    final buyPrice = _parseMoney(_buy.text);
                    final qty = double.tryParse(_qty.text) ?? 0;

                    final currentPrice = await fetchAutoPrice(buyPrice);

                    final totalInvested = buyPrice * qty;
                    final profitLoss = (currentPrice - buyPrice) * qty;

                    final inv = Investment(
                      userId: 0,
                      name: _name.text.trim(),
                      type: _assetType,
                      buyPrice: buyPrice,
                      currentPrice: currentPrice,
                      quantity: qty,
                      totalInvested: totalInvested,
                      profitLoss: profitLoss,
                      autoUpdate: _autoUpdate,
                      symbol: _symbol.text.trim(),
                      apiSource: apiSource,
                      apiPath: apiPath,
                      createdAt: DateTime.now(),
                    );

                    final ok =
                        await context.read<InvestmentProvider>().add(inv);

                    if (ok && mounted) Navigator.pop(context, true);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
