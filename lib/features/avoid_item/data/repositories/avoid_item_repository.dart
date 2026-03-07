import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final avoidItemRepositoryProvider = Provider<AvoidItemRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AvoidItemRepository(dio);
});

class AvoidItemRepository {
  final Dio _dio;

  AvoidItemRepository(this._dio);

  /// HTTP 상태 코드 체크 헬퍼
  void _checkResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 300) {
      final message = response.data is Map
          ? (response.data['message'] ?? 'HTTP ${response.statusCode}')
          : 'HTTP ${response.statusCode}';
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: message.toString(),
      );
    }
  }

  /// GET /avoid-items/my → 내 기피재료 목록 조회
  Future<List<String>> getMyAvoidItems() async {
    try {
      final response = await _dio.get('/avoid-items/my');
      _checkResponse(response);

      if (response.data is Map &&
          response.data.containsKey('result') &&
          response.data['result'] is Map &&
          response.data['result'].containsKey('avoidItems')) {
        final List<dynamic> items = response.data['result']['avoidItems'];
        return items.cast<String>();
      }

      log(
        'Warning: Unexpected response format for getMyAvoidItems: ${response.data}',
      );
      return [];
    } catch (e) {
      log('getMyAvoidItems error: $e');
      rethrow;
    }
  }

  /// POST /avoid-items/my/search → 자연어 문장에서 기피재료 추출 (AI)
  Future<AvoidExtractResult> extractAvoidItems(String text) async {
    try {
      final response = await _dio.post(
        '/avoid-items/my/search',
        data: {'text': text},
      );
      _checkResponse(response);

      if (response.data is Map &&
          response.data.containsKey('result') &&
          response.data['result'] is Map) {
        final result = response.data['result'];
        final List<dynamic> items = result['avoidItems'] ?? [];
        final String? confirmQuestion = result['confirmQuestion'];
        return AvoidExtractResult(
          avoidItems: items.cast<String>(),
          confirmQuestion: confirmQuestion ?? '',
        );
      }

      log(
        'Warning: Unexpected response format for extractAvoidItems: ${response.data}',
      );
      return AvoidExtractResult(avoidItems: [], confirmQuestion: '');
    } catch (e) {
      log('extractAvoidItems error: $e');
      rethrow;
    }
  }

  /// PUT /avoid-items/my → 기피재료 저장
  Future<List<String>> saveAvoidItems(List<String> items) async {
    try {
      final response = await _dio.put(
        '/avoid-items/my',
        data: {'items': items},
      );
      _checkResponse(response);

      if (response.data is Map &&
          response.data.containsKey('result') &&
          response.data['result'] is Map &&
          response.data['result'].containsKey('avoidItems')) {
        final List<dynamic> saved = response.data['result']['avoidItems'];
        return saved.cast<String>();
      }

      return items;
    } catch (e) {
      log('saveAvoidItems error: $e');
      rethrow;
    }
  }
}

class AvoidExtractResult {
  final List<String> avoidItems;
  final String confirmQuestion;

  AvoidExtractResult({required this.avoidItems, required this.confirmQuestion});
}
