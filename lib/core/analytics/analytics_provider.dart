import 'package:flutter/material.dart';
import '../../api/ai/ai_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AiService aiService;
  double? predictedExpense;
  List<dynamic> alerts = [];

  AnalyticsProvider(this.aiService);

  Future<void> loadPrediction() async {
    try {
      final data = await aiService.fetchPrediction();
      predictedExpense = data['predicted_expense']?.toDouble();
      alerts = data['alerts'] ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi dự báo: $e");
    }
  }
}
