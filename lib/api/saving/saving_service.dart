import 'package:dio/dio.dart';
import 'saving_model.dart';

class SavingService {
  final Dio dio;
  SavingService(this.dio);

  /// Lấy tất cả Saving cho năm và tháng cụ thể
  Future<List<SavingModel>> getAll({int? year, int? month}) async {
    final queryParameters = <String, dynamic>{};
    if (year != null) queryParameters['year'] = year;
    if (month != null) queryParameters['month'] = month;

    final res = await dio.get('saving', queryParameters: queryParameters);

    if (res.data is List) {
      return (res.data as List)
          .map((e) => SavingModel.fromJson(e))
          .toList();
    }

    throw Exception("Invalid format from API /saving");
  }

  /// Tạo Saving
  Future<SavingModel> create(Map<String, dynamic> data) async {
    final res = await dio.post('saving', data: data);
    return SavingModel.fromJson(res.data);
  }

  /// Update Saving
  Future<SavingModel> update(int id, Map<String, dynamic> data) async {
    final res = await dio.put('saving/$id', data: data);
    return SavingModel.fromJson(res.data);
  }

  /// Delete
  Future<void> delete(int id) async {
    await dio.delete('saving/$id');
  }

  /// Tạo giao dịch tiết kiệm (Nạp / Rút)
  Future<bool> createTransaction({
    required int savingId,
    required int bankId,
    required double amount,
    required String note,
  }) async {
    final resp = await dio.post("saving_transaction", data: {
      "saving_id": savingId,
      "bank_id": bankId,
      "amount": amount,
      "note": note,
    });

    return resp.statusCode == 200 || resp.statusCode == 201;
  }
}
