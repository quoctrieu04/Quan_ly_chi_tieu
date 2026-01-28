import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'https://thuchi.itcctv-soft.com';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$_baseUrl/api/',
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60), // ✅ FIX TIMEOUT
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    /// ✅ Tự động gắn Bearer token + log lỗi
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          debugPrint('❌ API error: ${e.requestOptions.method} ${e.requestOptions.path}');
          debugPrint('❌ Message: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  // ================= TOKEN =================

  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: 'access_token');
  }

  Future<void> clearToken() async {
    await _storage.deleteAll();
  }

  // ================= AUTH =================

  /// 🔐 Login
  Future<void> login(String email, String password) async {
    final res = await _dio.post(
      'auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final token = res.data['access_token'];
    if (token == null || token.toString().isEmpty) {
      throw Exception('Login failed: access_token missing');
    }

    await _saveToken(token);
  }

  /// 👤 Lấy user hiện tại
  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('auth/user');
    return Map<String, dynamic>.from(res.data);
  }

  /// 📝 Đăng ký
  Future<void> register(String name, String email, String pass) async {
    final res = await _dio.post(
      'auth/register',
      data: {
        'name': name,
        'email': email,
        'password': pass,
      },
    );

    final token = res.data['access_token'];
    if (token != null && token.toString().isNotEmpty) {
      await _saveToken(token);
    }
  }

  /// 🔁 Logout
  Future<void> logout() async {
    try {
      await _dio.post('auth/logout');
    } catch (_) {}
    await clearToken();
  }

  /// ✏️ Cập nhật tên
  Future<Map<String, dynamic>> updateName(String newName) async {
    final res = await _dio.put(
      'auth/user',
      data: {'name': newName},
    );

    return Map<String, dynamic>.from(res.data);
  }

  /// 🔒 Đổi mật khẩu
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      'auth/change-password',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
    return true;
  }
}
