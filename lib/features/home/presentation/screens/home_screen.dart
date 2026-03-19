import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/data/repositories/history_repository.dart';
import '../../../team/presentation/providers/team_provider.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../shared/widgets/safeplate_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  static const LinearGradient _homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F1), Color(0xFFF2F7F6), Color(0xFFFCFEFD)],
    stops: [0, 0.5, 1],
  );

  @override
  void initState() {
    super.initState();
    // Load history on first open
    Future.microtask(() {
      ref.read(historyListProvider.notifier).loadInitial();
    });
  }

  Future<void> _pickImage(ImageSource source, {int? teamMemberId}) async {
    if (kIsWeb && source == ImageSource.camera) {
      if (mounted) {
        await context.push('/camera', extra: {'teamMemberId': teamMemberId});
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'home.image_pick_failed_with_message',
                namedArgs: {'message': e.toString()},
              ),
            ),
          ),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context, {int? teamMemberId}) {
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
                text: tr('home.source_camera'),
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
                text: tr('home.source_gallery'),
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
              Text(
                tr('home.target_sheet_title'),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('home.target_personal_title'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('home.target_personal_desc'),
                              style: const TextStyle(
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
              Text(
                tr('home.target_team_title'),
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
                              tr(
                                'home.team_load_failed_with_message',
                                namedArgs: {'message': err.toString()},
                              ),
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
                              label: Text(tr('common.retry')),
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
                                Text(
                                  tr('home.team_empty_title'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tr('home.team_empty_desc'),
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
                                  label: Text(tr('home.team_create_or_join')),
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
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade300),
                            itemBuilder: (context, index) {
                              final team = teams[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.withOpacity(
                                    0.15,
                                  ),
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
                                  tr(
                                    'home.team_member_count_id',
                                    namedArgs: {
                                      'count': '${team.members.length}',
                                      'id': '${team.teamMemberId}',
                                    },
                                  ),
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
                  label: Text(
                    tr('home.go_to_team_management'),
                    style: const TextStyle(color: Colors.white),
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
                                final message = toUserMessage(
                                  e,
                                  fallback: tr('home.language_change_failed'),
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

  void _showSideMenuOverlay(BuildContext parentContext) {
    showGeneralDialog(
      context: parentContext,
      barrierDismissible: true,
      barrierLabel: 'side_menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: SizedBox(
                width: MediaQuery.of(parentContext).size.width * 0.72,
                child: SafeArea(
                  right: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final authState = ref.watch(authProvider);
                          final user = authState.value;
                          final initial =
                              user?.email.substring(0, 1).toUpperCase() ?? 'G';

                            return Container(
                              margin: const EdgeInsets.fromLTRB(2, 8, 2, 18),
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                              decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.82),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.98)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8DAEA8).withOpacity(0.2),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF1B9A8D).withOpacity(0.45),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                      backgroundColor: Colors.white.withOpacity(0.98),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        color: Color(0xFF14857B),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'SafePlate',
                                        style: TextStyle(
                                          color: Color(0xFF1F3030),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        user?.email ?? tr('common.unknown'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF5D6F6E),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildDrawerMenuTile(
                        icon: Icons.person_outline_rounded,
                        accentColor: const Color(0xFF14857B),
                        label: tr('drawer.profile_management'),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          parentContext.push('/profile');
                        },
                      ),
                      _buildDrawerMenuTile(
                        icon: Icons.group_rounded,
                        accentColor: const Color(0xFF2C74D8),
                        label: tr('team.manage_title'),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          parentContext.push('/teams');
                        },
                      ),
                      _buildDrawerMenuTile(
                        icon: Icons.language_rounded,
                        accentColor: const Color(0xFF6A60D9),
                        label: tr('drawer.language_change'),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Future.delayed(
                            const Duration(milliseconds: 60),
                            () => _showLanguageSelectionBottomSheet(parentContext),
                          );
                        },
                      ),
                      _buildDrawerMenuTile(
                        icon: Icons.logout_rounded,
                        accentColor: const Color(0xFFD65C4C),
                        label: tr('drawer.logout'),
                        isDestructive: true,
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          await ref.read(authProvider.notifier).logout();
                          if (mounted) {
                            parentContext.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final blurValue = Tween<double>(begin: 0, end: 5).transform(curved.value);
        final dimValue = Tween<double>(begin: 0, end: 0.34).transform(curved.value);
        final panelOffset = Tween<double>(begin: -0.03, end: 0).transform(
          curved.value,
        );

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurValue,
                        sigmaY: blurValue,
                      ),
                      child: Container(
                        color: Colors.black.withOpacity(dimValue),
                      ),
                    ),
                  ),
                ),
              ),
              FractionalTranslation(
                translation: Offset(panelOffset, 0),
                child: FadeTransition(opacity: curved, child: child),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── History list body ──
  Widget _buildHistoryList(HistoryListState historyState) {
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 10;

    // Error state
    if (historyState.errorMessage != null && historyState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              tr('home.history_load_failed'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(historyListProvider.notifier).loadInitial(),
              icon: const Icon(Icons.refresh),
              label: Text(tr('common.retry')),
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
                color: const Color(0xFF7AA39D).withValues(alpha: 0.035),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: const Color(0xFF678A85).withValues(alpha: 0.14),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              tr('home.empty_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('home.empty_desc'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // History list
    return RefreshIndicator(
      onRefresh: () => ref.read(historyListProvider.notifier).refresh(),
      color: const Color(0xFF128B7E),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, topInset, 20, 92),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 252,
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
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final dateStr = DateFormat('yyMMdd HH:mm').format(item.createdAt);

    return GestureDetector(
      onTap: () {
        context.push('/history-detail', extra: item);
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7FA7A0).withOpacity(0.16),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            const BoxShadow(
              color: Color(0xFFFDFEFE),
              blurRadius: 10,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main image
            if (item.imageUrls.isNotEmpty)
              Image.network(
                item.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFD9E8E5),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Color(0xFF759E97),
                    ),
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xFFDFF0EC),
                child: Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: const Color(0xFF71A69E),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.22),
                    ],
                    stops: const [0.42, 0.72, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.5,
                      vertical: 11.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.72),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.78)),
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
                              color: Color(0xFF4A6360),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateStr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4A6360),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.best != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildSummaryChip(
                                icon: Icons.thumb_up_alt_outlined,
                                label: tr(
                                  'home.chip_best',
                                  namedArgs: {
                                    'name': _menuNameOrUnknown(
                                      item.best!.menuName,
                                    ),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    color: Colors.white.withOpacity(0.24),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: tr('home.history_delete_tooltip'),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _confirmDeleteHistory(item),
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

  Future<void> _confirmDeleteHistory(HistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return SafePlateDialog(
          icon: Icons.delete_outline_rounded,
          accentColor: const Color(0xFFD94B3A),
          title: tr('home.history_delete_title'),
          message: tr('home.history_delete_content'),
          actions: [
            SafePlateDialogButton.ghost(
              label: tr('common.cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            SafePlateDialogButton.filled(
              label: tr('common.delete'),
              accentColor: const Color(0xFFD94B3A),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(historyListProvider.notifier).deleteHistory(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('home.history_delete_success'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            toUserMessage(e, fallback: tr('home.history_delete_failed')),
          ),
        ),
      );
    }
  }

  Widget _buildSummaryChip({required IconData icon, required String label}) {
    const accentColor = Color(0xFF0D7B76);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.38),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: accentColor.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: accentColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerMenuTile({
    required IconData icon,
    required Color accentColor,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final titleColor = isDestructive
        ? const Color(0xFFB83D30)
        : const Color(0xFF253636);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.79),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.97)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CBAB4).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withOpacity(0.15),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: titleColor,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: titleColor.withOpacity(0.58),
        ),
        onTap: onTap,
      ),
    );
  }

  String _menuNameOrUnknown(String menuName) {
    final normalized = menuName.trim();
    if (normalized.isEmpty) return tr('common.unknown');
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 19,
                color: Color(0xFF1E6B66),
              ),
              const SizedBox(width: 7),
              Text(
                tr('home.history_header'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F3030),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        centerTitle: true,
        leading: Builder(
          builder: (context) => Padding(
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
                icon: const Icon(Icons.menu, size: 24),
                color: const Color(0xFF253636),
                onPressed: () => _showSideMenuOverlay(context),
              ),
            ),
          ),
        ),
      ),
      drawerEnableOpenDragGesture: false,
      drawer: Drawer(
        elevation: 0,
        width: MediaQuery.of(context).size.width,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(context).pop(),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.black.withOpacity(0.34),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.72,
                  child: SafeArea(
                    right: false,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final authState = ref.watch(authProvider);
                            final user = authState.value;
                            final initial =
                                user?.email.substring(0, 1).toUpperCase() ?? 'G';

                            return Container(
                              margin: const EdgeInsets.fromLTRB(2, 8, 2, 18),
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFF1B9A8D,
                                        ).withOpacity(0.45),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.88,
                                      ),
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          color: Color(0xFF14857B),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'SafePlate',
                                          style: TextStyle(
                                            color: Color(0xFF1F3030),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          user?.email ?? tr('common.unknown'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF5D6F6E),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        _buildDrawerMenuTile(
                          icon: Icons.person_outline_rounded,
                          accentColor: const Color(0xFF14857B),
                          label: tr('drawer.profile_management'),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/profile');
                          },
                        ),
                        _buildDrawerMenuTile(
                          icon: Icons.group_rounded,
                          accentColor: const Color(0xFF2C74D8),
                          label: tr('team.manage_title'),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/teams');
                          },
                        ),
                        _buildDrawerMenuTile(
                          icon: Icons.language_rounded,
                          accentColor: const Color(0xFF6A60D9),
                          label: tr('drawer.language_change'),
                          onTap: () {
                            Navigator.pop(context);
                            _showLanguageSelectionBottomSheet(context);
                          },
                        ),
                        _buildDrawerMenuTile(
                          icon: Icons.logout_rounded,
                          accentColor: const Color(0xFFD65C4C),
                          label: tr('drawer.logout'),
                          isDestructive: true,
                          onTap: () async {
                            Navigator.pop(context);
                            await ref.read(authProvider.notifier).logout();
                            if (mounted) {
                              context.go('/login');
                            }
                          },
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
      body: Container(
        decoration: const BoxDecoration(gradient: _homeBackgroundGradient),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -36,
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFB7DED6).withOpacity(0.7),
                        const Color(0xFFB7DED6).withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -68,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFCFE5F0).withOpacity(0.5),
                        const Color(0xFFCFE5F0).withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [Expanded(child: _buildHistoryList(historyState))],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF17A89B), Color(0xFF0D847B)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D847B).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showTargetSelectionSheet(context),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.document_scanner_rounded),
            label: Text(
              tr('home.scan_button'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
