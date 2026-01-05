import 'package:flutter/foundation.dart';
import 'bank_account_model.dart';
import 'bank_account_service.dart';

class BankAccountProvider extends ChangeNotifier {
  BankAccountService _service;
  String? _token; // ✅ lưu token hiện tại

  BankAccountProvider({required BankAccountService service})
      : _service = service;

  List<BankAccount> _items = [];
  bool _loading = false;
  String? _error;

  List<BankAccount> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  double get totalBalance => _items.fold(0.0, (sum, e) => sum + e.balance);

  BankAccount? get defaultAccount {
    try {
      return _items.firstWhere((e) => e.isDefault);
    } catch (_) {
      return null;
    }
  }

  // ====================================================
  // 🔹 Cập nhật token khi AuthProvider thay đổi
  // ====================================================
  void updateAuthToken(String? token) {
    _token = token;
    if (token != null && token.isNotEmpty) {
      // ✅ Khi có token mới, fetch dữ liệu ngay
      fetchAccounts();
    } else {
      // 🚫 Khi đăng xuất, xoá dữ liệu
      clear();
    }
  }

  // ====================================================
  // 🔹 LẤY DANH SÁCH TÀI KHOẢN
  // ====================================================
  Future<void> fetchAccounts({String? token}) async {
    debugPrint('🔍 [BankAccountProvider] fetchAccounts() được gọi');

    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (token != null && token.isNotEmpty) {
        _service.setToken(token); // ✅ Gắn token mỗi lần fetch
      }

      debugPrint('🌐 Gọi API /api/bankaccounts...');
      final accounts = await _service.getAccounts();
      _items = accounts;
      debugPrint('✅ Load thành công ${_items.length} tài khoản');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ BankAccountProvider.fetch error: $_error');
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ✅ Alias cho code cũ (fetch)
  Future<void> fetch({int? year, int? month, String? token}) async {
    if (token != null) updateAuthToken(token);
    await fetchAccounts();
  }

  // ====================================================
  // 🔹 TẠO TÀI KHOẢN MỚI
  // ====================================================
  Future<bool> create({
    required String name,
    String? bankName,
    String? bankNumber,
    double? initAmount,
    String? currency,
  }) async {
    try {
      _service.setToken(_token ?? '');
      final acc = await _service.createAccount({
        'name': name,
        'bankname': bankName,
        'banknumber': bankNumber,
        'initamount': initAmount ?? 0,
        'currency': currency ?? 'VND',
      });

      _items.add(acc);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ====================================================
  // 🔹 CẬP NHẬT TÀI KHOẢN
  // ====================================================
  Future<bool> updateAccount(int id, Map<String, dynamic> body) async {
    try {
      _service.setToken(_token ?? '');
      final updated = await _service.updateAccount(id, body);
      final index = _items.indexWhere((e) => e.id == id);
      if (index != -1) {
        _items[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ====================================================
  // 🔹 XÓA TÀI KHOẢN (Soft Delete)
  // ====================================================
  Future<bool> deleteAccount(int id) async {
    try {
      _service.setToken(_token ?? '');
      await _service.deleteAccount(id);
      _items.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ====================================================
  // 🔹 ĐẶT TÀI KHOẢN MẶC ĐỊNH
  // ====================================================
  Future<void> makeDefault(int id) async {
    try {
      _service.setToken(_token ?? '');
      await _service.makeDefault(id);
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(isDefault: _items[i].id == id);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ====================================================
  // 🔹 XÓA DỮ LIỆU KHI ĐĂNG XUẤT
  // ====================================================
  void clear() {
    _items = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }

  // ====================================================
  // 🔹 CẬP NHẬT SỐ DƯ TẠI CLIENT
  // ====================================================
  void updateWalletBalance(int id, double newBalance, {String? name}) {
    final idx = _items.indexWhere((w) => w.id == id);
    if (idx == -1) return;

    _items[idx] = _items[idx].copyWith(
      balance: newBalance,
      name: name ?? _items[idx].name,
    );
    notifyListeners();
  }

  // ====================================================
  // 🔹 HÀM TIỆN DỤNG CHO UI
  // ====================================================
  Future<bool> createBankAccount({
    required String title,
    String? bankName,
    String? bankNumber,
    double? initAmount,
    String? currency,
  }) async {
    return await create(
      name: title,
      bankName: bankName,
      bankNumber: bankNumber,
      initAmount: initAmount,
      currency: currency,
    );
  }

  void updateService(BankAccountService newService) {
    _service = newService;
  }
}
