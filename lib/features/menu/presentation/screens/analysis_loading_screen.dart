import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/error_utils.dart';
import '../providers/menu_provider.dart';
import '../../../../core/theme/app_design.dart';

class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  final XFile imageFile;
  final int? teamMemberId;
  final String menuLang;

  const AnalysisLoadingScreen({
    super.key,
    required this.imageFile,
    this.teamMemberId,
    required this.menuLang,
  });

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
      ref
          .read(menuAnalysisProvider.notifier)
          .analyzeMenu(
            widget.imageFile,
            teamMemberId: widget.teamMemberId,
            menuLang: widget.menuLang,
          );
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
    final analysisState = ref.watch(menuAnalysisProvider);
    final rawError = analysisState.whenOrNull(error: (error, _) => error);
    final errorMessage = rawError == null
        ? tr('common.unknown_error')
        : _friendlyErrorMessage(rawError);

    final closeIcon = analysisState.hasError
        ? Icons.arrow_back_ios_new_rounded
        : Icons.close;

    void closeAction() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    ref.listen(menuAnalysisProvider, (previous, next) {
      if (previous != null && previous.hasError && next.isLoading) {
        setState(() {
          _step1 = false;
          _step2 = false;
          _step3 = false;
        });
        _startStepAnimations();
      }
      next.whenData((results) {
        final router = GoRouter.of(context);
        // Add a small delay to let the last animation finish visually
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            router.pushReplacement(
              '/analysis-result',
              extra: {
                'imagePath': widget.imageFile.path,
                'teamMemberId': widget.teamMemberId,
              },
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
            child: analysisState.hasError
                ? _buildErrorCard(context, errorMessage)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SafePlate Logo/Icon
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
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
                                Text(
                                  tr('analysis_loading.title'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tr('analysis_loading.description'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Steps
                                _buildStepItem(
                                  tr('analysis_loading.step_text'),
                                  _step1,
                                ),
                                const SizedBox(height: 12),
                                _buildStepItem(
                                  tr('analysis_loading.step_ingredient'),
                                  _step2,
                                ),
                                const SizedBox(height: 12),
                                _buildStepItem(
                                  tr('analysis_loading.step_risk'),
                                  _step3,
                                ),

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
                  onTap: closeAction,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(closeIcon, color: Colors.black54, size: 24),
                      ),
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

  String _friendlyErrorMessage(Object error) {
    final fallback = tr('common.unknown_error');
    final extracted = toUserMessage(error, fallback: fallback);
    if (extracted != fallback) return _normalizeErrorText(extracted, fallback);
    return _normalizeErrorText(error.toString(), fallback);
  }

  String _normalizeErrorText(String raw, String fallback) {
    var text = raw.trim();
    text = text.replaceFirst(
      RegExp(r'^Exception:\s*', caseSensitive: false),
      '',
    );
    text = text.replaceFirst(
      RegExp(r'^DioException(\s*\[[^\]]+\])?:\s*', caseSensitive: false),
      '',
    );
    if (text.isEmpty || text.toLowerCase() == 'exception') return fallback;
    return text;
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5FAF9), Color(0xFFEAF4F1)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.95)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF486965).withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEB5450).withOpacity(0.12),
                  border: Border.all(
                    color: const Color(0xFFEB5450).withOpacity(0.25),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEB5450),
                  size: 46,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr('analysis_loading.failed_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2E2D),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.58),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE1ECE9)),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A6A68),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(menuAnalysisProvider.notifier)
                            .analyzeMenu(
                              widget.imageFile,
                              teamMemberId: widget.teamMemberId,
                              menuLang: widget.menuLang,
                            );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(tr('common.retry')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF23756E),
                        side: BorderSide(
                          color: const Color(0xFF23756E).withOpacity(0.28),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF17A89B), Color(0xFF0D847B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D847B).withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(tr('analysis_loading.back_to_previous')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
