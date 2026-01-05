import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  static const _k = 'access_token';
  static const _s = FlutterSecureStorage();

  static Future<void> saveToken(String t) => _s.write(key: _k, value: t);
  static Future<String?> readToken() => _s.read(key: _k);
  static Future<void> clear() => _s.delete(key: _k);
}
