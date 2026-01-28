import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? 'http://localhost:8080',
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
          print('Adding Token to Header: Bearer ${token.substring(0, 10)}...');
        } else {
          print('Warning: No token found in storage.');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // TODO: Handle Token Refresh or Logout
          print('Unauthorized: Token might be expired');
        }
        return handler.next(e);
      },
    ),
  );

  // Cookie Manager removed (JWT implementation)

  // Add interceptors here if needed (e.g., for logging or auth tokens)
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
});
