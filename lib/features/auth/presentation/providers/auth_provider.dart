import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authRepository.login(email: email, password: password),
    );
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () =>
          _authRepository.signUp(name: name, email: email, password: password),
    );
  }
}
