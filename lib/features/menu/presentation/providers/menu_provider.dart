import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/menu_repository.dart';

// State provider to hold the analysis results
final menuAnalysisProvider =
    StateNotifierProvider<MenuAnalysisNotifier, AsyncValue<SearchResult>>((
      ref,
    ) {
      final repository = ref.watch(menuRepositoryProvider);
      return MenuAnalysisNotifier(repository);
    });

class MenuAnalysisNotifier extends StateNotifier<AsyncValue<SearchResult>> {
  final MenuRepository _repository;

  MenuAnalysisNotifier(this._repository)
    : super(AsyncValue.data(SearchResult(items: [])));

  Future<void> analyzeMenu(
    XFile file, {
    int? teamMemberId,
    required String menuLang,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Backend automatically fetches user's avoid items
      final result = await _repository.uploadMenuImage(
        file,
        teamMemberId: teamMemberId,
        menuLang: menuLang,
      );
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
