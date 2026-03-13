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

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    restoreSession();
  }

  Future<void> restoreSession() async {
    state = const AsyncValue.loading();
    try {
      final hasSession = await _authRepository.hasActiveSession();
      if (!hasSession) {
        state = const AsyncValue.data(null);
        return;
      }

      final savedEmail = await _authRepository.getStoredEmail();
      final email = (savedEmail == null || savedEmail.trim().isEmpty)
          ? 'user@safeplate.local'
          : savedEmail;
      state = AsyncValue.data(User(id: 'local', email: email, name: null));
    } catch (_) {
      // Fall back to logged-out state if local session restore fails.
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.login(email: email, password: password);
      // Since API doesn't return user info, we create a local user object with the email
      return User(id: 'local', email: email, name: null);
    });
  }

  Future<void> signUp(String email, String password, String language) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<User?>(() async {
      await _authRepository.signUp(
        email: email,
        password: password,
        language: language,
      );
      return null;
    });
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } finally {
      // Always clear local auth state even if storage cleanup fails.
      state = const AsyncValue.data(null);
    }
  }
}
