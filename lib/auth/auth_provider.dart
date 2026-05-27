import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService api;
  AuthProvider(this.api);
  bool _googleInitialized = false;

  // ================== STATE ==================
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  String? _accessToken; // ✅ GIỮ TOKEN Ở RAM
  String? get accessToken => _accessToken;

  bool loading = false;
  String? error;
  String? emailError;
  String? passwordError;
  String? nameError;
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
  void clearLoginErrors({bool notify = true}) {
    error = null;
    emailError = null;
    passwordError = null;
    if (notify) notifyListeners();
  }

  void clearRegisterErrors({bool notify = true}) {
    error = null;
    nameError = null;
    emailError = null;
    passwordError = null;
    if (notify) notifyListeners();
  }

  Future<bool> login(String email, String pass) async {
    loading = true;
    clearLoginErrors(notify: false);
    notifyListeners();

    try {
      // 1️⃣ Login (AuthService lưu token)
      await api.login(email, pass);

      // 2️⃣ Lấy token + user
      _accessToken = await api.getAccessToken();
      _user = await api.me();

      return true;
    } on AuthLoginException catch (e) {
      if (kDebugMode) print('Login error: $e');
      emailError = e.emailError;
      passwordError = e.passwordError;
      error = e.message;
      _user = null;
      _accessToken = null;
      await api.clearToken();
      return false;
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

  // ================== GOOGLE LOGIN ==================
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<bool> loginWithGoogle() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _ensureGoogleInitialized();

      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        error = 'Không thể lấy token xác thực từ Google';
        return false;
      }

      // 1️⃣ Gửi Google Token lên Server để lấy Access Token của app
      await api.loginWithGoogle(idToken);

      // 2️⃣ Lấy token + user (sau khi backend đã xác thực và cấp token)
      _accessToken = await api.getAccessToken();
      _user = await api.me();

      return true;
    } on GoogleSignInException catch (e) {
      if (kDebugMode) print('Google Login error: $e');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        error = null;
        return false;
      }
      error = 'Đăng nhập Google thất bại';
      _user = null;
      _accessToken = null;
      await api.clearToken();
      return false;
    } catch (e) {
      if (kDebugMode) print('Google Login error: $e');
      error = 'Đăng nhập Google thất bại';
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
    clearRegisterErrors(notify: false);
    notifyListeners();

    try {
      await api.register(name, email, pass);
      await api.clearToken();
      _accessToken = null;
      _user = null;

      return true;
    } on AuthRegisterException catch (e) {
      if (kDebugMode) print('Register error: $e');
      nameError = e.nameError;
      emailError = e.emailError;
      passwordError = e.passwordError;
      error = e.message;
      _user = null;
      _accessToken = null;
      await api.clearToken();
      return false;
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
