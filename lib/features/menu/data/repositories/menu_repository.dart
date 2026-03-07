import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Model for Analysis Result
class MenuAnalysisResult {
  final String menuName;
  final int safetyScore; // 0-100
  final String reason;
  final String safetyLevel; // 'safe', 'caution', 'danger'
  final List<String> matchedAvoid;
  final List<String> suspectedIngredients;

  MenuAnalysisResult({
    required this.menuName,
    required this.safetyScore,
    required this.reason,
    required this.safetyLevel,
    this.matchedAvoid = const [],
    this.suspectedIngredients = const [],
  });

  factory MenuAnalysisResult.fromJson(Map<String, dynamic> json) {
    final int risk = json['risk'] ?? 0;
    String safetyLevel = 'safe';
    if (risk > 70) {
      safetyLevel = 'danger';
    } else if (risk > 30) {
      safetyLevel = 'caution';
    }

    return MenuAnalysisResult(
      menuName: json['menu'] ?? 'Unknown',
      safetyScore: json['score'] ?? 0,
      reason: json['reason'] ?? json['reason_ko'] ?? '',
      safetyLevel: safetyLevel,
      matchedAvoid:
          (json['matched_avoid'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suspectedIngredients:
          (json['suspected_ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// Full search result from backend (includes best item + timings)
class SearchResult {
  final List<MenuAnalysisResult> items;
  final MenuAnalysisResult? best;

  SearchResult({required this.items, this.best});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] ?? [];
    final items = itemsJson
        .map((item) => MenuAnalysisResult.fromJson(item))
        .toList();

    MenuAnalysisResult? best;
    if (json['best'] != null) {
      best = MenuAnalysisResult.fromJson(json['best']);
    }

    return SearchResult(items: items, best: best);
  }
}

class MenuRepository {
  final Dio _dio;

  MenuRepository(this._dio);

  /// Upload image to S3 and analyze via backend (POST /restaurant/search)
  /// The backend automatically fetches user's avoid items and saves history.
  Future<List<MenuAnalysisResult>> uploadMenuImage(
    XFile file, {
    int? teamMemberId,
  }) async {
    try {
      // 1. Normalize Image (Resize & Convert to JPEG)
      developer.log(
        'Step 0: Normalizing Image to JPEG...',
        name: 'MenuRepository',
      );
      final Uint8List originalBytes = await file.readAsBytes();

      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithList(
            originalBytes,
            minHeight: 1024,
            minWidth: 1024,
            quality: 85,
            format: CompressFormat.jpeg,
          );

      const String fileExtension = 'jpeg';
      developer.log(
        'Image normalized. Size: ${originalBytes.length} -> ${compressedBytes.length}',
        name: 'MenuRepository',
      );

      // 2. Get Presigned URL
      developer.log(
        'Step 1: Requesting Presigned URL...',
        name: 'MenuRepository',
      );
      final presignedResponse = await _dio.post(
        '/files/presigned-url',
        data: {'path': 'menu_board_request', 'fileType': fileExtension},
      );

      if (presignedResponse.statusCode != 200 ||
          presignedResponse.data['isSuccess'] == false) {
        throw Exception(
          'Failed to get presigned URL: ${presignedResponse.data['message'] ?? presignedResponse.statusCode}',
        );
      }

      final result = presignedResponse.data['result'];
      final int fileId = result['fileId'];
      final String presignedUrl = result['presignedUrl'];
      developer.log(
        'Got Presigned URL for FileID: $fileId',
        name: 'MenuRepository',
      );

      // 3. Upload to S3
      developer.log('Step 2: Uploading to S3...', name: 'MenuRepository');
      final s3Dio = Dio();
      await s3Dio.put(
        presignedUrl,
        data: compressedBytes,
        options: Options(
          headers: {
            'Content-Type': 'image/$fileExtension',
            'Content-Length': compressedBytes.length,
          },
        ),
      );
      developer.log('S3 Upload Completed', name: 'MenuRepository');

      // 4. Update File Status
      developer.log('Step 3: Updating File Status...', name: 'MenuRepository');
      final statusResponse = await _dio.patch(
        '/files/$fileId/status',
        data: {'fileStatus': 'UPLOADED'},
      );

      if (statusResponse.statusCode != 200) {
        throw Exception(
          'Failed to update file status: ${statusResponse.statusCode}',
        );
      }
      developer.log('File Status Updated', name: 'MenuRepository');

      // 5. Request Analysis via Backend (POST /restaurant/search)
      // Backend will: fetch avoid items, call AI, save history automatically
      developer.log(
        'Step 4: Requesting Menu Analysis via Backend... (Team: $teamMemberId)',
        name: 'MenuRepository',
      );

      final Map<String, dynamic> requestData = {
        'ids': [fileId],
      };
      if (teamMemberId != null) {
        requestData['teamMemberId'] = teamMemberId;
      }

      final analysisResponse = await _dio.post(
        '/restaurant/search',
        data: requestData,
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (analysisResponse.statusCode == 200 &&
          analysisResponse.data['isSuccess'] == true) {
        final resultData = analysisResponse.data['result'];
        developer.log(
          'Backend Analysis Result: $resultData',
          name: 'MenuRepository',
        );

        final searchResult = SearchResult.fromJson(resultData);
        return searchResult.items;
      } else {
        throw Exception(
          'Failed to analyze menu: ${analysisResponse.data['message'] ?? analysisResponse.statusCode}',
        );
      }
    } catch (e) {
      developer.log(
        'Error during menu analysis flow: $e',
        name: 'MenuRepository',
        error: e,
      );
      rethrow;
    }
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MenuRepository(dio);
});
