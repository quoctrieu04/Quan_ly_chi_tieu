import 'dart:io';
import 'package:dio/dio.dart';

class OutInvoiceService {
  final Dio _dio;
  OutInvoiceService(this._dio);

  Future<dynamic> fetchByMonth({
    required int year,
    required int month,
    int? day,
  }) async {
    try {
      final res = await _dio.get(
        '/out-invoices',
        queryParameters: {
          'year': year,
          'month': month,
          if (day != null) 'day': day,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return res.data;
    } catch (e) {
      throw Exception('Lỗi tải danh sách phiếu chi: $e');
    }
  }

  Future<void> create(
    Map<String, dynamic> data, {
    File? photoFile,
  }) async {
    try {
      final payload = <String, dynamic>{
        'bank_id': data['bank_id'] ?? data['bankId'],
        'outcat_id': data['outcat_id'] ??
            data['outcatId'] ??
            data['category_id'] ??
            data['categoryId'],
        'amount': data['amount'],
        'content': data['content'],
        'month': data['month'],
        'year': data['year'],
        if (data['occurred_at'] != null) 'occurred_at': data['occurred_at'],
      };

      if (photoFile != null) {
        final fileName = photoFile.path.split(Platform.pathSeparator).last;

        final formData = FormData.fromMap({
          ...payload,
          'photo': await MultipartFile.fromFile(
            photoFile.path,
            filename: fileName,
          ),
        });

        await _dio.post(
          '/out-invoices',
          data: formData,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'multipart/form-data',
            },
          ),
        );
        return;
      }

      await _dio.post(
        '/out-invoices',
        data: payload,
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } catch (e) {
      throw Exception('Lỗi tạo phiếu chi: $e');
    }
  }
}