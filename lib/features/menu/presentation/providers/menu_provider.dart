import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/menu_repository.dart';
import '../../../../features/allergy/presentation/providers/allergy_provider.dart';

// State provider to hold the analysis results
final menuAnalysisProvider =
    StateNotifierProvider<
      MenuAnalysisNotifier,
      AsyncValue<List<MenuAnalysisResult>>
    >((ref) {
      final repository = ref.watch(menuRepositoryProvider);
      return MenuAnalysisNotifier(repository, ref);
    });

class MenuAnalysisNotifier
    extends StateNotifier<AsyncValue<List<MenuAnalysisResult>>> {
  final MenuRepository _repository;
  final Ref _ref;

  MenuAnalysisNotifier(this._repository, this._ref)
    : super(const AsyncValue.data([]));

  Future<void> analyzeMenu(XFile file) async {
    state = const AsyncValue.loading();
    try {
      // Fetch user's allergies
      final myAllergiesState = await _ref.read(myAllergiesProvider.future);
      final List<String> avoidList = myAllergiesState
          .map((e) => e.name)
          .toList();

      print('Analyzing with avoid list: $avoidList');

      final result = await _repository.uploadMenuImage(file, avoidList);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
