import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String _resolveBaseUrl() {
  final rawBaseUrl = (dotenv.env['BASE_URL'] ?? '').trim();

  if (rawBaseUrl.isEmpty) {
    throw StateError(
      'BASE_URL is missing. Set BASE_URL in .env before running the app.',
    );
  }

  final uri = Uri.tryParse(rawBaseUrl);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw StateError(
      'BASE_URL is invalid: "$rawBaseUrl". Expected format: https://api.example.com',
    );
  }

  if (kReleaseMode && uri.scheme != 'https') {
    throw StateError(
      'In release builds, BASE_URL must use HTTPS. Current: "$rawBaseUrl"',
    );
  }

  return rawBaseUrl;
}

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = _resolveBaseUrl();

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );

  const storage = FlutterSecureStorage();

  // Add Token Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add Bearer Token if available
        final token = await storage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          if (kDebugMode) {
            debugPrint('Authorization header attached.');
          }
        } else if (kDebugMode) {
          debugPrint('No token found in storage.');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && kDebugMode) {
          // TODO: Handle Token Refresh or Logout
          debugPrint('Unauthorized: token might be expired.');
        }
        return handler.next(e);
      },
    ),
  );

  // Cookie Manager removed (JWT implementation)

  // Verbose HTTP logging is enabled only in debug builds.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  return dio;
});
