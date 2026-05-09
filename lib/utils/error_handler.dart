import 'dart:convert';

/// Hàm xử lý lỗi thân thiện cho UI
/// Nhận vào [error] là exception hoặc string và trả về một thông báo tiếng Việt có dấu.
String getFriendlyError(dynamic error, {String defaultMessage = 'Đã có lỗi xảy ra, vui lòng thử lại.'}) {
  if (error == null) return defaultMessage;
  
  String msg = error.toString();
  
  // Bắt một số lỗi mạng thường gặp
  if (msg.toLowerCase().contains('timeout') || msg.toLowerCase().contains('socketexception')) {
    return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền.';
  }

  // Cố gắng bóc tách JSON nếu backend trả về lỗi dạng {"message": "..."}
  try {
    final jsonStart = msg.indexOf('{');
    if (jsonStart != -1) {
      final map = jsonDecode(msg.substring(jsonStart)) as Map<String, dynamic>;
      return (map['message'] as String?) ??
             (map['errors']?.toString() ?? msg);
    }
  } catch (_) {
    // Không phải JSON, bỏ qua
  }

  // Một số trường hợp lỗi không bóc tách được từ backend thì giữ nguyên nội dung (hoặc custom thêm)
  return msg;
}
