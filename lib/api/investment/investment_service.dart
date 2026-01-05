import 'package:dio/dio.dart';

class InvestmentService {
  final Dio dio;

  InvestmentService(this.dio);

  Future<List<dynamic>> fetch() async {
    final res = await dio.get("investments");
    if (res.statusCode == 200) return res.data;
    throw Exception("Failed to fetch investments");
  }

  Future<bool> create(Map<String, dynamic> data) async {
    final res = await dio.post("investments", data: data);
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> updatePrice(int id, double newPrice) async {
    final res = await dio.put("investments/$id", data: {
      "current_price": newPrice,
    });
    return res.statusCode == 200;
  }

  Future<bool> delete(int id) async {
    final res = await dio.delete("investments/$id");
    return res.statusCode == 200;
  }
}
