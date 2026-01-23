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
      await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      // TODO: Handle response, save token/user
    } catch (e) {
      throw e;
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
