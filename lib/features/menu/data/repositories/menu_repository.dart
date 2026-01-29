import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../../core/network/dio_client.dart';

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
      // Use file.name for extension as file.path on web might be a blob URL without extension
      final String fileExtension = p
          .extension(file.name)
          .replaceAll('.', '')
          .toLowerCase();

      // 1. Get Presigned URL
      print('Step 1: Requesting Presigned URL...');
      print('File Type: $fileExtension'); // Debug print
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
      print('Got Presigned URL for FileID: $fileId');

      // 2. Upload to S3 (Direct Binary Upload)
      print('Step 2: Uploading to S3...');
      // Create a separate Dio instance for S3 to avoid default interceptors (like Auth headers)
      final s3Dio = Dio();

      // On web, file.length() is not supported for XFile, so we read bytes.
      // For mobile, we could use openRead, but readAsBytes works cross-platform for reasonable sizes.
      final Uint8List fileBytes = await file.readAsBytes();

      await s3Dio.put(
        presignedUrl,
        data: fileBytes, // Pass bytes directly
        options: Options(
          headers: {
            'Content-Type': 'image/$fileExtension',
            'Content-Length': fileBytes.length,
          },
        ),
      );
      print('S3 Upload Completed');

      // 3. Update File Status
      print('Step 3: Updating File Status...');
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
      print('File Status Updated. URL: $uploadedFileUrl');

      // 4. Request Analysis (Direct AI Call)
      print('Step 4: Requesting Menu Analysis (Direct AI)...');

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
        print('AI Analysis Result: $data');

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
      print('Error during menu analysis flow: $e');
      rethrow;
    }
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MenuRepository(dio);
});
