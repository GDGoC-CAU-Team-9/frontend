import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  Widget _buildBestCard() {
    final best = historyItem.best;
    if (best == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8FB8B1).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F8E83).withOpacity(0.12),
            ),
            child: const Icon(
              Icons.thumb_up_alt_outlined,
              color: Color(0xFF0F8E83),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('history_detail.ai_best_menu'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3D6360),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  best.menuName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0E6E67),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F8E83),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tr('common.points', namedArgs: {'value': '${best.safetyScore}'}),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(item) {
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
                  item.menuName,
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
            if (historyItem.best != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                sliver: SliverToBoxAdapter(child: _buildBestCard()),
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
