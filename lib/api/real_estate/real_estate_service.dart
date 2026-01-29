import 'package:dio/dio.dart';
import 'real_estate_model.dart';

class RealEstateService {
  final Dio dio;

  RealEstateService({required this.dio});

  /// ===============================
  /// CREATE REAL ESTATE INVESTMENT
  /// ===============================
  Future<RealEstateInvestment> createInvestment({
    required String name,
    required String propertyType,
    String? address,
    required double purchasePrice,
    required DateTime purchaseDate,
    required int accountSourceId,
    String? notes,
  }) async {
    final res = await dio.post(
      '/v1/real-estate/investments',
      data: {
        'name': name,
        'property_type': propertyType,
        'address': address,
        'purchase_price': purchasePrice,
        'purchase_date':
            purchaseDate.toIso8601String().substring(0, 10),
        'account_source_id': accountSourceId,
        'notes': notes,
      },
    );

    return RealEstateInvestment.fromJson(res.data);
  }

  /// ===============================
  /// LIST INVESTMENTS (OPTIONAL)
  /// ===============================
  Future<List<RealEstateInvestment>> getAll() async {
    final res =
        await dio.get('/v1/real-estate/investments');

    return (res.data as List)
        .map((e) =>
            RealEstateInvestment.fromJson(e))
        .toList();
  }
}
