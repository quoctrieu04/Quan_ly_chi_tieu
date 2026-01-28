import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/api/category/category_model.dart' as cm;
import 'package:chitieu/core/refreshable.dart';

class CategoryProvider extends ChangeNotifier implements Refreshable {
  final Dio _dio;
  final AuthProvider auth;

  String _currentType = 'out';
  bool loading = false;

  List<cm.Category> _items = [];
  List<cm.Category> get items => _items;

  CategoryProvider(this._dio, this.auth);

  void clear() {
    _items = [];
    notifyListeners();
  }

  // ---- helpers --------------------------------------------------------------

  dynamic _decodeBody(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      if (body['data'] is List) return body['data'] as List;
      if (body['items'] is List) return body['items'] as List;
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }

  // ---- API ------------------------------------------------------------------

  /// 📂 Lấy danh sách danh mục
  Future<void> fetchAll({String type = 'out'}) async {
    _currentType = type;

    if (!auth.isAuthenticated) {
      debugPrint('CategoryProvider.fetchAll: skip (not authenticated)');
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final r = await _dio.get(
        '/categories',
        queryParameters: {'type': type},
      );

      final body = _decodeBody(r.data);
      final rawList = _extractList(body);

      _items = rawList
          .map((e) => cm.Category.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (e) {
      debugPrint('❌ CategoryProvider.fetchAll lỗi: $e');
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refresh() => fetchAll(type: _currentType);

  /// ➕ Tạo danh mục mới
  Future<cm.Category> create(String name, {String type = 'out'}) async {
    if (!auth.isAuthenticated) {
      throw Exception('Chưa đăng nhập');
    }

    final r = await _dio.post(
      '/categories',
      data: jsonEncode({
        'loai': type == 'in' ? 'thu' : 'chi',
        'title': name,
      }),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final body = _decodeBody(r.data);
    final map = _extractMap(body);

    if (map.isEmpty) {
      throw Exception('Phản hồi không hợp lệ từ server khi tạo danh mục');
    }

    final cat = cm.Category.fromJson(map);
    _items.add(cat);
    notifyListeners();
    return cat;
  }

  /// ✏️ Cập nhật danh mục
  Future<void> update({
    required int id,
    required String name,
    String type = 'out',
  }) async {
    if (!auth.isAuthenticated) {
      throw Exception('Chưa đăng nhập');
    }

    await _dio.put(
      '/categories/$id',
      data: jsonEncode({'title': name, 'type': type}),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final i = _items.indexWhere((e) => e.id == id);
    if (i != -1) {
      _items[i] = cm.Category(id: id, name: name, type: type);
      notifyListeners();
    }
  }

  /// ❌ Xóa danh mục
  Future<void> delete({required int id}) async {
    if (!auth.isAuthenticated) {
      throw Exception('Chưa đăng nhập');
    }

    await _dio.delete('/categories/$id');
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
