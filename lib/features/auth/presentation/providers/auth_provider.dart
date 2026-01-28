import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.login(email: email, password: password);
      // Since API doesn't return user info, we create a local user object with the email
      return User(id: 'local', email: email, name: '사용자');
    });
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    await AsyncValue.guard(
      () =>
          _authRepository.signUp(name: name, email: email, password: password),
    );
    // After signup, we might want to auto-login or just return to login screen
    // For now, setting state to data(null) to indicate success but no user yet
    if (!state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}
