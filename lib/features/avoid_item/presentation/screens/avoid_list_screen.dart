import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/avoid_item_provider.dart';

class AvoidListScreen extends ConsumerWidget {
  const AvoidListScreen({super.key});

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F1), Color(0xFFF2F7F6), Color(0xFFFCFEFD)],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avoidItemsAsync = ref.watch(myAvoidItemsProvider);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
          ),
          child: Text(
            tr('avoid.list_title'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3030),
              fontSize: 18,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.9)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7FA7A0).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF253636),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: _backgroundGradient),
          ),
          IgnorePointer(child: _buildBackgroundVegetableIcon()),
          SafeArea(
            top: false,
            child: avoidItemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F8E83)),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Color(0xFFD94B3A),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        tr(
                          'avoid.load_failed_with_message',
                          namedArgs: {'message': err.toString()},
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF5F7070)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(myAvoidItemsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F8E83),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(tr('common.retry')),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  color: const Color(0xFF0F8E83),
                  onRefresh: () async => ref.invalidate(myAvoidItemsProvider),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, topInset, 16, 16),
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildSummaryCard(items.length),
                          );
                        }

                        final item = items[index - 1];
                        return Dismissible(
                          key: Key(item),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE25545),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _handleRemove(context, ref, item),
                          child: _buildAvoidItemTile(
                            item: item,
                            onRemove: () => _handleRemove(context, ref, item),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundVegetableIcon() {
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF7AA39D).withValues(alpha: 0.035),
        ),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Icon(
            Icons.apple_rounded,
            size: 126,
            color: const Color(0xFF678A85).withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int itemCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8DAEA8).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF0F8E83).withOpacity(0.12),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Color(0xFF0F8E83),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('avoid.total_items', namedArgs: {'count': '$itemCount'}),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4D6260),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvoidItemTile({
    required String item,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF0F8E83).withOpacity(0.12),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            size: 24,
            color: Color(0xFF0F8E83),
          ),
        ),
        title: Text(
          item,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF213434),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.cancel_rounded,
            color: Color(0xFFDF7176),
            size: 26,
          ),
          onPressed: onRemove,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tr('avoid.empty_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B4D4B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('avoid.empty_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7C7B)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRemove(BuildContext context, WidgetRef ref, String item) async {
    try {
      await ref.read(avoidItemNotifierProvider.notifier).removeItem(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('avoid.remove_success', namedArgs: {'item': item}),
            ),
            backgroundColor: const Color(0xFF0F8E83),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'avoid.remove_failed_with_message',
                namedArgs: {'message': e.toString()},
              ),
            ),
            backgroundColor: const Color(0xFFD94B3A),
          ),
        );
      }
    }
  }
}
