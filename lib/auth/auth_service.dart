import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio;

  // Secure storage (dùng chung)
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  AuthService(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl, // ví dụ: http://192.168.1.67:8000
            headers: {'Accept': 'application/json'},
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            // Cho phép đọc body lỗi (4xx) để trích xuất message
            validateStatus: (code) => code != null && code >= 200 && code < 500,
          ),
        ) {
    // Interceptor: luôn thêm Authorization nếu có token lưu trong SecureStorage
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          final t = await _storage.read(key: _tokenKey);
          if (t != null && t.isNotEmpty && t != 'null') {
            o.headers['Authorization'] = 'Bearer $t';
          }
          h.next(o);
        },
      ),
    );
  }

  // ===== Token helpers (static) =====
  static Future<void> saveToken(String t) =>
      _storage.write(key: _tokenKey, value: t);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // ===== Token helpers (INSTANCE) — để Provider gọi lấy token hiện tại =====
  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  // (tuỳ chọn) nếu muốn dùng instance thay vì static:
  Future<void> saveTokenInstance(String t) async =>
      _storage.write(key: _tokenKey, value: t);
  Future<void> clearTokenInstance() async =>
      _storage.delete(key: _tokenKey);

  // ===== Helpers: trích xuất token & user =====
  String? _extractToken(dynamic data) {
    if (data is Map) {
      if (data['token'] is String) return data['token'] as String;
      if (data['access_token'] is String) return data['access_token'] as String;
      if (data['data'] is Map) {
        final m = data['data'] as Map;
        if (m['token'] is String) return m['token'] as String;
        if (m['access_token'] is String) return m['access_token'] as String;
      }
    }
    return null;
  }

  Map<String, dynamic> _extractUser(dynamic data) {
    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user'] as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  String _readErr(DioException e, {required String fallback}) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    } catch (_) {}
    return fallback;
  }

  // ===== API calls =====

  /// Đăng ký: trả về user; nếu backend trả token thì sẽ được lưu vào storage
  Future<Map<String, dynamic>> register(
      String name, String email, String pass) async {
    try {
      final res = await _dio.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': pass,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final token = _extractToken(res.data);
        if (token != null && token.isNotEmpty) {
          await saveToken(token); // lưu để interceptor dùng
        }
        return _extractUser(res.data);
      }
      throw Exception('Đăng ký thất bại: ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_readErr(e, fallback: 'Đăng ký thất bại'));
    }
  }

  /// Đăng nhập: lưu token (bắt buộc) và trả về user
  Future<Map<String, dynamic>> login(String email, String pass) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': pass,
      });
      if (res.statusCode == 200) {
        final token = _extractToken(res.data);
        if (token == null || token.isEmpty) {
          throw Exception('Máy chủ không trả token');
        }
        await saveToken(token); // lưu để interceptor thêm Authorization tự động
        return _extractUser(res.data);
      }
      throw Exception('Đăng nhập thất bại: ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_readErr(e, fallback: 'Đăng nhập thất bại'));
    }
  }

  /// Lấy thông tin người dùng hiện tại
  Future<Map<String, dynamic>> me() async {
    try {
      final res = await _dio.get('/api/auth/user');
      if (res.statusCode == 200) return _extractUser(res.data);
      throw Exception('Không lấy được hồ sơ: ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_readErr(e, fallback: 'Lấy thông tin người dùng thất bại'));
    }
  }

  /// Đăng xuất: gọi API (nếu có) rồi xoá token lưu trữ
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {
      // ignore lỗi mạng khi logout
    } finally {
      await clearToken();
    }
  }

  /// Cập nhật tên hiển thị
  Future<Map<String, dynamic>?> updateName(String name) async {
    try {
      final res = await _dio.put('/api/auth/user', data: {'name': name});
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['user'] is Map) {
          return Map<String, dynamic>.from(data['user'] as Map);
        }
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } on DioException catch (e) {
      throw Exception(_readErr(e, fallback: 'Không thể cập nhật tên'));
    }
  }

  /// Đổi mật khẩu
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post('/api/auth/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      if (res.statusCode == 200 || res.statusCode == 204) return true;
      final d = res.data;
      if (d is Map && d['success'] == true) return true;
      return false;
    } on DioException catch (e) {
      final msg = _readErr(e, fallback: 'Đổi mật khẩu thất bại');
      throw Exception(msg);
    }
  }
}
