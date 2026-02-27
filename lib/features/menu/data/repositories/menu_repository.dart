import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
// import 'package:path/path.dart' as p; // Removed unused import
import '../../../../core/network/dio_client.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Added here

// Model for Analysis Result
class MenuAnalysisResult {
  final String menuName;
  final int safetyScore; // 0-100
  final String reason;
  final String safetyLevel; // 'safe', 'caution', 'danger'

  MenuAnalysisResult({
    required this.menuName,
    required this.safetyScore,
    required this.reason,
    required this.safetyLevel,
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
      reason: json['reason_ko'] ?? '',
      safetyLevel: safetyLevel,
    );
  }
}

class MenuRepository {
  final Dio _dio;

  MenuRepository(this._dio);

  Future<List<MenuAnalysisResult>> uploadMenuImage(
    XFile file,
    List<String> avoidList,
  ) async {
    try {
      // 1. Normalize Image (Resize & Convert to JPEG)
      developer.log(
        'Step 0: Normalizing Image to JPEG...',
        name: 'MenuRepository',
      );
      final Uint8List originalBytes = await file.readAsBytes();

      // Compress and convert to JPEG
      // Web, Android, iOS support via compressWithList
      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithList(
            originalBytes,
            minHeight: 1024,
            minWidth: 1024,
            quality: 85,
            format: CompressFormat.jpeg,
          );

      const String fileExtension = 'jpeg'; // Always JPEG after conversion
      developer.log(
        'Image normalized. Size: ${originalBytes.length} -> ${compressedBytes.length}',
        name: 'MenuRepository',
      );

      // 1. Get Presigned URL
      developer.log(
        'Step 1: Requesting Presigned URL...',
        name: 'MenuRepository',
      );
      developer.log(
        'File Type: $fileExtension',
        name: 'MenuRepository',
      ); // Debug print
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

      // 2. Upload to S3 (Direct Binary Upload)
      developer.log('Step 2: Uploading to S3...', name: 'MenuRepository');
      // Create a separate Dio instance for S3 to avoid default interceptors (like Auth headers)
      final s3Dio = Dio();

      // Use compressedBytes instead of original fileBytes
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

      // 3. Update File Status
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

      // Get the uploaded file URL from the status response
      final String uploadedFileUrl = statusResponse.data['result']['fileUrl'];
      developer.log(
        'File Status Updated. URL: $uploadedFileUrl',
        name: 'MenuRepository',
      );

      // 4. Request Analysis (Direct AI Call)
      developer.log(
        'Step 4: Requesting Menu Analysis (Direct AI)...',
        name: 'MenuRepository',
      );

      // AI Service Endpoint
      const aiEndpoint = 'https://hn-ui-gdg-team-9.hf.space/rank';

      final aiDio = Dio(); // New Dio instance for external AI service
      final analysisResponse = await aiDio.post(
        aiEndpoint,
        data: {'image_url': uploadedFileUrl, 'avoid': avoidList},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (analysisResponse.statusCode == 200) {
        final data = analysisResponse.data;
        developer.log('AI Analysis Result: $data', name: 'MenuRepository');

        List<dynamic> items = [];
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          items = data['items'];
        }

        return items.map((item) => MenuAnalysisResult.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to analyze menu: ${analysisResponse.statusCode}',
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
