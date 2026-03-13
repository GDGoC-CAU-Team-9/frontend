import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../menu/data/repositories/menu_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HistoryRepository(dio);
});

/// A single history entry from the backend
class HistoryItem {
  final int id;
  final List<String> imageUrls;
  final List<MenuAnalysisResult> items;
  final MenuAnalysisResult? best;
  final DateTime createdAt;

  HistoryItem({
    required this.id,
    required this.imageUrls,
    required this.items,
    this.best,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> imageUrlsJson = json['imageUrls'] ?? [];
    final searchResult = json['searchResult'] as Map<String, dynamic>?;

    List<MenuAnalysisResult> items = [];
    MenuAnalysisResult? best;

    if (searchResult != null) {
      final List<dynamic> itemsJson = searchResult['items'] ?? [];
      items = itemsJson
          .map((item) => MenuAnalysisResult.fromJson(item))
          .toList();

      if (searchResult['best'] != null) {
        best = MenuAnalysisResult.fromJson(searchResult['best']);
      }
    }

    return HistoryItem(
      id: json['id'] ?? 0,
      imageUrls: imageUrlsJson.map((e) => e.toString()).toList(),
      items: items,
      best: best,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class HistoryPage {
  final List<HistoryItem> items;
  final int totalPages;
  final int totalElements;

  HistoryPage({
    required this.items,
    required this.totalPages,
    required this.totalElements,
  });

  factory HistoryPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> historyJson = json['searchHistory'] ?? [];
    return HistoryPage(
      items: historyJson.map((item) => HistoryItem.fromJson(item)).toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
    );
  }
}

class HistoryRepository {
  final Dio _dio;

  HistoryRepository(this._dio);

  /// GET /histories?pageNumber={pageNumber}
  Future<HistoryPage> getHistories(int pageNumber) async {
    try {
      final response = await _dio.get(
        '/histories',
        queryParameters: {'pageNumber': pageNumber},
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['isSuccess'] == true) {
        final result = response.data['result'];
        return HistoryPage.fromJson(result);
      }

      log('Warning: Unexpected response for getHistories: ${response.data}');
      return HistoryPage(items: [], totalPages: 0, totalElements: 0);
    } catch (e) {
      log('getHistories error: $e');
      rethrow;
    }
  }

  /// DELETE /histories/{historyId}
  Future<void> deleteHistory(int historyId) async {
    try {
      final response = await _dio.delete(
        '/histories/$historyId',
        options: Options(
          validateStatus: (status) {
            return status != null && status < 600;
          },
        ),
      );

      if (response.data is Map && response.data['isSuccess'] == false) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['message']?.toString() ?? '기록 삭제 실패',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      final responseMessage = response.data is Map
          ? response.data['message']?.toString()
          : null;

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: responseMessage ?? '기록 삭제 실패: ${response.statusCode}',
      );
    } catch (e) {
      log('deleteHistory error: $e');
      rethrow;
    }
  }
}
