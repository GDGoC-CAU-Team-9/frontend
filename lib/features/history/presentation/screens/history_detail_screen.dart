import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../menu/data/repositories/menu_repository.dart';
import '../../data/repositories/history_repository.dart';

class HistoryDetailScreen extends StatelessWidget {
  final HistoryItem historyItem;

  const HistoryDetailScreen({super.key, required this.historyItem});

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F1), Color(0xFFF2F7F6), Color(0xFFFCFEFD)],
    stops: [0, 0.55, 1],
  );

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
        return tr('history_detail.safety.unknown');
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
        final scoreCompare = b.safetyScore.compareTo(a.safetyScore);
        if (scoreCompare != 0) return scoreCompare;

        final levelCompare = rank(a.safetyLevel).compareTo(rank(b.safetyLevel));
        if (levelCompare != 0) return levelCompare;

        return _menuNameOrUnknown(
          a.menuName,
        ).compareTo(_menuNameOrUnknown(b.menuName));
      });
    return sorted.take(limit).toList();
  }

  void _showFullImage(BuildContext context, String imageUrl) {
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
                child: Image.network(imageUrl, fit: BoxFit.contain),
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

  Widget _buildRecommendationCard(List<MenuAnalysisResult> recommended) {
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
                    child: Text(
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
                  ),
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
                      '${recommended.length}',
                      style: const TextStyle(
                        color: Color(0xFF5A3A23),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
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

  Widget _buildItemCard(MenuAnalysisResult item) {
    final levelColor = _getLevelColor(item.safetyLevel);
    final levelLabel = _getSafetyLabel(item.safetyLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.92)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF98B8B2).withOpacity(0.15),
            blurRadius: 9,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: levelColor.withOpacity(0.7)),
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
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF556765),
                height: 1.25,
                fontSize: 14,
              ),
            ),
          ],
          if (item.matchedAvoid.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.matchedAvoid
                  .map<Widget>(
                    (avoid) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE25545).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE25545).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        avoid,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD84939),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommended = _pickTopRecommendations(historyItem.items, limit: 5);
    final dateStr =
        '${historyItem.createdAt.year}.${historyItem.createdAt.month.toString().padLeft(2, '0')}.${historyItem.createdAt.day.toString().padLeft(2, '0')} ${historyItem.createdAt.hour.toString().padLeft(2, '0')}:${historyItem.createdAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: CustomScrollView(
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
                    border: Border.all(color: Colors.white.withOpacity(0.9)),
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
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                ),
                child: Text(
                  tr('history_detail.title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F3030),
                    fontSize: 18,
                  ),
                ),
              ),
              centerTitle: true,
              flexibleSpace: historyItem.imageUrls.isNotEmpty
                  ? FlexibleSpaceBar(
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
                          onTap: () => _showFullImage(
                            context,
                            historyItem.imageUrls.first,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              historyItem.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFD9E8E5),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Color(0xFF759E97),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
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
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFF617D7A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tr(
                        'history_detail.items_analyzed',
                        namedArgs: {'count': '${historyItem.items.length}'},
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
            if (recommended.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                sliver: SliverToBoxAdapter(
                  child: _buildRecommendationCard(recommended),
                ),
              ),
            if (historyItem.items.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text(tr('history_detail.no_items'))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = historyItem.items[index];
                    return _buildItemCard(item);
                  }, childCount: historyItem.items.length),
                ),
              ),
          ],
        ),
      ),
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
