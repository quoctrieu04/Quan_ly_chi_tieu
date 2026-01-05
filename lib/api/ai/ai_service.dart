import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String baseUrl;
  final String token;

  AiService({required this.baseUrl, required this.token});

  Future<Map<String, dynamic>> fetchPrediction() async {
    final url = Uri.parse("$baseUrl/api/predict");

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Lỗi gọi API: ${res.statusCode}");
    }
  }
}
