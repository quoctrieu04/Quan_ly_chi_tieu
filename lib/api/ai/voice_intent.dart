import 'dart:convert';

import 'package:chitieu/api/category/category_provider.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';

enum VoiceIntentType { spend, income, unknown }

class VoiceIntent {
  final VoiceIntentType type;
  final String? note;
  final int? amount;
  final String? walletName;
  final String? categoryName;

  VoiceIntent({
    required this.type,
    this.note,
    this.amount,
    this.walletName,
    this.categoryName,
  });

  @override
  String toString() {
    return 'VoiceIntent(type: $type, note: $note, amount: $amount, wallet: $walletName, cat: $categoryName)';
  }

  VoiceIntent copyWith({
    VoiceIntentType? type,
    String? note,
    int? amount,
    String? walletName,
    String? categoryName,
  }) {
    return VoiceIntent(
      type: type ?? this.type,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      walletName: walletName ?? this.walletName,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}

class VoiceIntentParser {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyDGXMVaN6EL_Irb4VmvZscn647WDzfnDu8',
  );

  static const List<String> _candidateModels = <String>[
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  final RegExp _moneyRegex =
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(k|nghìn|ngàn|triệu|tr|tỷ|tỉ|đ|đồng)?');

  final RegExp _walletRegex = RegExp(r'(ví|bằng|vào|từ)\s+([a-zA-Z0-9]+)');

  VoiceIntentParser();

  List<String> _getUserCategories(BuildContext context) {
    try {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      final result = <String>[];

      for (final item in provider.items) {
        final name = item.name.trim();
        if (name.isNotEmpty && !result.contains(name)) {
          result.add(name);
        }
      }

      debugPrint('DEBUG: List Cat: ${result.join(', ')}');
      return result;
    } catch (e) {
      debugPrint('DEBUG: Load categories error: $e');
      return <String>[];
    }
  }

  Future<VoiceIntent> parse(String text, {BuildContext? context}) async {
    final lower = text.toLowerCase().trim();

    List<String> userCategories = <String>[];
    if (context != null) {
      userCategories = _getUserCategories(context);
    }

    if (_geminiApiKey.isNotEmpty && _geminiApiKey != 'YOUR_API_KEY_HERE') {
      final geminiIntent = await _parseWithGemini(lower, userCategories);

      if (geminiIntent != null) {
        final resolvedCategory = _resolveCategoryName(
          categories: userCategories,
          aiSuggested: geminiIntent.categoryName,
          note: geminiIntent.note,
          originalText: lower,
        );

        debugPrint('Gemini Cat raw: ${geminiIntent.categoryName}');
        debugPrint('Gemini Cat resolved: $resolvedCategory');

        return geminiIntent.copyWith(categoryName: resolvedCategory);
      }

      debugPrint('⚠️ Gemini lỗi hoặc không parse được. Fallback về regex + local match.');
    } else {
      debugPrint('⚠️ Chưa cấu hình GEMINI_API_KEY. Fallback về regex + local match.');
    }

    final fallbackIntent = _fallbackParse(lower);
    final resolvedCategory = _resolveCategoryName(
      categories: userCategories,
      aiSuggested: null,
      note: fallbackIntent.note,
      originalText: lower,
    );

    debugPrint('Fallback Cat resolved: $resolvedCategory');

    return fallbackIntent.copyWith(categoryName: resolvedCategory);
  }

  Future<VoiceIntent?> _parseWithGemini(
    String input,
    List<String> categories,
  ) async {
    final catListString = categories.isNotEmpty
        ? 'Danh sách Danh mục hiện có của user: [${categories.join(', ')}].'
        : 'User chưa có danh mục nào.';

    final prompt = '''
Bạn là một trợ lý tài chính tiếng Việt siêu nhạy bén.
$catListString

Người dùng đã đọc một câu bằng giọng nói, có thể bị lẫn tạp âm hoặc lỗi nhận diện.
Ví dụ: "ờ 03 50.000đ" thì số tiền thực sự là 50000.

Nhiệm vụ:
1. BỎ QUA số rác hoặc tạp âm ở đầu câu.
2. Tách số tiền thực tế thành amount (số nguyên, không dấu phẩy).
3. Tách ghi chú ngắn gọn vào note (ví dụ: "bánh tráng trộn", "áo quần").
4. Nếu đoán được loại giao dịch thì trả "spend" hoặc "income".
5. Nếu có danh mục user, BẮT BUỘC CHỌN 1 categoryName phù hợp nhất từ danh sách hiện có, dù chỉ liên quan một phần.
6. categoryName phải viết y chang tên danh mục trong danh sách được cung cấp.
7. walletName chỉ điền khi thật sự rõ.
8. Không trả markdown, không giải thích, chỉ trả đúng 1 object JSON.

Trả đúng định dạng JSON:
{
  "type": "spend" | "income",
  "amount": 50000,
  "note": "ăn sáng",
  "walletName": null,
  "categoryName": "ăn uống"
}

Văn bản STT: "$input"
''';

    Object? lastError;

    for (final modelName in _candidateModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _geminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
          ),
        );

        final response = await model
            .generateContent(<Content>[Content.text(prompt)])
            .timeout(const Duration(seconds: 15));

        final rawText = response.text?.trim() ?? '';
        debugPrint('🤖 Gemini [$modelName] Response: $rawText');

        final jsonText = _extractJsonObject(rawText);
        if (jsonText == null || jsonText.isEmpty) {
          debugPrint('⚠️ Gemini [$modelName] không trả JSON hợp lệ.');
          continue;
        }

        final dynamic decoded = json.decode(jsonText);
        if (decoded is! Map) {
          throw const FormatException('Gemini không trả về JSON object.');
        }

        final jsonMap = Map<String, dynamic>.from(decoded);
        return _mapJsonToIntent(jsonMap);
      } catch (e) {
        lastError = e;
        debugPrint('⚠️ Gemini [$modelName] lỗi: $e');
      }
    }

    if (lastError != null) {
      debugPrint('⚠️ Tất cả model Gemini đều lỗi: $lastError');
    }

    // QUAN TRỌNG:
    // Trả null để parse() tự rơi xuống fallback regex,
    // không return VoiceIntent lỗi làm hỏng amount/type.
    return null;
  }

  VoiceIntent _mapJsonToIntent(Map<String, dynamic> jsonMap) {
    final typeRaw = jsonMap['type']?.toString().trim().toLowerCase();

    VoiceIntentType type = VoiceIntentType.unknown;
    if (typeRaw == 'spend') type = VoiceIntentType.spend;
    if (typeRaw == 'income') type = VoiceIntentType.income;

    int? amount;
    final rawAmt = jsonMap['amount'];

    if (rawAmt is int) {
      amount = rawAmt;
    } else if (rawAmt is double) {
      amount = rawAmt.toInt();
    } else if (rawAmt != null) {
      final digits = rawAmt.toString().replaceAll(RegExp(r'[^0-9]'), '');
      amount = digits.isEmpty ? null : int.tryParse(digits);
    }

    return VoiceIntent(
      type: type,
      note: _normalizeNullableString(jsonMap['note']),
      amount: amount,
      walletName: _normalizeNullableString(jsonMap['walletName']),
      categoryName: _normalizeNullableString(jsonMap['categoryName']),
    );
  }

  String? _normalizeNullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final lower = text.toLowerCase();
    if (lower == 'null' || lower == 'unknown' || lower == 'không rõ') {
      return null;
    }

    return text;
  }

  String? _extractJsonObject(String rawText) {
    if (rawText.trim().isEmpty) return null;

    var text = rawText.trim();

    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }

    final startIndex = text.indexOf('{');
    final endIndex = text.lastIndexOf('}');

    if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
      return null;
    }

    return text.substring(startIndex, endIndex + 1);
  }

  VoiceIntent _fallbackParse(String lower) {
    int? amount;
    final match = _moneyRegex.firstMatch(lower);

    if (match != null) {
      var raw = match.group(1)!.replaceAll(RegExp(r'[^\d]'), '');
      amount = int.tryParse(raw);

      final unit = match.group(2);
      if (unit != null && amount != null) {
        if (unit.contains('tỷ') || unit.contains('tỉ')) {
          amount *= 1000000000;
        }
        if (unit.contains('tr') || unit.contains('triệu')) {
          amount *= 1000000;
        }
        if (unit.contains('k') ||
            unit.contains('nghìn') ||
            unit.contains('ngàn')) {
          amount *= 1000;
        }
      }
    }

    String? walletName;
    final walletMatch = _walletRegex.firstMatch(lower);
    if (walletMatch != null) {
      walletName = walletMatch.group(2);
    }

    VoiceIntentType type = VoiceIntentType.unknown;
    if (lower.contains('mua') ||
        lower.contains('ăn') ||
        lower.contains('uong') ||
        lower.contains('uống') ||
        lower.contains('chi') ||
        lower.contains('trả') ||
        lower.contains('áo') ||
        lower.contains('ao') ||
        lower.contains('quần') ||
        lower.contains('quan')) {
      type = VoiceIntentType.spend;
    } else if (lower.contains('lương') ||
        lower.contains('thưởng') ||
        lower.contains('thu') ||
        lower.contains('nhận')) {
      type = VoiceIntentType.income;
    }

    String note = lower;
    note = note.replaceAll(_moneyRegex, '');
    if (walletName != null && walletName.isNotEmpty) {
      note = note.replaceAll(walletName, '');
    }
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();

    return VoiceIntent(
      type: type,
      note: note.isNotEmpty ? note : null,
      amount: amount,
      walletName: walletName,
      categoryName: null,
    );
  }

  String _normalizeText(String input) {
    return removeDiacritics(input.toLowerCase())
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _tokenize(String input) {
    final normalized = _normalizeText(input);
    if (normalized.isEmpty) return <String>[];
    return normalized
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _resolveCategoryName({
    required List<String> categories,
    String? aiSuggested,
    String? note,
    required String originalText,
  }) {
    if (categories.isEmpty) return null;

    final normalizedMap = <String, String>{};
    for (final category in categories) {
      final normalized = _normalizeText(category);
      if (normalized.isNotEmpty && !normalizedMap.containsKey(normalized)) {
        normalizedMap[normalized] = category;
      }
    }

    final normalizedAi = _normalizeText(aiSuggested ?? '');
    if (normalizedAi.isNotEmpty) {
      if (normalizedMap.containsKey(normalizedAi)) {
        return normalizedMap[normalizedAi];
      }

      for (final entry in normalizedMap.entries) {
        if (entry.key == normalizedAi ||
            entry.key.contains(normalizedAi) ||
            normalizedAi.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    final combinedText = [
      originalText,
      note ?? '',
      aiSuggested ?? '',
    ].where((e) => e.trim().isNotEmpty).join(' ');

    final normalizedText = _normalizeText(combinedText);

    String? directMatched;
    int directScore = -1;

    for (final category in categories) {
      final normalizedCat = _normalizeText(category);
      if (normalizedCat.isEmpty) continue;

      if (normalizedText.contains(normalizedCat)) {
        if (normalizedCat.length > directScore) {
          directScore = normalizedCat.length;
          directMatched = category;
        }
      }
    }

    if (directMatched != null) {
      return directMatched;
    }

    String? bestCategory;
    int bestScore = 0;

    for (final category in categories) {
      final score = _scoreCategoryAgainstText(category, combinedText);
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    }

    if (bestScore > 0) {
      return bestCategory;
    }

    return null;
  }

  int _scoreCategoryAgainstText(String category, String text) {
    final normalizedCategory = _normalizeText(category);
    final normalizedText = _normalizeText(text);

    if (normalizedCategory.isEmpty || normalizedText.isEmpty) {
      return 0;
    }

    int score = 0;

    final categoryTokens = _tokenize(category).toSet();
    final textTokens = _tokenize(text).toSet();

    for (final token in categoryTokens) {
      if (token.length >= 2 && textTokens.contains(token)) {
        score += 2;
      }
    }

    final hintKeywords = _hintKeywordsForCategory(category);
    for (final keyword in hintKeywords) {
      final normalizedKeyword = _normalizeText(keyword);
      if (normalizedKeyword.isNotEmpty &&
          normalizedText.contains(normalizedKeyword)) {
        score += 3;
      }
    }

    return score;
  }

  List<String> _hintKeywordsForCategory(String category) {
    final cat = _normalizeText(category);
    final result = <String>[];

    if (cat.contains('an uong') ||
        cat.contains('am thuc') ||
        cat.contains('do an') ||
        cat.contains('do uong') ||
        cat.contains('an vat') ||
        cat.contains('thuc pham')) {
      result.addAll([
        'an',
        'uong',
        'com',
        'pho',
        'bun',
        'chao',
        'hu tieu',
        'banh',
        'banh mi',
        'banh trang',
        'banh trang tron',
        'tra sua',
        'tra',
        'sua',
        'ca phe',
        'cafe',
        'nuoc',
        'do an',
        'do uong',
        'an vat',
        'lau',
        'oc',
        'do nhau',
      ]);
    }

    if (cat.contains('sam') ||
        cat.contains('mua sam') ||
        cat.contains('shopping') ||
        cat.contains('quan ao') ||
        cat.contains('my pham')) {
      result.addAll([
        'mua',
        'shopping',
        'quan ao',
        'giay',
        'dep',
        'tui',
        'my pham',
        'ao',
        'quan',
        'vay',
        'dam',
        'tui xach',
        'ao quan',
      ]);
    }

    if (cat.contains('tien nha') ||
        cat.contains('nha') ||
        cat.contains('tro') ||
        cat.contains('phong')) {
      result.addAll([
        'tien nha',
        'tien tro',
        'thue nha',
        'thue phong',
        'dien',
        'nuoc',
        'wifi',
        'phong',
        'tro',
        'mang',
      ]);
    }

    if (cat.contains('xang') ||
        cat.contains('di lai') ||
        cat.contains('giao thong') ||
        cat.contains('di chuyen') ||
        cat.contains('xe')) {
      result.addAll([
        'xang',
        'do xang',
        'grab',
        'taxi',
        'xe om',
        'gui xe',
        've xe',
        'bus',
        'di lai',
        'di chuyen',
        'sua xe',
      ]);
    }

    if (cat.contains('hoc') ||
        cat.contains('giao duc') ||
        cat.contains('hoc tap')) {
      result.addAll([
        'hoc',
        'hoc phi',
        'sach',
        'vo',
        'tai lieu',
        'khoa hoc',
        'but',
      ]);
    }

    if (cat.contains('luong') ||
        cat.contains('thu nhap') ||
        cat.contains('thu')) {
      result.addAll([
        'luong',
        'thuong',
        'thu',
        'nhan tien',
        'duoc cho',
        'hoan tien',
        'ban hang',
      ]);
    }

    return result;
  }
}