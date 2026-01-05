import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService api;
  AuthProvider(this.api);

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  String? _token;
  String? get token => _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  bool loading = false;
  String? error;
  bool updatingName = false;
  bool changingPassword = false;

  /// ✅ Tạo Dio có baseUrl + token (nếu có)
  Dio get dio {
    const rawBase = String.fromEnvironment(
      'API_BASE',
      defaultValue: 'http://192.168.1.67:8000',
    );

    final d = Dio(BaseOptions(
      baseUrl: '$rawBase/api/',
      headers: {
        'Accept': 'application/json',
        if (_token != null && _token!.isNotEmpty)
          'Authorization': 'Bearer $_token',
      },
    ));
    return d;
  }

  /// 🔹 Khởi động: nạp token và lấy hồ sơ
  Future<void> bootstrap({VoidCallback? onReady}) async {
    try {
      _token = await AuthService.readToken();

      if (_token != null && _token!.isNotEmpty) {
        try {
          _user = await api.me();
        } catch (e) {
          if (kDebugMode) print('Bootstrap me() error: $e');
          _user = null;
        }
      } else {
        _user = null;
      }

      error = null;
      notifyListeners(); // ✅ phải có: để AccountsPage lắng nghe thay đổi khi mở app
    } catch (e) {
      if (kDebugMode) print('Bootstrap error: $e');
      _user = null;
      _token = null;
      notifyListeners(); // ✅ vẫn cần để báo UI biết trạng thái thay đổi
    }

    if (onReady != null) onReady();
  }

  /// 🔹 Làm mới hồ sơ
  Future<void> refresh() async {
    if (!isAuthenticated) return;
    try {
      _user = await api.me();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Refresh error: $e');
    }
  }

  /// 🔹 Đăng nhập
  Future<bool> login(String email, String pass) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await api.login(email, pass);
      _token = await api.getToken();

      if (!isAuthenticated) {
        error = 'Không nhận được token từ máy chủ';
        _user = null;
        notifyListeners(); // ✅ vẫn phải thông báo để UI biết lỗi
        return false;
      }

      _user = Map<String, dynamic>.from(res);
      error = null;

      // ✅ Bổ sung: lưu token & thông báo login thành công
      await AuthService.saveToken(_token!);
      notifyListeners(); // 🔥 Báo cho AccountsPage biết là user đã login → sẽ fetch lại dữ liệu

      return true;
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      error = 'Đăng nhập thất bại';
      _user = null;
      _token = null;
      notifyListeners(); // ✅ báo lỗi cũng cần thông báo
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 🔹 Đăng ký
  Future<bool> register(String name, String email, String pass) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await api.register(name, email, pass);
      _token = await api.getToken();

      if (!isAuthenticated) {
        _user = null;
        notifyListeners();
        return false;
      }

      _user = Map<String, dynamic>.from(res);
      error = null;

      // ✅ Lưu token sau đăng ký
      await AuthService.saveToken(_token!);
      notifyListeners(); // 🔥 thông báo đăng ký xong

      return true;
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      error = 'Đăng ký thất bại';
      _user = null;
      _token = null;
      notifyListeners();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 🔹 Đăng xuất
  Future<void> logout() async {
    try {
      await api.logout();
    } catch (e) {
      if (kDebugMode) print('Logout error: $e');
    }
    await AuthService.clearToken();
    _user = null;
    _token = null;
    error = null;
    notifyListeners(); // ✅ báo cho UI biết để clear state
  }

  /// 🔹 Cập nhật tên
  Future<bool> updateName(String newName) async {
    if (!isAuthenticated) return false;
    updatingName = true;
    notifyListeners();
    try {
      final updated = await api.updateName(newName);
      if (updated == null) return false;
      _user = {...?_user, ...updated};
      error = null;
      notifyListeners(); // ✅ cập nhật UI tên mới
      return true;
    } catch (e) {
      if (kDebugMode) print('UpdateName error: $e');
      return false;
    } finally {
      updatingName = false;
      notifyListeners();
    }
  }

  /// 🔹 Đổi mật khẩu
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return false;
    changingPassword = true;
    notifyListeners();
    try {
      final ok = await api.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      notifyListeners();
      return ok;
    } catch (e) {
      if (kDebugMode) print('ChangePassword error: $e');
      return false;
    } finally {
      changingPassword = false;
      notifyListeners();
    }
  }
}
