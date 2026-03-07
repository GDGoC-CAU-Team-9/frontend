import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/history_repository.dart';

/// State for the history list with pagination
class HistoryListState {
  final List<HistoryItem> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  const HistoryListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
  });

  HistoryListState copyWith({
    List<HistoryItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return HistoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for history list with pagination support
class HistoryListNotifier extends StateNotifier<HistoryListState> {
  final HistoryRepository _repository;

  HistoryListNotifier(this._repository) : super(const HistoryListState());

  /// Load the first page (or refresh)
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _repository.getHistories(1);
      state = HistoryListState(
        items: page.items,
        isLoading: false,
        hasMore: page.totalPages > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Load the next page
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true);
    try {
      final page = await _repository.getHistories(nextPage);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        isLoading: false,
        hasMore: nextPage < page.totalPages,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Refresh from scratch
  Future<void> refresh() async {
    state = const HistoryListState();
    await loadInitial();
  }
}

final historyListProvider =
    StateNotifierProvider<HistoryListNotifier, HistoryListState>((ref) {
      final repository = ref.watch(historyRepositoryProvider);
      return HistoryListNotifier(repository);
    });
