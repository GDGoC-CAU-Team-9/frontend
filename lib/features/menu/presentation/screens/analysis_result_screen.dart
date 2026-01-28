import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../providers/menu_provider.dart';
import '../../data/repositories/menu_repository.dart';
import '../../../../core/theme/app_design.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const AnalysisResultScreen({super.key, required this.imagePath});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
  }

  Color _getScoreColor(String safetyLevel) {
    switch (safetyLevel) {
      case 'safe':
        return Colors.green;
      case 'caution':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(menuAnalysisProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '분석 결과',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: Colors.black87,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppDesign.backgroundGradient,
            ),
          ),
          Column(
            children: [
              // Display the scanned image thumbnail with blur header effect maybe?
              // For now just top padding to avoid AppBar overlap if not using Sliver
              // Actually, let's keep it simple.
              SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: kIsWeb
                        ? Image.network(widget.imagePath, fit: BoxFit.cover)
                        : Image.file(File(widget.imagePath), fit: BoxFit.cover),
                  ),
                ),
              ),

              Expanded(
                child: analysisState.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('AI가 메뉴판을 분석 중입니다...'),
                      ],
                    ),
                  ),
                  error: (err, stack) => Center(child: Text('오류 발생: $err')),
                  data: (results) {
                    if (results.isEmpty) {
                      return const Center(child: Text('분석된 메뉴가 없습니다.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return Container(
                          // Replaced Card with Glass Container
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: AppDesign.glassDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.menuName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(
                                        item.safetyLevel,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getScoreColor(item.safetyLevel),
                                      ),
                                    ),
                                    child: Text(
                                      '${item.safetyScore}점',
                                      style: TextStyle(
                                        color: _getScoreColor(item.safetyLevel),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.reason,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
