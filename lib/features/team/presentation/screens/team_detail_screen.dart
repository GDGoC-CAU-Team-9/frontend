import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import '../providers/team_provider.dart';

class TeamDetailScreen extends ConsumerWidget {
  final int teamMemberId;

  const TeamDetailScreen({super.key, required this.teamMemberId});

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F1), Color(0xFFF2F7F6), Color(0xFFFCFEFD)],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(teamDetailProvider(teamMemberId));
    final currentUserEmail = ref.watch(authProvider).value?.email;

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
            tr('team.detail_title'),
            style: const TextStyle(
              color: Color(0xFF1F3030),
              fontWeight: FontWeight.w800,
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
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          child: detailState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F8E83)),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  tr('team.error_with_message', namedArgs: {'message': '$err'}),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (team) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTeamHeaderCard(context, team),
                    const SizedBox(height: 14),
                    _buildMyIdCard(context, team.teamMemberId.toString()),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          tr('team.members_title'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F3030),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F8E83).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${team.members.length}',
                            style: const TextStyle(
                              color: Color(0xFF0F8E83),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (team.members.isEmpty)
                      _buildMembersEmpty()
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.12,
                            ),
                        itemCount: team.members.length,
                        itemBuilder: (context, index) {
                          final memberEmail = team.members[index];
                          final isMe =
                              currentUserEmail != null &&
                              currentUserEmail == memberEmail;
                          return _buildMemberCard(
                            memberEmail: memberEmail,
                            isMe: isMe,
                          );
                        },
                      ),
                    const SizedBox(height: 22),
                    _buildActionButton(
                      label: tr('team.rename_button'),
                      icon: Icons.edit_rounded,
                      colors: const [Color(0xFF17A89B), Color(0xFF0D847B)],
                      onPressed: () =>
                          _showRenameDialog(context, ref, team.teamName),
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      label: tr('team.leave_button'),
                      icon: Icons.logout_rounded,
                      colors: const [Color(0xFFE88485), Color(0xFFDF7176)],
                      onPressed: () => _showExitDialog(context, ref),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTeamHeaderCard(BuildContext context, TeamModel team) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.64),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8DAEA8).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F8E83).withOpacity(0.12),
            ),
            child: const Icon(
              Icons.groups_rounded,
              size: 42,
              color: Color(0xFF0F8E83),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            team.teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3030),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'team.created_at',
              namedArgs: {
                'date':
                    team.createdAt?.toLocal().toString().split(' ')[0] ??
                    tr('common.unknown'),
              },
            ),
            style: const TextStyle(color: Color(0xFF5F7070), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'team.team_id',
              namedArgs: {'id': team.teamId?.toString() ?? '-'},
            ),
            style: const TextStyle(
              color: Color(0xFF5F7070),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyIdCard(BuildContext context, String myId) {
    return GestureDetector(
      onTap: () => _copyToClipboard(context, myId),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.9)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F8E83).withOpacity(0.12),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: Color(0xFF0F8E83),
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('team.my_member_id', namedArgs: {'id': myId}),
                style: const TextStyle(
                  color: Color(0xFF0F8E83),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF0F8E83)),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
      ),
      child: Text(
        tr('team.members_empty'),
        style: const TextStyle(
          color: Color(0xFF5F7070),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMemberCard({required String memberEmail, required bool isMe}) {
    final accentColor = isMe
        ? const Color(0xFF0F8E83)
        : const Color(0xFF2E7AAE);
    final displayName = _displayNameFromEmail(memberEmail);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.92)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8DAEA8).withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPhotoAvatar(accentColor: accentColor),
          const SizedBox(height: 5),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3030),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            memberEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFF607272)),
          ),
          if (isMe) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F8E83).withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tr('team.me_badge'),
                style: const TextStyle(
                  color: Color(0xFF0F8E83),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoAvatar({required Color accentColor}) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.45), width: 1.4),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/image/team_p.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: accentColor.withOpacity(0.12),
            child: Icon(Icons.person_rounded, color: accentColor, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onPressed,
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
            color: colors.last.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ),
    );
  }

  String _displayNameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return email;
    final words = local
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return local;
    return words
        .map(
          (w) => w.length > 1
              ? '${w[0].toUpperCase()}${w.substring(1)}'
              : w.toUpperCase(),
        )
        .join(' ');
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            tr('team.rename_dialog_title'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: tr('team.rename_label'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0F8E83),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('common.cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F8E83),
              ),
              onPressed: () async {
                if (controller.text.trim().isEmpty ||
                    controller.text.trim() == currentName) {
                  return;
                }
                try {
                  await ref
                      .read(teamRepositoryProvider)
                      .renameTeam(teamMemberId, controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(teamDetailProvider(teamMemberId));
                    ref.read(teamListProvider.notifier).fetchInitial();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.rename_success'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.rename_failed'))),
                    );
                  }
                }
              },
              child: Text(
                tr('team.change_button'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            tr('team.leave_dialog_title'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFD94B3A),
            ),
          ),
          content: Text(tr('team.leave_dialog_content')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('common.cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD94B3A),
              ),
              onPressed: () async {
                try {
                  await ref.read(teamRepositoryProvider).exitTeam(teamMemberId);
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.pop();
                    ref.read(teamListProvider.notifier).fetchInitial();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.leave_success'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.leave_failed'))),
                    );
                  }
                }
              },
              child: Text(
                tr('team.leave_confirm_button'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('team.member_id_copied'))));
    }
  }
}
