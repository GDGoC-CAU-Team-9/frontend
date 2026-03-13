import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../providers/menu_provider.dart';
import '../../../../core/theme/app_design.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const AnalysisResultScreen({super.key, required this.imagePath});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: kIsWeb
                    ? Image.network(imagePath, fit: BoxFit.contain)
                    : Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: analysisState.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('analysis_result.analyzing'.tr()),
              ],
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              tr(
                'analysis_result.error_with_message',
                namedArgs: {'message': err.toString()},
              ),
            ),
          ),
          data: (results) {
            return CustomScrollView(
              slivers: [
                // Collapsible image header
                SliverAppBar(
                  expandedHeight: 300,
                  collapsedHeight: 60,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
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
                  title: Text(
                    tr('analysis_result.title'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: EdgeInsets.only(
                        top:
                            MediaQuery.of(context).padding.top + kToolbarHeight,
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: GestureDetector(
                        onTap: () => _showFullImage(context, widget.imagePath),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: kIsWeb
                              ? Image.network(
                                  widget.imagePath,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Results list
                if (results.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: Text(tr('analysis_result.no_items'))),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = results[index];
                        return Container(
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
                                  Expanded(
                                    child: Text(
                                      item.menuName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
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
                                      tr(
                                        'common.points',
                                        namedArgs: {'value': '${item.safetyScore}'},
                                      ),
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
                      }, childCount: results.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
