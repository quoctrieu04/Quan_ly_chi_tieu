import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diacritic/diacritic.dart';

/// Bộ nhớ học synonym (từ nói) CHỈ dành cho DANH MỤC.
/// Ví và Income KHÔNG học vào đây để tránh nhiễu.
///
/// Format lưu:
/// {
///   "keyword": "categoryName"
/// }
class VoiceSynonymStore {
  static const _kKey = 'voice_synonyms_v3';
  Map<String, String> _map = {}; // unsign(keyword) -> categoryName

  /// Chuẩn hóa chuỗi (remove dấu + trim)
  String _u(String s) => removeDiacritics(s.toLowerCase().trim().replaceAll(
              RegExp(r'[-_]'),
              '') // ← SỬA: Xóa dấu gạch thay vì thay bằng space
          )
      .replaceAll(RegExp(r'\s+'), ' ');

  /// 🔹 Load data từ SharedPreferences
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kKey);
    if (raw == null || raw.isEmpty) return;

    try {
      _map = Map<String, String>.from(json.decode(raw));
    } catch (_) {
      _map = {};
    }
  }

  /// 🔹 Save data
  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKey, json.encode(_map)); // Lưu dữ liệu vào SharedPreferences
  }

  // ============================================================
  // 🔍 TÌM DANH MỤC theo câu nói
  // ============================================================

  /// Match theo từ khoá đã học (ưu tiên từ dài nhất)
  String? matchCategoryName(String utterance) {
    final u = _u(utterance);
    String? best;
    int bestLen = 0;

    for (final entry in _map.entries) {
      final syn = entry.key;
      final cat = entry.value;

      // Sử dụng fuzzy matching: kiểm tra xem từ khóa có chứa từ đã học không
      if (u.contains(syn) || syn.contains(u)) {
        if (syn.length > bestLen) {
          bestLen = syn.length;
          best = cat; // Lưu danh mục tốt nhất
        }
      }
    }

    return best; // Trả về danh mục phù hợp nhất
  }

  // ============================================================
  // 🧠 HỌC DỮ LIỆU AN TOÀN
  // ============================================================

  /// Chỉ học khi danh mục đã xác định rõ (do *người dùng chọn*)
  Future<void> learnFromUtterance(String utterance, String category) async {
    if (utterance.trim().isEmpty) return;

    final normalized = _u(utterance);

    // ✅ 1) Học CẢ CÂU gốc đã chuẩn hóa
    if (normalized.length >= 3) {
      _map[normalized] = category;
    }

    // ✅ 2) Học từng từ khóa
    final kws = _extractKeywordsSafe(utterance);

    for (final kw in kws) {
      final key = _u(kw);
      if (key.length < 3) continue;
      _map[key] = category;
    }

    await _save();  // Lưu lại sau khi học
    print("🧠 Đã học: \"$normalized\" + ${kws.length} từ → \"$category\"");
    debugPrintAll();  // In danh sách từ học
  }

  // ============================================================
  // ✂️ TÁCH TỪ KHÓA AN TOÀN (ĐÃ FIX HOÀN TOÀN)
  // ============================================================

  List<String> _extractKeywordsSafe(String utterance) {
    var u = _u(utterance);

    // Loại số tiền
    u = u.replaceAll(RegExp(r'\b\d+[.,]?\d*\b'), ' ');

    // Loại ngày tháng
    u = u.replaceAll(RegExp(r'\b\d{1,2}[/-]\d{1,2}([/-]\d{4})?\b'), ' ');

    // Từ dừng (stop words)
    final stop = <String>{
      'chi', 'tieu', 'mua', 'tra', 'thu', 'nhan', 'nap', 'duoc', 'vao',
      'vi', 'cho', 'tai', 'di', 've', 'voi', 'an', 'uong', 'banh', 'mon',
      'dong', 'la'
    };

    final parts = u.split(RegExp(r'[^a-z0-9]+')).where((x) => x.isNotEmpty);

    final kws = <String>[];

    for (final w in parts) {
      if (w.length < 3) continue;  // Loại bỏ các từ quá ngắn
      if (stop.contains(w)) continue;  // Loại bỏ các từ dừng

      kws.add(w);  // Thêm từ khóa vào danh sách
    }

    return kws;
  }

  // ============================================================
  // DEBUG HELPER
  // ============================================================

  Future<void> clearAll() async {
    _map.clear();
    await _save();
  }

  void debugPrintAll() {
    print("------ SYNO MAP -------");
    if (_map.isEmpty) print("(empty)");
    _map.forEach((k, v) => print('"$k" → "$v"'));
    print("------------------------");
  }
}
