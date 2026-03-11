import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/data/repositories/history_repository.dart';
import '../../../team/presentation/providers/team_provider.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load history on first open
    Future.microtask(() {
      ref.read(historyListProvider.notifier).loadInitial();
    });
  }

  Future<void> _pickImage(
    ImageSource source, {
    int? teamMemberId,
  }) async {
    if (kIsWeb && source == ImageSource.camera) {
      if (mounted) {
        await context.push(
          '/camera',
          extra: {'teamMemberId': teamMemberId},
        );
        // Refresh history when returning from camera flow
        if (mounted) {
          ref.read(historyListProvider.notifier).refresh();
        }
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        if (mounted) {
          await context.push(
            '/analysis-loading',
            extra: {'imageFile': image, 'teamMemberId': teamMemberId},
          );
          // Refresh history when returning from analysis
          if (mounted) {
            ref.read(historyListProvider.notifier).refresh();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미지 선택 실패: $e')));
      }
    }
  }

  void _showImageSourceActionSheet(
    BuildContext context, {
    int? teamMemberId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              _buildImageSourceButton(
                context,
                icon: Icons.camera_alt_rounded,
                text: '카메라로 촬영하기',
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, teamMemberId: teamMemberId);
                },
              ),
              const SizedBox(height: 16),
              _buildImageSourceButton(
                context,
                icon: Icons.photo_library_rounded,
                text: '갤러리에서 선택하기',
                color: Colors.blueAccent,
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, teamMemberId: teamMemberId);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTargetSelectionSheet(BuildContext context) {
    // Refresh team list each time the selector opens so users see latest changes.
    ref.read(teamListProvider.notifier).fetchInitial();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '누구 기준으로 분석할까요?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showImageSourceActionSheet(context);
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: AppDesign.glassDecoration.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.teal,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '나만을 위한 분석',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '내 기피 재료/알러지만 반영',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '팀을 선택해 같이 분석하기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: AppDesign.glassDecoration.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final teamState = ref.watch(teamListProvider);
                    return teamState.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        ),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '팀 목록을 불러오지 못했습니다.\n$err',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(teamListProvider.notifier)
                                  .fetchInitial(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                      data: (teams) {
                        if (teams.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '등록된 팀이 없습니다.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '팀을 만들거나 초대에 참여해보세요.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push('/teams');
                                  },
                                  icon: const Icon(Icons.group_add),
                                  label: const Text('팀 만들기/참여하기'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SizedBox(
                          height: 240,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: teams.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                            itemBuilder: (context, index) {
                              final team = teams[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.withOpacity(0.15),
                                  child: const Icon(
                                    Icons.group,
                                    color: Colors.teal,
                                  ),
                                ),
                                title: Text(
                                  team.teamName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '멤버 ${team.members.length}명 · ID ${team.teamMemberId}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showImageSourceActionSheet(
                                    context,
                                    teamMemberId: team.teamMemberId,
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/teams');
                  },
                  icon: const Icon(Icons.manage_accounts, color: Colors.white),
                  label: const Text(
                    '팀 관리로 이동',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: AppDesign.glassDecoration.copyWith(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionBottomSheet(BuildContext context) {
    final List<Map<String, String>> languages = AppConstants.supportedLanguages;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr('drawer.language_change'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: AppDesign.glassDecoration.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: languages.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade300, height: 1),
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        final isSelected =
                            context.locale.languageCode == lang['code'];

                        return ListTile(
                          leading: Text(
                            lang['icon']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            tr('language.${lang['code']}'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.teal : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.teal,
                                )
                              : null,
                          onTap: () async {
                            Navigator.pop(context);
                            if (!isSelected) {
                              try {
                                await ref
                                    .read(authRepositoryProvider)
                                    .updateLanguage(lang['code']!);

                                if (!mounted) return;

                                await context.setLocale(Locale(lang['code']!));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        tr(
                                          'language_changed',
                                          namedArgs: {
                                            'lang': tr(
                                              'language.${lang['code']}',
                                            ),
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                final message = _toUserMessage(
                                  e,
                                  fallback: '언어 변경에 실패했습니다. 다시 시도해주세요.',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── History list body ──
  Widget _buildHistoryList(HistoryListState historyState) {
    // Error state
    if (historyState.errorMessage != null && historyState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '기록을 불러오지 못했습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(historyListProvider.notifier).loadInitial(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Loading (first load)
    if (historyState.isLoading && historyState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    // Empty state
    if (!historyState.isLoading && historyState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Colors.teal.shade300,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '메뉴판을 촬영하여\n안전한 음식을 찾아보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI가 기피 재료를 분석해 드립니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Text(
              '우측 하단의 + 버튼을 눌러 시작하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // History list
    return RefreshIndicator(
      onRefresh: () => ref.read(historyListProvider.notifier).refresh(),
      color: Colors.teal,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent:
                    240, // Reduced overall height to make white area smaller
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = historyState.items[index];
                return _buildHistoryCard(item);
              }, childCount: historyState.items.length),
            ),
          ),
          if (historyState.hasMore)
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  if (!historyState.isLoading) {
                    Future.microtask(
                      () => ref.read(historyListProvider.notifier).loadMore(),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final dateStr = _formatDate(item.createdAt);
    final menuCount = item.items.length;
    final safeCount = item.items.where((m) => m.safetyLevel == 'safe').length;
    final dangerCount = item.items
        .where((m) => m.safetyLevel == 'danger')
        .length;

    return GestureDetector(
      onTap: () {
        context.push('/history-detail', extra: item);
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full background image
            if (item.imageUrls.isNotEmpty)
              Image.network(
                item.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Container(
                color: Colors.teal.shade50,
                child: Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Colors.teal.shade200,
                  ),
                ),
              ),

            // Information overlay with Glassmorphism
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 6,
                    sigmaY: 6,
                  ), // Balanced blur
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.6,
                      ), // Balanced transparency
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.4)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Summary chips
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Best item recommendation
                            if (item.best != null)
                              _buildSummaryChip(
                                icon: Icons.thumb_up_alt_outlined,
                                label: '추천: ${item.best!.menuName}',
                                color: Colors.teal.shade700,
                              ),
                            _buildSummaryChip(
                              icon: Icons.restaurant_menu,
                              label: '$menuCount개',
                              color: Colors.teal.shade700,
                            ),
                            if (safeCount > 0)
                              _buildSummaryChip(
                                icon: Icons.check_circle_outline,
                                label: '안전 $safeCount',
                                color: Colors.green.shade800,
                              ),
                            if (dangerCount > 0)
                              _buildSummaryChip(
                                icon: Icons.warning_amber_rounded,
                                label: '위험 $dangerCount',
                                color: Colors.red.shade800,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _toUserMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }

        final result = data['result'];
        if (result is String && result.trim().isNotEmpty) {
          return result.trim();
        }
      }

      final message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'SafePlate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 24),
                color: Colors.black87,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        elevation: 0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppDesign.backgroundGradient,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    final user = authState.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.teal.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: Text(
                              user?.email.substring(0, 1).toUpperCase() ?? 'G',
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? '사용자',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? 'guest@example.com',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDesign.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: Colors.teal,
                        ),
                        title: Text(
                          tr('drawer.profile_management'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/profile');
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDesign.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.group,
                          color: Colors.indigoAccent,
                        ),
                        title: const Text(
                          '내 팀 관리',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.black54,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/teams');
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDesign.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.language,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          tr('drawer.language_change'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.black54,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showLanguageSelectionBottomSheet(context);
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDesign.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          tr('drawer.logout'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(authProvider.notifier).logout();
                          if (mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Section header when there's history
              if (historyState.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '분석 기록',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              // Main content
              Expanded(child: _buildHistoryList(historyState)),
            ],
          ),
        ),
      ),
      // FAB for scanning
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTargetSelectionSheet(context),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text(
          '검사하기',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
