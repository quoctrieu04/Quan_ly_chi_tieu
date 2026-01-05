import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:chitieu/core/voice/voice_synonym_store.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:diacritic/diacritic.dart';

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
  String toString() =>
      'VoiceIntent(type: $type, note: $note, amount: $amount, wallet: $walletName, cat: $categoryName)';
}

class VoiceIntentParser {
  final VoiceSynonymStore _synonyms = VoiceSynonymStore();

  // Regex nhận diện tiền
  final _moneyRegex =
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(k|nghìn|ngàn|triệu|tr|đ|đồng)?');

  // Regex nhận diện ví
  final _walletRegex = RegExp(r'(ví|bằng|vào|từ)\s+([a-zA-Z0-9]+)');

  // Dữ liệu nạp từ file JSON
  List<String> incomeWords = [];
  List<String> spendWords = [];
  Map<String, String> categoryMap = {};
  Map<String, String> intentMap = {};

  VoiceIntentParser() {
    // _synonyms.load();
    _loadVoiceData();
  }

  Future<void> _loadVoiceData() async {
    try {
      final keywordJson =
          await rootBundle.loadString('assets/voice_keywords.json');
      final synonymJson =
          await rootBundle.loadString('assets/default_voice_synonyms.json');

      final keywordData = json.decode(keywordJson);
      final synonymData = json.decode(synonymJson);

      incomeWords = List<String>.from(keywordData['income']);
      spendWords = List<String>.from(keywordData['spend']);
      categoryMap = Map<String, String>.from(synonymData['category']);
      intentMap = Map<String, String>.from(synonymData['intent']);

      debugPrint("✅ Voice JSON data loaded successfully");
    } catch (e) {
      debugPrint("⚠️ Error loading JSON data: $e");
    }
  }

  /* =============================================
   * Lấy danh mục user trực tiếp từ Provider
   * ============================================= */
  List<String> _getUserCategories(BuildContext context) {
    try {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      return provider.items
          .where((c) => c.type == 'out')
          .map((c) => removeDiacritics(c.name.toLowerCase()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /* =============================================
   * MATCH danh mục theo user's categories
   * ============================================= */
  String? _matchCategory(String text, List<String> cats) {
    final clean = removeDiacritics(text.toLowerCase());

    // 1) Từ đã học
    final learned = _synonyms.matchCategoryName(clean);
    if (learned != null) return learned;

    // 2) Tra trong file JSON
    for (final entry in categoryMap.entries) {
      if (clean.contains(removeDiacritics(entry.key))) {
        return entry.value;
      }
    }

    // 3) Match theo user category
    for (final c in cats) {
      if (clean == c || clean.contains(c) || c.contains(clean)) return c;
    }

    // 4) Fuzzy
    for (final c in cats) {
      if (clean.split(" ").any((w) => c.contains(w))) return c;
    }

    return null;
  }

  /* =============================================
   * PHÂN LOẠI THU/CHI
   * ============================================= */
  VoiceIntentType _detectType(String clean) {
    final normalized = removeDiacritics(clean.toLowerCase());

    // 1) Từ trong file JSON intent
    for (final entry in intentMap.entries) {
      if (normalized.contains(removeDiacritics(entry.key))) {
        if (entry.value == "income") return VoiceIntentType.income;
        if (entry.value == "spend") return VoiceIntentType.spend;
      }
    }

    // 2) Danh sách JSON
    if (incomeWords.any((w) => normalized.contains(removeDiacritics(w)))) {
      return VoiceIntentType.income;
    }
    if (spendWords.any((w) => normalized.contains(removeDiacritics(w)))) {
      return VoiceIntentType.spend;
    }

    // 3) Danh sách mặc định (fallback)
    const defaultIncome = [
      "nhan",
      "duoc",
      "cho",
      "luong",
      "thuong",
      "tien ve",
      "vao vi"
    ];
    const defaultSpend = [
      "mua",
      "an",
      "uống",
      "tieu",
      "thanh toan",
      "xang",
      "grab"
    ];

    if (defaultIncome.any((w) => normalized.contains(w))) {
      return VoiceIntentType.income;
    }
    if (defaultSpend.any((w) => normalized.contains(w))) {
      return VoiceIntentType.spend;
    }

    return VoiceIntentType.unknown;
  }

  /* =============================================
   * PARSE – hàm chính
   * ============================================= */
  Future<VoiceIntent> parse(String text, {BuildContext? context}) async {
    final lower = text.toLowerCase().trim();
    final clean = removeDiacritics(lower);

    // 1️⃣ Nhận diện số tiền
    int? amount;
    final match = _moneyRegex.firstMatch(lower);
    if (match != null) {
      var raw = match.group(1)!.replaceAll(RegExp(r'[^\d]'), '');
      amount = int.tryParse(raw);
      final unit = match.group(2);
      if (unit != null && amount != null) {
        if (unit.contains("tr") || unit.contains("triệu")) amount *= 1000000;
        if (unit.contains("k") ||
            unit.contains("nghìn") ||
            unit.contains("ngàn")) amount *= 1000;
      }
    }

    // 2️⃣ Nhận diện ví
    String? walletName;
    final w = _walletRegex.firstMatch(lower);
    if (w != null) walletName = w.group(2);

    // 3️⃣ Nhận diện danh mục
    List<String> categories = [];
    if (context != null) categories = _getUserCategories(context);
    String? categoryName = _matchCategory(lower, categories);

    // 4️⃣ Nhận diện loại (chi / thu)
    final type = _detectType(clean);

    // 5️⃣ Note
    String note = lower;
    note = note.replaceAll(_moneyRegex, '');
    if (walletName != null) note = note.replaceAll(walletName, '');
    note = note.trim();

    // 6️⃣ Học từ mới
    if (categoryName != null && note.isNotEmpty) {
      await _synonyms.learnFromUtterance(note, categoryName);
    }

    // 7️⃣ Trả kết quả
    return VoiceIntent(
      type: type,
      note: note.isNotEmpty ? note : null,
      amount: amount,
      walletName: walletName,
      categoryName: categoryName ?? "Của Bạn",
    );
  }
}
