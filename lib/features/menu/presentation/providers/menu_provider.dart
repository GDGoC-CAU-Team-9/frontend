import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/menu_repository.dart';

// State provider to hold the analysis results
final menuAnalysisProvider =
    StateNotifierProvider<
      MenuAnalysisNotifier,
      AsyncValue<List<MenuAnalysisResult>>
    >((ref) {
      final repository = ref.watch(menuRepositoryProvider);
      return MenuAnalysisNotifier(repository);
    });

class MenuAnalysisNotifier
    extends StateNotifier<AsyncValue<List<MenuAnalysisResult>>> {
  final MenuRepository _repository;

  MenuAnalysisNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> analyzeMenu(String filePath) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.uploadMenuImage(filePath);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
