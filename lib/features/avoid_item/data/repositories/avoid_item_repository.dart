import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final avoidItemRepositoryProvider = Provider<AvoidItemRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AvoidItemRepository(dio);
});

class AvoidPresetSummary {
  final int id;
  final String name;
  final String description;
  final int? avoidItemCount;
  final List<String> items;

  const AvoidPresetSummary({
    required this.id,
    required this.name,
    this.description = '',
    this.avoidItemCount,
    this.items = const [],
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  factory AvoidPresetSummary.fromJson(Map<String, dynamic> json) {
    final items = _parseStringList(
      json['items'] ??
          json['avoidItems'] ??
          json['avoid_items'] ??
          json['presetItems'],
    );
    final parsedCount = json['avoidItemCount'] != null
        ? _parseInt(json['avoidItemCount'])
        : (json['itemCount'] != null ? _parseInt(json['itemCount']) : 0);

    return AvoidPresetSummary(
      id: _parseInt(json['presetId'] ?? json['id']),
      name: (json['presetName'] ?? json['name'] ?? json['title'] ?? '')
          .toString()
          .trim(),
      description: (json['description'] ?? json['summary'] ?? '')
          .toString()
          .trim(),
      avoidItemCount: parsedCount > 0
          ? parsedCount
          : (items.isNotEmpty ? items.length : null),
      items: items,
    );
  }
}

class AvoidPresetDetail {
  final int id;
  final String name;
  final String description;
  final List<String> avoidItems;

  const AvoidPresetDetail({
    required this.id,
    required this.name,
    required this.avoidItems,
    this.description = '',
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  factory AvoidPresetDetail.fromJson(Map<String, dynamic> json) {
    return AvoidPresetDetail(
      id: _parseInt(json['presetId'] ?? json['id']),
      name: (json['presetName'] ?? json['name'] ?? json['title'] ?? '')
          .toString()
          .trim(),
      description: (json['description'] ?? json['summary'] ?? '')
          .toString()
          .trim(),
      avoidItems: _parseStringList(
        json['avoidItems'] ??
            json['avoid_items'] ??
            json['items'] ??
            json['presetItems'],
      ),
    );
  }
}

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

  /// GET /avoid-presets → 기피재료 프리셋 목록 조회
  Future<List<AvoidPresetSummary>> getAvoidPresets() async {
    try {
      final response = await _dio.get('/avoid-presets');
      _checkResponse(response);

      final dynamic result = response.data is Map
          ? (response.data['result'] ?? response.data)
          : response.data;

      List<dynamic> presetsJson = const [];
      if (result is List) {
        presetsJson = result;
      } else if (result is Map) {
        final listLike =
            result['avoidPresets'] ??
            result['presets'] ??
            result['items'] ??
            result['list'];
        if (listLike is List) {
          presetsJson = listLike;
        }
      }

      return presetsJson
          .whereType<Map>()
          .map(
            (json) =>
                AvoidPresetSummary.fromJson(Map<String, dynamic>.from(json)),
          )
          .where((preset) => preset.id > 0 || preset.name.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      // Backend rollout 이전에는 404가 정상일 수 있으므로 빈 목록으로 처리.
      if (e.response?.statusCode == 404) {
        log('getAvoidPresets not deployed yet: ${e.response?.statusCode}');
        return [];
      }
      log('getAvoidPresets error: $e');
      rethrow;
    } catch (e) {
      log('getAvoidPresets error: $e');
      rethrow;
    }
  }

  /// GET /avoid-presets/{presetId} → 단일 프리셋 상세 조회
  Future<AvoidPresetDetail> getAvoidPresetById(int presetId) async {
    try {
      final response = await _dio.get('/avoid-presets/$presetId');
      _checkResponse(response);

      final dynamic result = response.data is Map
          ? (response.data['result'] ?? response.data)
          : response.data;

      Map<String, dynamic>? presetJson;
      if (result is Map) {
        final nested =
            result['avoidPreset'] ?? result['preset'] ?? result['detail'];
        if (nested is Map) {
          presetJson = Map<String, dynamic>.from(nested);
        } else {
          presetJson = Map<String, dynamic>.from(result);
        }
      }

      if (presetJson == null) {
        throw Exception(
          'Unexpected response format for getAvoidPresetById: ${response.data}',
        );
      }

      return AvoidPresetDetail.fromJson(presetJson);
    } catch (e) {
      log('getAvoidPresetById error: $e');
      rethrow;
    }
  }
}

class AvoidExtractResult {
  final List<String> avoidItems;
  final String confirmQuestion;

  AvoidExtractResult({required this.avoidItems, required this.confirmQuestion});
}
