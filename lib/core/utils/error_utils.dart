import 'package:dio/dio.dart';

String toUserMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }

      final result = data['result'];
      if (result is String && result.trim().isNotEmpty) {
        return result.trim();
      }
    }

    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }
  }

  return fallback;
}
