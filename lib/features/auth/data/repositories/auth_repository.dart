import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      if (response.statusCode == 302) {
        final location = response.headers.value('location');
        if (location != null && location.contains('error')) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Login failed: Invalid credentials',
          );
        }
        // Success (Redirects to / or home usually)
        return;
      } else if (response.statusCode == 200) {
        // Success
        return;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Login failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/join',
        data: {'name': name, 'email': email, 'password': password},
      );
      // TODO: Handle response
    } catch (e) {
      throw e;
    }
  }
}
