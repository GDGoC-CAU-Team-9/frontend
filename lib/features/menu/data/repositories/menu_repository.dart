import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model for Analysis Result (Temporary placement, can be moved to models folder later)
class MenuAnalysisResult {
  final String menuName;
  final int safetyScore; // 0-100
  final String reason;
  final String safetyLevel; // 'safe', 'caution', 'danger'

  MenuAnalysisResult({
    required this.menuName,
    required this.safetyScore,
    required this.reason,
    required this.safetyLevel,
  });
}

class MenuRepository {
  Future<List<MenuAnalysisResult>> uploadMenuImage(String filePath) async {
    // TODO: Implement actual API call using Dio
    // For now, return mock data after a short delay
    await Future.delayed(const Duration(seconds: 2));

    return [
      MenuAnalysisResult(
        menuName: "새우 볶음밥",
        safetyScore: 30,
        reason: "사용자의 기피 재료인 '갑각류(새우)'가 포함되어 있습니다.",
        safetyLevel: "danger",
      ),
      MenuAnalysisResult(
        menuName: "계란국",
        safetyScore: 95,
        reason: "기피 재료가 발견되지 않았습니다.",
        safetyLevel: "safe",
      ),
      MenuAnalysisResult(
        menuName: "마파두부",
        safetyScore: 60,
        reason: "매운 소스에 알 수 없는 향신료가 포함될 수 있어 주의가 필요합니다.",
        safetyLevel: "caution",
      ),
    ];
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository();
});
