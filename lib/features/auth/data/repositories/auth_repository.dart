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
            // Handle all HTTP codes in app logic so we can show clean messages.
            return status != null && status < 600;
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

      final responseMessage = _extractServerMessage(response.data);

      if (response.data is Map && response.data['isSuccess'] == false) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: responseMessage ?? '로그인 실패',
        );
      }

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: responseMessage ?? '아이디 또는 비밀번호가 틀렸습니다.',
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: responseMessage ?? '로그인 실패: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Normalize unexpected Dio exceptions (network, timeout, etc.)
      final normalizedMessage =
          _extractServerMessage(e.response?.data) ?? e.message ?? '로그인 실패';
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: e.type,
        error: e.error,
        stackTrace: e.stackTrace,
        message: normalizedMessage,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/join',
        data: {'email': email, 'password': password, 'language': language},
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) {
            return status != null && status < 600;
          },
        ),
      );

      final responseMessage = _extractServerMessage(response.data);

      if (response.data is Map && response.data['isSuccess'] == false) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: responseMessage ?? '회원가입 실패',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message:
            responseMessage ??
            '회원가입 실패: ${response.statusCode ?? '알 수 없는 오류'}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
  }

  String? _extractServerMessage(dynamic data) {
    if (data is! Map) return null;

    final message = data['message']?.toString();
    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }

    final result = data['result'];
    if (result is String && result.trim().isNotEmpty) {
      return result.trim();
    }

    return null;
  }
}
