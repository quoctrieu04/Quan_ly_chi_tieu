import 'package:dio/dio.dart';
import 'saving_transaction_model.dart';

class SavingTransactionService {
  final Dio dio;
  SavingTransactionService(this.dio);

  Future<List<SavingTransaction>> index(int savingId) async {
    final res = await dio.get('saving/$savingId/transactions');
    return (res.data as List)
        .map((e) => SavingTransaction.fromJson(e))
        .toList();
  }

  Future<SavingTransaction> create(int savingId, Map<String, dynamic> data) async {
    final res = await dio.post('saving/$savingId/transactions', data: data);
    return SavingTransaction.fromJson(res.data);
  }
}
