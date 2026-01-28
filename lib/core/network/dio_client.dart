import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
// ignore: uri_does_not_exist
import 'package:dio/browser.dart'; // For Web Adapter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

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

  // Web Configuration: Enable Cookies (CORS)
  if (kIsWeb) {
    // Enable credentials (cookies) for cross-origin requests
    final adapter = BrowserHttpClientAdapter();
    adapter.withCredentials = true;
    dio.httpClientAdapter = adapter;
  }

  // Cookie Manager
  // CookieManager is not supported on Web and causes a crash
  if (!kIsWeb) {
    final cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
  }

  // Add interceptors here if needed (e.g., for logging or auth tokens)
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
});
