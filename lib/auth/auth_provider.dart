import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService api;
  AuthProvider(this.api);

  // ================== STATE ==================
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  String? _accessToken; // ✅ GIỮ TOKEN Ở RAM
  String? get accessToken => _accessToken;

  bool loading = false;
  String? error;
  bool updatingName = false;
  bool changingPassword = false;

  bool get isAuthenticated => _user != null;

  // ================== BOOTSTRAP ==================
  /// App start → nếu có token → gọi /api/auth/user
  Future<void> bootstrap({VoidCallback? onReady}) async {
    try {
      _accessToken = await api.getAccessToken();

      if (_accessToken != null && _accessToken!.isNotEmpty) {
        _user = await api.me();
      } else {
        _user = null;
      }

      error = null;
    } catch (e) {
      if (kDebugMode) print('Bootstrap error: $e');
      _user = null;
      _accessToken = null;
      await api.clearToken();
    }

    notifyListeners();
    onReady?.call();
  }

  // ================== REFRESH ==================
  Future<void> refresh() async {
    if (!isAuthenticated) return;

    try {
      _user = await api.me();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Refresh error: $e');
    }
  }

  // ================== LOGIN ==================
  Future<bool> login(String email, String pass) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      // 1️⃣ Login (AuthService lưu token)
      await api.login(email, pass);

      // 2️⃣ Lấy token + user
      _accessToken = await api.getAccessToken();
      _user = await api.me();

      return true;
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      error = 'Đăng nhập thất bại';
      _user = null;
      _accessToken = null;
      await api.clearToken();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ================== REGISTER ==================
  Future<bool> register(String name, String email, String pass) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await api.register(name, email, pass);

      _accessToken = await api.getAccessToken();
      _user = await api.me();

      return true;
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      error = 'Đăng ký thất bại';
      _user = null;
      _accessToken = null;
      await api.clearToken();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ================== LOGOUT ==================
  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}

    await api.clearToken();
    _user = null;
    _accessToken = null;
    error = null;
    notifyListeners();
  }

  // ================== UPDATE NAME ==================
  Future<bool> updateName(String newName) async {
    if (!isAuthenticated) return false;

    updatingName = true;
    notifyListeners();

    try {
      final updated = await api.updateName(newName);
      if (updated == null) return false;

      _user = {...?_user, ...updated};
      return true;
    } catch (e) {
      if (kDebugMode) print('UpdateName error: $e');
      return false;
    } finally {
      updatingName = false;
      notifyListeners();
    }
  }

  // ================== CHANGE PASSWORD ==================
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return false;

    changingPassword = true;
    notifyListeners();

    try {
      return await api.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      if (kDebugMode) print('ChangePassword error: $e');
      return false;
    } finally {
      changingPassword = false;
      notifyListeners();
    }
  }
}
