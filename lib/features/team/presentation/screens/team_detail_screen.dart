import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/team_provider.dart';
import '../../data/repositories/team_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_design.dart';
import 'package:flutter/services.dart';

class TeamDetailScreen extends ConsumerWidget {
  final int teamMemberId;

  const TeamDetailScreen({super.key, required this.teamMemberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(teamDetailProvider(teamMemberId));
    final currentUserEmail = ref.watch(authProvider).value?.email;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          tr('team.detail_title'),
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: Colors.black87,
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: detailState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
            error: (err, stack) => Center(
              child: Text(
                tr('team.error_with_message', namedArgs: {'message': '$err'}),
                textAlign: TextAlign.center,
              ),
            ),
            data: (team) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Name Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: AppDesign.glassDecoration.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group,
                              size: 40,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            team.teamName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(
                              'team.created_at',
                              namedArgs: {
                                'date':
                                    team.createdAt
                                        ?.toLocal()
                                        .toString()
                                        .split(' ')[0] ??
                                    tr('common.unknown'),
                              },
                            ),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(
                              'team.team_id',
                              namedArgs: {
                                'id': team.teamId?.toString() ?? '-',
                              },
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Members
                    Text(
                      tr('team.members_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppDesign.glassDecoration.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: team.members.isEmpty
                            ? 1
                            : team.members.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey.shade300, height: 1),
                        itemBuilder: (context, index) {
                          if (team.members.isEmpty) {
                            return ListTile(
                              title: Text(
                                tr('team.members_empty'),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          final memberEmail = team.members[index];
                          final isMe =
                              currentUserEmail != null &&
                              currentUserEmail == memberEmail;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                memberEmail.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              memberEmail,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: isMe
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: GestureDetector(
                                      onTap: () => _copyToClipboard(
                                        context,
                                        team.teamMemberId.toString(),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            tr(
                                              'team.my_member_id',
                                              namedArgs: {
                                                'id': '${team.teamMemberId}',
                                              },
                                            ),
                                            style: TextStyle(
                                              color: Colors.teal.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.copy,
                                            size: 14,
                                            color: Colors.teal,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          foregroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            _showRenameDialog(context, ref, team.teamName),
                        icon: const Icon(Icons.edit),
                        label: Text(
                          tr('team.rename_button'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50.withOpacity(0.8),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _showExitDialog(context, ref),
                        icon: const Icon(Icons.logout),
                        label: Text(
                          tr('team.leave_button'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            tr('team.rename_dialog_title'),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: tr('team.rename_label'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('common.cancel'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                if (controller.text.trim().isEmpty ||
                    controller.text.trim() == currentName)
                  return;
                try {
                  await ref
                      .read(teamRepositoryProvider)
                      .renameTeam(teamMemberId, controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(teamDetailProvider(teamMemberId));
                    ref
                        .read(teamListProvider.notifier)
                        .fetchInitial(); // refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.rename_success'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(content: Text(tr('team.rename_failed'))),
                    );
                  }
                }
              },
              child: Text(
                tr('team.change_button'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            tr('team.leave_dialog_title'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: Text(tr('team.leave_dialog_content')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('common.cancel'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                try {
                  await ref.read(teamRepositoryProvider).exitTeam(teamMemberId);
                  if (context.mounted) {
                    Navigator.pop(context); // dialog
                    context.pop(); // exit screen
                    ref
                        .read(teamListProvider.notifier)
                        .fetchInitial(); // refresh list
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(content: Text(tr('team.leave_success'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(content: Text(tr('team.leave_failed'))),
                    );
                  }
                }
              },
              child: Text(
                tr('team.leave_confirm_button'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('team.member_id_copied'))),
      );
    }
  }
}
