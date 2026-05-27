import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLoginException implements Exception {
  final String? emailError;
  final String? passwordError;
  final String? message;

  const AuthLoginException({
    this.emailError,
    this.passwordError,
    this.message,
  });

  @override
  String toString() => message ?? 'Đăng nhập thất bại';
}

class AuthRegisterException implements Exception {
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? message;

  const AuthRegisterException({
    this.nameError,
    this.emailError,
    this.passwordError,
    this.message,
  });

  @override
  String toString() => message ?? 'Đăng ký thất bại';
}

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
  String? _asText(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  String? _extractFieldError(dynamic errors, List<String> fieldNames) {
    if (errors is! Map) return null;
    for (final field in fieldNames) {
      final raw = errors[field];
      if (raw is List && raw.isNotEmpty) {
        return _asText(raw.first);
      }
      final text = _asText(raw);
      if (text != null) return text;
    }
    return null;
  }

  Never _throwLoginException(Response<dynamic> res) {
    final data = res.data is Map<String, dynamic>
        ? Map<String, dynamic>.from(res.data as Map<String, dynamic>)
        : <String, dynamic>{};

    final message = _asText(data['message']) ?? _asText(data['error']);
    final errors = data['errors'];

    final emailError =
        _extractFieldError(errors, const ['email', 'username', 'account']);
    final passwordError = _extractFieldError(errors, const ['password']);

    if (res.statusCode == 401) {
      final lower = (message ?? '').toLowerCase();
      if (emailError == null &&
          (lower.contains('email') ||
              lower.contains('tài khoản') ||
              lower.contains('tai khoan') ||
              lower.contains('account') ||
              lower.contains('user'))) {
        throw AuthLoginException(
          emailError: message,
          message: message ?? 'Đăng nhập thất bại',
        );
      } else if (passwordError == null &&
          (lower.contains('mật khẩu') ||
              lower.contains('mat khau') ||
              lower.contains('password'))) {
        throw AuthLoginException(
          passwordError: message,
          message: message ?? 'Đăng nhập thất bại',
        );
      }
    }

    throw AuthLoginException(
      emailError: emailError,
      passwordError: passwordError,
      message: message ?? 'Đăng nhập thất bại',
    );
  }

  /// 🔐 Login
  Future<void> login(String email, String password) async {
    final res = await _dio.post(
      'auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    if ((res.statusCode ?? 500) >= 400) {
      _throwLoginException(res);
    }

    final token = res.data['access_token'];
    if (token == null || token.toString().isEmpty) {
      throw const AuthLoginException(
        message: 'Đăng nhập thất bại',
      );
    }

    await _saveToken(token);
  }

  /// 🌍 Đăng nhập bằng Google
  Future<void> loginWithGoogle(String idToken) async {
    final res = await _dio.post(
      'auth/google',
      data: {
        'id_token': idToken,
      },
    );

    final token = res.data['access_token'];
    if (token == null || token.toString().isEmpty) {
      throw Exception('Google Login failed: access_token missing');
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

    if ((res.statusCode ?? 500) >= 400) {
      final data = res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map<String, dynamic>)
          : <String, dynamic>{};
      final errors = data['errors'];

      throw AuthRegisterException(
        nameError: _extractFieldError(errors, const ['name']),
        emailError: _extractFieldError(errors, const ['email']),
        passwordError: _extractFieldError(errors, const ['password']),
        message: _asText(data['message']) ??
            _asText(data['error']) ??
            'Đăng ký thất bại',
      );
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
