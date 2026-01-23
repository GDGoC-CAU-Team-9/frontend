import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/allergy_repository.dart';
import '../../data/models/allergy_model.dart';

// Provider to fetch all available allergies
final allergiesProvider = FutureProvider<List<Allergy>>((ref) async {
  final repository = ref.watch(allergyRepositoryProvider);
  return repository.getAllergies();
});

// Provider to fetch user's selected allergies
final myAllergiesProvider = FutureProvider<List<Allergy>>((ref) async {
  final repository = ref.watch(allergyRepositoryProvider);
  return repository.getMyAllergies();
});

// StateNotifier to manage the selection state for the UI
class AllergySelectionNotifier extends StateNotifier<Set<int>> {
  final AllergyRepository _repository;
  final Ref _ref;

  AllergySelectionNotifier(this._repository, this._ref) : super({});

  // Initialize with existing user allergies
  void initialize(List<Allergy> myAllergies) {
    state = myAllergies.map((e) => e.id).toSet();
  }

  void toggleAllergy(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
    }
  }

  Future<void> saveMyAllergies() async {
    await _repository.updateMyAllergies(state.toList());
    _ref.invalidate(
      myAllergiesProvider,
    ); // Invalidate cache to force refetch next time
  }
}

final allergySelectionProvider =
    StateNotifierProvider<AllergySelectionNotifier, Set<int>>((ref) {
      final repository = ref.watch(allergyRepositoryProvider);
      return AllergySelectionNotifier(repository, ref);
    });
