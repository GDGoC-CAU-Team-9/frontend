import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/menu_provider.dart';
import '../../../../core/theme/app_design.dart';

class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  final XFile imageFile;

  const AnalysisLoadingScreen({super.key, required this.imageFile});

  @override
  ConsumerState<AnalysisLoadingScreen> createState() =>
      _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends ConsumerState<AnalysisLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  // Step animations
  bool _step1 = false;
  bool _step2 = false;
  bool _step3 = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Total estimated duration
    )..repeat();

    // Start analysis
    Future.microtask(() {
      ref.read(menuAnalysisProvider.notifier).analyzeMenu(widget.imageFile);
    });

    // Simulate step progress matching the mock repository delay (2 seconds)
    _startStepAnimations();
  }

  void _startStepAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _step1 = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _step2 = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _step3 = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for completion
    ref.listen(menuAnalysisProvider, (previous, next) {
      next.whenData((results) {
        // Add a small delay to let the last animation finish visually
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pushReplacement(
              '/analysis-result',
              extra: widget
                  .imageFile
                  .path, // We can pass path here for display, AnalysisResult can handle dynamic or just String
            );
          }
        });
      });
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background (Gradient or Blured Image)
          Container(
            decoration: const BoxDecoration(
              gradient: AppDesign.backgroundGradient,
            ),
          ),

          // 2. Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SafePlate Logo/Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera, // Placeholder for App Icon
                    size: 40,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('SafePlate', style: AppDesign.logoTextStyle),
                const SizedBox(height: 60),

                // Premium Glassmorphism Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(24),
                      decoration: AppDesign.glassDecoration,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '메뉴판 이미지를 분석하고 있어요...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI가 메뉴 이름과 재료를 인식 중입니다...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Steps
                          _buildStepItem('메뉴 텍스트 인식', _step1),
                          const SizedBox(height: 12),
                          _buildStepItem('재료 성분 분석', _step2),
                          const SizedBox(height: 12),
                          _buildStepItem('알러지 위험 진단', _step3),

                          const SizedBox(height: 30),

                          // Linear Progress Indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const LinearProgressIndicator(
                              backgroundColor: Color(0xFFE0E0E0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.teal,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 3. Cancel Button
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // Fallback if can't pop (e.g. opened directly, though unlikely here)
                      context.go('/home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String text, bool completed) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: completed ? Colors.teal : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[500]!,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: completed ? Colors.black87 : Colors.grey[500],
            fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
