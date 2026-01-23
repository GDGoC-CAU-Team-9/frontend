import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/allergy_model.dart';

final allergyRepositoryProvider = Provider<AllergyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AllergyRepository(dio);
});

class AllergyRepository {
  final Dio _dio;

  AllergyRepository(this._dio);

  Future<List<Allergy>> getAllergies() async {
    try {
      final response = await _dio.get('/allergies');

      List<dynamic> data;
      if (response.data is Map &&
          response.data.containsKey('result') &&
          response.data['result'] is Map &&
          response.data['result'].containsKey('allergies')) {
        data = response.data['result']['allergies'];
      } else if (response.data is List) {
        data = response.data;
      } else {
        data = [];
        print(
          'Warning: Unexpected response format for getAllergies: ${response.data}',
        );
      }

      return data.map((json) => Allergy.fromJson(json)).toList();
    } catch (e) {
      throw e;
    }
  }

  Future<List<Allergy>> getMyAllergies() async {
    try {
      final response = await _dio.get('/allergies/my');

      List<dynamic> data;
      if (response.data is Map &&
          response.data.containsKey('result') &&
          response.data['result'] is Map &&
          response.data['result'].containsKey('allergies')) {
        data = response.data['result']['allergies'];
      } else if (response.data is List) {
        data = response.data;
      } else {
        data = [];
        print(
          'Warning: Unexpected response format for getMyAllergies: ${response.data}',
        );
      }

      return data.map((json) => Allergy.fromJson(json)).toList();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateMyAllergies(List<int> allergyIds) async {
    try {
      print('Updating allergies: $allergyIds');
      // Changed key to 'allergyIds' based on backend validation error
      final response = await _dio.put(
        '/allergies/my',
        data: {'allergyIds': allergyIds},
      );

      if (response.data is Map && response.data['isSuccess'] == false) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['message'] ?? 'Update failed',
        );
      }
      print('Update successful');
    } catch (e) {
      print('Update failed: $e');
      throw e;
    }
  }
}
