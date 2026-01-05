import 'dart:convert';
import 'package:http/http.dart' as http;

import 'category_model.dart';

class CategoryService {
  /// Ví dụ: baseUrl = 'http://192.168.1.67:8000/api'
  final String baseUrl;

  String _token;
  final String path; // REST: /categories
  final Duration timeout;

  CategoryService({
    required this.baseUrl,
    String token = '',
    this.path = '/categories',
    this.timeout = const Duration(seconds: 15),
  }) : _token = token;

  // ========== Token ==========
  String get token => _token;
  set token(String v) => _token = v;
  void updateToken(String token) => _token = token;

  // ========== Headers ==========
  Map<String, String> get _headers {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token.isNotEmpty) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  // ========== Helpers ==========
  Uri _u([String extra = '']) {
    final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    final e = (extra.isNotEmpty && !extra.startsWith('/')) ? '/$extra' : extra;
    return Uri.parse('$b$p$e');
  }

  Never _throwHttp(int code, String body) {
    final isAuth = code == 401 || code == 403;
    final msg = isAuth
        ? 'Bạn chưa đăng nhập hoặc không có quyền (HTTP $code).'
        : 'Lỗi máy chủ (HTTP $code): $body';
    throw Exception(msg);
  }

  List<Map<String, dynamic>> _asListOfMap(dynamic json) {
    if (json is List) {
      return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (json is Map) {
      if (json['data'] is List) {
        return (json['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (json['items'] is List) {
        return (json['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return const [];
  }

  Map<String, dynamic>? _asSingleMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map && json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    if (json is List && json.isNotEmpty && json.first is Map) {
      return Map<String, dynamic>.from(json.first as Map);
    }
    return null;
  }

  void _ensureAuthed() {
    if (_token.isEmpty) {
      throw Exception('Thiếu token xác thực (Authorization Bearer).');
    }
  }

  // ========== APIs ==========

  /// GET /categories
  Future<List<Category>> getCategories() async {
    _ensureAuthed();

    final res = await http.get(_u(), headers: _headers).timeout(timeout);
    if (res.statusCode != 200) {
      _throwHttp(res.statusCode, res.body);
    }

    final decoded = jsonDecode(res.body);
    final list = _asListOfMap(decoded);
    if (list.isNotEmpty) return list.map(Category.fromJson).toList();

    final one = _asSingleMap(decoded);
    if (one != null) return [Category.fromJson(one)];

    return const [];
  }

  /// POST /categories
  /// Gửi cả 'ten' và 'name' để tương thích nhiều backend.
  Future<Category> createCategory(String name) async {
    _ensureAuthed();

    final body = jsonEncode({'ten': name, 'name': name});

    final res = await http
        .post(_u(), headers: _headers, body: body)
        .timeout(timeout);

    if (res.statusCode != 201 && res.statusCode != 200) {
      _throwHttp(res.statusCode, res.body);
    }

    final decoded = jsonDecode(res.body);
    final map = _asSingleMap(decoded);
    if (map != null) return Category.fromJson(map);

    final list = _asListOfMap(decoded);
    if (list.isNotEmpty) return Category.fromJson(list.first);

    throw Exception('Phản hồi không hợp lệ khi tạo danh mục: $decoded');
  }

  /// PUT /categories/{id}
  /// Fallback: PUT -> PATCH -> POST + _method=PUT
  Future<Category> updateCategory({
    required int id,
    required String name,
  }) async {
    _ensureAuthed();

    final payload = jsonEncode({'ten': name, 'name': name});

    Future<http.Response> _tryPut() =>
        http.put(_u('$id'), headers: _headers, body: payload).timeout(timeout);

    var res = await _tryPut();

    if (res.statusCode == 405) {
      // thử PATCH
      res = await http
          .patch(_u('$id'), headers: _headers, body: payload)
          .timeout(timeout);
    }
    if (res.statusCode == 405) {
      // fallback POST + _method=PUT (Laravel style)
      res = await http
          .post(_u('$id'),
              headers: _headers,
              body: jsonEncode({'ten': name, 'name': name, '_method': 'PUT'}))
          .timeout(timeout);
    }

    if (res.statusCode != 200) {
      _throwHttp(res.statusCode, res.body);
    }

    final decoded = jsonDecode(res.body);
    final map = _asSingleMap(decoded);
    if (map != null) return Category.fromJson(map);

    throw Exception('Phản hồi không hợp lệ khi cập nhật danh mục: $decoded');
  }

  /// DELETE /categories/{id}
  /// Fallback: DELETE -> POST + _method=DELETE
  Future<void> deleteCategory(int id) async {
    _ensureAuthed();

    var res = await http.delete(_u('$id'), headers: _headers).timeout(timeout);

    if (res.statusCode == 405) {
      // fallback POST + _method=DELETE
      res = await http
          .post(_u('$id'),
              headers: _headers, body: jsonEncode({'_method': 'DELETE'}))
          .timeout(timeout);
    }

    if (res.statusCode != 200 && res.statusCode != 204) {
      _throwHttp(res.statusCode, res.body);
    }
  }
}
