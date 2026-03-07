import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/avoid_item_repository.dart';

/// 내 기피재료 목록 조회
final myAvoidItemsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(avoidItemRepositoryProvider);
  return repository.getMyAvoidItems();
});

/// 기피재료 입력/추출/저장 상태 관리
class AvoidItemNotifier extends StateNotifier<AvoidItemState> {
  final AvoidItemRepository _repository;
  final Ref _ref;

  AvoidItemNotifier(this._repository, this._ref) : super(AvoidItemState());

  /// AI로 기피재료 추출
  Future<void> extractFromText(String text) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.extractAvoidItems(text);
      state = state.copyWith(
        isLoading: false,
        extractedItems: result.avoidItems,
        confirmQuestion: result.confirmQuestion,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 추출 결과에서 아이템 토글 (선택/해제)
  void toggleItem(String item) {
    final current = List<String>.from(state.extractedItems);
    if (current.contains(item)) {
      current.remove(item);
    } else {
      current.add(item);
    }
    state = state.copyWith(extractedItems: current);
  }

  /// 추출된 기피재료를 서버에 저장
  Future<void> saveExtractedItems() async {
    if (state.extractedItems.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // 기존 아이템을 가져와서 합침
      final existing = await _repository.getMyAvoidItems();
      final merged = <String>{...existing, ...state.extractedItems}.toList();
      await _repository.saveAvoidItems(merged);
      _ref.invalidate(myAvoidItemsProvider);
      state = state.copyWith(
        isLoading: false,
        isSaved: true,
        extractedItems: [],
        confirmQuestion: '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 기존 기피재료 목록에서 아이템 삭제
  Future<void> removeItem(String item) async {
    try {
      final existing = await _repository.getMyAvoidItems();
      final updated = existing.where((i) => i != item).toList();
      await _repository.saveAvoidItems(updated);
      _ref.invalidate(myAvoidItemsProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 상태 초기화
  void reset() {
    state = AvoidItemState();
  }
}

class AvoidItemState {
  final bool isLoading;
  final List<String> extractedItems;
  final String confirmQuestion;
  final String? error;
  final bool isSaved;

  AvoidItemState({
    this.isLoading = false,
    this.extractedItems = const [],
    this.confirmQuestion = '',
    this.error,
    this.isSaved = false,
  });

  AvoidItemState copyWith({
    bool? isLoading,
    List<String>? extractedItems,
    String? confirmQuestion,
    String? error,
    bool? isSaved,
  }) {
    return AvoidItemState(
      isLoading: isLoading ?? this.isLoading,
      extractedItems: extractedItems ?? this.extractedItems,
      confirmQuestion: confirmQuestion ?? this.confirmQuestion,
      error: error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

final avoidItemNotifierProvider =
    StateNotifierProvider<AvoidItemNotifier, AvoidItemState>((ref) {
      final repository = ref.watch(avoidItemRepositoryProvider);
      return AvoidItemNotifier(repository, ref);
    });
