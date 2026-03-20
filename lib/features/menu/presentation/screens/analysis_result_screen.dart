import 'dart:io';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../history/presentation/providers/history_provider.dart';
import '../../data/repositories/menu_repository.dart';
import '../providers/menu_provider.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final int? teamMemberId;

  const AnalysisResultScreen({
    super.key,
    required this.imagePath,
    this.teamMemberId,
  });

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  final DateTime _analyzedAt = DateTime.now();

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F1), Color(0xFFF2F7F6), Color(0xFFFCFEFD)],
    stops: [0, 0.55, 1],
  );

  void _showFullImage(BuildContext context, String imagePath) {
    final isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

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
                child: (kIsWeb || isNetworkImage)
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

  Color _getLevelColor(String safetyLevel) {
    switch (safetyLevel) {
      case 'safe':
        return const Color(0xFF179166);
      case 'caution':
        return const Color(0xFFF08C00);
      case 'danger':
        return const Color(0xFFE25545);
      default:
        return const Color(0xFF6E7C7A);
    }
  }

  IconData _getLevelIcon(String safetyLevel) {
    switch (safetyLevel) {
      case 'safe':
        return Icons.check_circle_outline_rounded;
      case 'caution':
        return Icons.info_outline_rounded;
      case 'danger':
        return Icons.warning_amber_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getSafetyLabel(String safetyLevel) {
    switch (safetyLevel) {
      case 'safe':
        return tr('history_detail.safety.safe');
      case 'caution':
        return tr('history_detail.safety.caution');
      case 'danger':
        return tr('history_detail.safety.danger');
      default:
        return '';
    }
  }

  String _menuNameOrUnknown(String menuName) {
    final normalized = menuName.trim();
    if (normalized.isEmpty) return tr('common.unknown');
    return normalized;
  }

  List<MenuAnalysisResult> _pickTopRecommendations(
    List<MenuAnalysisResult> results, {
    int limit = 5,
  }) {
    if (results.isEmpty || limit <= 0) return [];

    int rank(String level) {
      switch (level) {
        case 'safe':
          return 0;
        case 'caution':
          return 1;
        case 'danger':
          return 2;
        default:
          return 3;
      }
    }

    final sorted = [...results]
      ..sort((a, b) {
        final riskCompare = a.risk.compareTo(b.risk);
        if (riskCompare != 0) return riskCompare;

        final scoreCompare = b.safetyScore.compareTo(a.safetyScore);
        if (scoreCompare != 0) return scoreCompare;

        final confidenceCompare = b.confidence.compareTo(a.confidence);
        if (confidenceCompare != 0) return confidenceCompare;

        final levelCompare = rank(a.safetyLevel).compareTo(rank(b.safetyLevel));
        if (levelCompare != 0) return levelCompare;

        return _menuNameOrUnknown(
          a.menuName,
        ).compareTo(_menuNameOrUnknown(b.menuName));
      });
    return sorted.take(limit).toList();
  }

  Widget _buildRecommendationSummaryCard(
    List<MenuAnalysisResult> recommended,
    List<String> resultImageUrls,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6F4A2B), Color(0xFF5E3F25), Color(0xFF6B4729)],
          stops: [0, 0.5, 1],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF7C5636), width: 1.2),
        boxShadow: [
          const BoxShadow(
            color: Color(0x3A3B2415),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _WoodGrainPainter()),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDFC7A2),
                    ),
                    child: const Icon(
                      Icons.thumb_up_alt_outlined,
                      color: Color(0xFF5A3A23),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('history_detail.ai_best_menu'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF4E3C8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            fontFamily: 'Noto Serif KR',
                            fontFamilyFallback: ['Nanum Myeongjo', 'serif'],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          tr('history_detail.low_risk_priority'),
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE7D2B4),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Noto Serif KR',
                            fontFamilyFallback: ['Nanum Myeongjo', 'serif'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildResultImageButton(resultImageUrls),
                ],
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < recommended.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _menuNameOrUnknown(recommended[i].menuName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFFF4E3C8),
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Noto Serif KR',
                            fontFamilyFallback: ['Nanum Myeongjo', 'serif'],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFC7A2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tr(
                            'common.points',
                            namedArgs: {
                              'value': '${recommended[i].safetyScore}',
                            },
                          ),
                          style: const TextStyle(
                            color: Color(0xFF5A3A23),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            fontFamily: 'Noto Serif KR',
                            fontFamilyFallback: ['Nanum Myeongjo', 'serif'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != recommended.length - 1) const SizedBox(height: 2),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultImageButton(List<String> resultImageUrls) {
    return TextButton.icon(
      onPressed: () {
        if (resultImageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('analysis_result.result_image_not_found')),
            ),
          );
          return;
        }
        _showFullImage(context, resultImageUrls.first);
      },
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFDFC7A2).withValues(alpha: 0.92),
        foregroundColor: const Color(0xFF5A3A23),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.photo_library_outlined, size: 14),
      label: Text(
        tr('analysis_result.show_result_image'),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Noto Serif KR',
          fontFamilyFallback: ['Nanum Myeongjo', 'serif'],
        ),
      ),
    );
  }

  String _joinValues(List<String> values, {String fallback = '-'}) {
    if (values.isEmpty) return fallback;
    return values.where((e) => e.trim().isNotEmpty).join(', ');
  }

  String _localizedReason(String rawReason) {
    final normalized = rawReason.trim();
    if (normalized.isEmpty) return '-';

    if (normalized.contains('기피 재료 근거 부족')) {
      return tr('history_detail.reason_insufficient_evidence');
    }
    if (normalized.contains('위험도 판단 실패')) {
      return tr('history_detail.reason_fallback');
    }

    final lower = normalized.toLowerCase();
    if (lower.contains('insufficient avoid-ingredient evidence')) {
      return tr('history_detail.reason_insufficient_evidence');
    }
    if (lower.contains('risk assessment failed')) {
      return tr('history_detail.reason_fallback');
    }

    final cautionMatch = RegExp(
      r'^Caution:\s*(.+?)\s*\((common recipe|direct evidence)\)(\s*\(low confidence\))?$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (cautionMatch != null) {
      final ingredient = cautionMatch.group(1)?.trim() ?? '';
      final source = cautionMatch.group(2)?.toLowerCase() ?? '';
      final sourceLabel = source == 'direct evidence'
          ? tr('history_detail.reason_source_direct')
          : tr('history_detail.reason_source_common');
      final suffix = cautionMatch.group(3) != null
          ? tr('history_detail.reason_low_confidence_suffix')
          : '';

      return tr(
        'history_detail.reason_caution',
        namedArgs: {
          'ingredient': ingredient,
          'source': sourceLabel,
          'suffix': suffix,
        },
      );
    }

    return normalized;
  }

  Widget _buildFallbackSummaryCard(int fallbackCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C58F)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFBF6B1C),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr(
                'history_detail.fallback_summary',
                namedArgs: {'count': '$fallbackCount'},
              ),
              style: const TextStyle(
                color: Color(0xFF7A4A1E),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItemCard(MenuAnalysisResult item) {
    final levelColor = _getLevelColor(item.safetyLevel);
    final levelLabel = _getSafetyLabel(item.safetyLevel);
    final confidencePercent = (item.confidence * 100).round().clamp(0, 100);
    final matchedAvoidText = _joinValues(item.matchedAvoid);
    final suspectedText = _joinValues(item.suspectedIngredients);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.60),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF95B2AC).withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.30),
            blurRadius: 7,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _menuNameOrUnknown(item.menuName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF223535),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: levelColor.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLevelIcon(item.safetyLevel),
                      size: 14,
                      color: levelColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      tr(
                        'history_detail.safety_score',
                        namedArgs: {
                          'label': levelLabel,
                          'score': '${item.safetyScore}',
                        },
                      ),
                      style: TextStyle(
                        color: levelColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _localizedReason(item.reason),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF556765),
              height: 1.25,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMetaPill(
                icon: Icons.speed_rounded,
                label: tr(
                  'history_detail.meta_risk',
                  namedArgs: {'value': '${item.risk}'},
                ),
                textColor: const Color(0xFF8C5E2E),
                bgColor: const Color(0xFFFFF3E6),
                borderColor: const Color(0xFFF4CC9D),
              ),
              _buildMetaPill(
                icon: Icons.analytics_rounded,
                label: tr(
                  'history_detail.meta_confidence',
                  namedArgs: {'value': '$confidencePercent'},
                ),
                textColor: const Color(0xFF275E8F),
                bgColor: const Color(0xFFEAF3FC),
                borderColor: const Color(0xFFC4DAF0),
              ),
              if (item.isConservativeFallback)
                _buildMetaPill(
                  icon: Icons.warning_amber_rounded,
                  label: tr('history_detail.meta_conservative'),
                  textColor: const Color(0xFF8E4C1C),
                  bgColor: const Color(0xFFFFF2E4),
                  borderColor: const Color(0xFFF2C48E),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'history_detail.matched_avoid',
              namedArgs: {'value': matchedAvoidText},
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF49615E),
              height: 1.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'history_detail.suspected_ingredients',
              namedArgs: {'value': suspectedText},
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5A6D6A),
              height: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(menuAnalysisProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(historyListProvider.notifier).refresh();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: _backgroundGradient),
          child: analysisState.when(
            loading: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0F8E83)),
                  const SizedBox(height: 16),
                  Text(tr('analysis_result.analyzing')),
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
            data: (searchResult) {
              final results = searchResult.items;
              final recommended = _pickTopRecommendations(results, limit: 7);
              final fallbackCount = results
                  .where((item) => item.isConservativeFallback)
                  .length;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 240,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                          color: const Color(0xFF213434),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    title: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      child: Text(
                        tr('analysis_result.title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F3030),
                          fontSize: 18,
                        ),
                      ),
                    ),
                    centerTitle: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: EdgeInsets.only(
                          top:
                              MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              4,
                          left: 14,
                          right: 14,
                          bottom: 6,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              _showFullImage(context, widget.imagePath),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb
                                  ? Image.network(
                                      widget.imagePath,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.cover,
                                    ),
                              const IgnorePointer(
                                child: Center(child: _ZoomHintOverlay()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (results.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(tr('analysis_result.no_items')),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: Color(0xFF617D7A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'yyyy.MM.dd HH:mm',
                              ).format(_analyzedAt),
                              style: TextStyle(
                                color: Color(0xFF617D7A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              ' / ',
                              style: TextStyle(
                                color: Color(0xFF617D7A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              tr(
                                'history_detail.items_analyzed',
                                namedArgs: {'count': '${results.length}'},
                              ),
                              style: const TextStyle(
                                color: Color(0xFF617D7A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (fallbackCount > 0)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        sliver: SliverToBoxAdapter(
                          child: _buildFallbackSummaryCard(fallbackCount),
                        ),
                      ),
                    if (recommended.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        sliver: SliverToBoxAdapter(
                          child: _buildRecommendationSummaryCard(
                            recommended,
                            searchResult.resultImageUrls,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          tr('history_detail.safety_hint'),
                          style: TextStyle(
                            color: Color(0xFF6A8380),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = results[index];
                          return _buildResultItemCard(item);
                        }, childCount: results.length),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ZoomHintOverlay extends StatelessWidget {
  const _ZoomHintOverlay();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.zoom_in_rounded,
      size: 34,
      color: Colors.white.withValues(alpha: 0.84),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    for (double y = 6; y < size.height; y += 11) {
      final path = Path()..moveTo(0, y);
      final amplitude = 1.2 + ((math.sin(y * 0.08) + 1) * 0.8);
      final phase = y * 0.045;
      for (double x = 0; x <= size.width; x += 9) {
        final offsetY = math.sin((x * 0.038) + phase) * amplitude;
        path.lineTo(x, y + offsetY);
      }
      final alpha = 0.05 + ((math.sin(y * 0.1) + 1) * 0.035);
      paint.color = const Color(0xFFF2D9B8).withValues(alpha: alpha);
      canvas.drawPath(path, paint);
    }

    final knotPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFD4A778).withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.34),
        width: size.width * 0.18,
        height: 20,
      ),
      knotPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.68),
        width: size.width * 0.22,
        height: 24,
      ),
      knotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
