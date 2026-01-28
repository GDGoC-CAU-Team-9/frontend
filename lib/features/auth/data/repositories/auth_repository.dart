import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._dio);

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');
      print('Login response headers: ${response.headers}');

      // Extract Token (Try Header 'Authorization' first, then Body 'accessToken')
      String? token;

      // 1. Check Header
      final authHeader = response.headers.value('Authorization');
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      }

      // 2. Check Body (if header failed)
      if (token == null && response.data is Map) {
        if (response.data.containsKey('result') &&
            response.data['result'] is Map) {
          token = response.data['result']['token'];
        } else {
          token = response.data['accessToken'] ?? response.data['token'];
        }
      }

      if (token != null) {
        print('Token found: $token');
        await _storage.write(key: 'accessToken', value: token);
      } else {
        print('Warning: No token found in response');
      }

      if (response.data is Map && response.data['isSuccess'] == false) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['message'] ?? '로그인 실패',
        );
      }

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: '아이디 또는 비밀번호가 틀렸습니다.',
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: '로그인 실패: ${response.statusCode}',
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
