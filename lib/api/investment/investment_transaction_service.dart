import 'package:dio/dio.dart';
import 'investment_transaction_model.dart';

class InvestmentTransactionService {
  final Dio dio;
  InvestmentTransactionService(this.dio);

  Future<List<InvestmentTransaction>> getByMonth({
    required int year,
    required int month,
    int? day,
  }) async {
    try {
      // ✅ Query params theo tháng/ngày (backend bạn sẽ nhận year, month, day)
      final res = await dio.get(
        'investment-transactions',
        queryParameters: {
          'year': year,
          'month': month,
          if (day != null) 'day': day,
        },
      );

      final List list = res.data['data'];
      return list
          .map((e) =>
              InvestmentTransaction.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map && e.response?.data['message'] != null)
              ? e.response?.data['message'].toString()
              : 'Không tải được lịch sử đầu tư';
      throw Exception(msg);
    }
  }
}
