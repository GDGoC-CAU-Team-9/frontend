import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import 'dart:developer' as developer;

final teamListProvider =
    StateNotifierProvider.autoDispose<
      TeamListNotifier,
      AsyncValue<List<TeamModel>>
    >((ref) {
      final repository = ref.watch(teamRepositoryProvider);
      return TeamListNotifier(repository);
    });

class TeamListNotifier extends StateNotifier<AsyncValue<List<TeamModel>>> {
  final TeamRepository _repository;
  int _currentPage = 1;
  bool _hasMore = true;

  TeamListNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = const AsyncValue.loading();
    _currentPage = 1;
    _hasMore = true;
    try {
      // Backend expects 1-based pageNumber for my teams (based on history API pattern)
      final result = await _repository.getMyTeams(_currentPage);
      _hasMore = _currentPage < result.totalPages;
      state = AsyncValue.data(result.teamMembers);
    } catch (e, st) {
      developer.log(
        'Failed to fetch initial teams',
        name: 'TeamListNotifier',
        error: e,
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state is! AsyncData || state.value == null) return;

    _currentPage++;
    try {
      final result = await _repository.getMyTeams(_currentPage);
      _hasMore = _currentPage < result.totalPages;
      state = AsyncValue.data([...state.value!, ...result.teamMembers]);
    } catch (e) {
      developer.log(
        'Failed to load more teams',
        name: 'TeamListNotifier',
        error: e,
      );
      _currentPage--;
      // Optionally handle error visually, state keeps previous items
    }
  }

  Future<bool> createTeam(String teamName) async {
    try {
      await _repository.createTeam(teamName);
      await fetchInitial(); // Refresh list after creation
      return true;
    } catch (e) {
      developer.log(
        'Failed to create team',
        name: 'TeamListNotifier',
        error: e,
      );
      return false;
    }
  }

  Future<bool> joinTeam(String email, int id, String teamName) async {
    try {
      await _repository.joinTeam(
        teamMemberEmail: email,
        teamMemberId: id,
        teamName: teamName,
      );
      await fetchInitial(); // Refresh list after join
      return true;
    } catch (e) {
      developer.log('Failed to join team', name: 'TeamListNotifier', error: e);
      return false;
    }
  }
}

final teamDetailProvider = FutureProvider.autoDispose.family<TeamModel, int>((
  ref,
  teamMemberId,
) async {
  final repository = ref.watch(teamRepositoryProvider);
  return repository.getTeamDetail(teamMemberId);
});
