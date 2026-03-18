import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/avoid_item_provider.dart';

class AvoidInputScreen extends ConsumerStatefulWidget {
  const AvoidInputScreen({super.key});

  @override
  ConsumerState<AvoidInputScreen> createState() => _AvoidInputScreenState();
}

class _AvoidInputScreenState extends ConsumerState<AvoidInputScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F1), Color(0xFFF2F7F6), Color(0xFFFCFEFD)],
    stops: [0, 0.55, 1],
  );

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _textController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(avoidItemNotifierProvider);

    ref.listen<AvoidItemState>(avoidItemNotifierProvider, (prev, next) {
      if (next.extractedItems.isNotEmpty &&
          (prev?.extractedItems.isEmpty ?? true)) {
        _animController.forward(from: 0);
      }
      if (next.isSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('avoid.saved_success')),
            backgroundColor: const Color(0xFF0F8E83),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.read(avoidItemNotifierProvider.notifier).reset();
        _textController.clear();
      }
    });

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
            tr('avoid.input_title'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3030),
              fontSize: 18,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.9)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF253636),
              onPressed: () {
                ref.read(avoidItemNotifierProvider.notifier).reset();
                context.pop();
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: _backgroundGradient),
          ),
          IgnorePointer(child: _buildBackgroundInputIcon()),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.62),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8DAEA8,
                                  ).withOpacity(0.2),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF0F8E83,
                                    ).withOpacity(0.12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF0F8E83,
                                      ).withOpacity(0.18),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 32,
                                    color: Color(0xFF0F8E83),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('avoid.ai_title'),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF202F2F),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tr('avoid.ai_desc'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF5F7070),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.95),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8DAEA8,
                                  ).withOpacity(0.14),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _textController,
                              maxLines: 4,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1F3030),
                                height: 1.45,
                              ),
                              decoration: InputDecoration(
                                hintText: tr('avoid.input_hint'),
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: const Color(
                                    0xFF6B7C7B,
                                  ).withOpacity(0.55),
                                  height: 1.45,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPrimaryButton(
                            loading: state.isLoading,
                            icon: Icons.auto_awesome_rounded,
                            label: tr('avoid.analyze_button'),
                            onPressed: state.isLoading ? null : _handleExtract,
                            colors: const [
                              Color(0xFF17A89B),
                              Color(0xFF0D847B),
                            ],
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE25545,
                                ).withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFE25545,
                                  ).withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFD94B3A),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tr('avoid.analyze_failed'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFD94B3A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (state.extractedItems.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.58),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.88),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (state.confirmQuestion.isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF08C00,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFF08C00,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              color: Color(0xFFE07F00),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                state.confirmQuestion,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF9B5E16),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Text(
                                      tr('avoid.extracted_title'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF213434),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tr('avoid.extracted_desc'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5F7070),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: state.extractedItems
                                          .map((item) => _buildChip(item))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildPrimaryButton(
                                      loading: state.isLoading,
                                      icon: Icons.save_alt_rounded,
                                      label: tr('avoid.save_button'),
                                      onPressed: state.isLoading
                                          ? null
                                          : _handleSave,
                                      colors: const [
                                        Color(0xFF1D9D90),
                                        Color(0xFF1B8B7F),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundInputIcon() {
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
            Icons.edit_note_rounded,
            size: 126,
            color: const Color(0xFF678A85).withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required bool loading,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required List<Color> colors,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D847B).withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildChip(String item) {
    return GestureDetector(
      onTap: () =>
          ref.read(avoidItemNotifierProvider.notifier).toggleItem(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.68),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF0F8E83).withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F8E83).withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              size: 16,
              color: Color(0xFF0F8E83),
            ),
            const SizedBox(width: 6),
            Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F7E75),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close_rounded,
              size: 14,
              color: const Color(0xFF0F8E83).withOpacity(0.65),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExtract() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('avoid.empty_input')),
          backgroundColor: const Color(0xFFE07F00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    ref.read(avoidItemNotifierProvider.notifier).extractFromText(text);
  }

  void _handleSave() {
    ref.read(avoidItemNotifierProvider.notifier).saveExtractedItems();
  }
}
