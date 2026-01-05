import 'package:dio/dio.dart';
import 'bank_account_model.dart';

class BankAccountService {
  final Dio _dio;
  BankAccountService(this._dio);
   void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 🔹 Lấy danh sách tài khoản ngân hàng / ví
  Future<List<BankAccount>> getAccounts() async {
    final res = await _dio.get('api/bankaccounts'); // ✅ thêm 'api/'
    final body = res.data;
    final List raw = (body is List) ? body : (body['data'] ?? []);

    final accounts = raw
        .map((e) => BankAccount.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.isDeleted == false)
        .toList();
    return accounts;
  }

  /// 🔹 Tạo tài khoản mới
  Future<BankAccount> createAccount(Map<String, dynamic> body) async {
    final res = await _dio.post('api/bankaccounts', data: body);
    return BankAccount.fromJson(Map<String, dynamic>.from(res.data ?? {}));
  }

  /// 🔹 Cập nhật tài khoản
  Future<BankAccount> updateAccount(int id, Map<String, dynamic> body) async {
    final res = await _dio.put('api/bankaccounts/$id', data: body);
    return BankAccount.fromJson(Map<String, dynamic>.from(res.data ?? {}));
  }

  /// 🔹 Xóa tài khoản (soft delete)
  Future<void> deleteAccount(int id) async {
    await _dio.delete('api/bankaccounts/$id');
  }

  /// 🔹 Đặt tài khoản mặc định
  Future<void> makeDefault(int id) async {
    await _dio.post('api/bankaccounts/$id/default');
  }
}
