import 'dart:convert';
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
  static const _tokenKey = 'accessToken';
  static const _emailKey = 'userEmail';

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
        if (token == null || token.isEmpty) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: '로그인 응답에 토큰이 없습니다.',
          );
        }
        print('Token found: $token');
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _emailKey, value: email);
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

  Future<void> updateLanguage(String language) async {
    try {
      final response = await _dio.patch(
        '/members/language',
        data: {'language': language},
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
          message: responseMessage ?? '언어 변경 실패',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message:
            responseMessage ?? '언어 변경 실패: ${response.statusCode ?? '알 수 없는 오류'}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }

  Future<String?> getStoredEmail() async {
    return _storage.read(key: _emailKey);
  }

  Future<bool> hasActiveSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      return false;
    }

    if (_isTokenExpired(token)) {
      await logout();
      return false;
    }

    return true;
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

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      if (map is! Map<String, dynamic>) return false;

      final exp = map['exp'];
      if (exp is! num) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isAfter(expiry);
    } catch (_) {
      // If token parsing fails, don't force logout here.
      return false;
    }
  }
}
