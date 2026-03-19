import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/safeplate_dialog.dart';
import '../providers/team_provider.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F1), Color(0xFFF2F7F6), Color(0xFFFCFEFD)],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamState = ref.watch(teamListProvider);

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
            tr('team.manage_title'),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: _backgroundGradient),
          ),
          IgnorePointer(child: _buildBackgroundTeamIcon()),
          SafeArea(
            child: teamState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F8E83)),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    tr(
                      'team.error_with_message',
                      namedArgs: {'message': '$err'},
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (teams) {
                if (teams.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  color: const Color(0xFF0F8E83),
                  onRefresh: () =>
                      ref.read(teamListProvider.notifier).fetchInitial(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.62),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8DAEA8).withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F8E83).withOpacity(0.12),
                            ),
                            child: const Icon(
                              Icons.groups_2_rounded,
                              color: Color(0xFF0F8E83),
                              size: 28,
                            ),
                          ),
                          title: Text(
                            team.teamName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Color(0xFF213434),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tr(
                                'team.my_member_id',
                                namedArgs: {'id': '${team.teamMemberId}'},
                              ),
                              style: const TextStyle(
                                color: Color(0xFF4E6462),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF708483),
                          ),
                          onTap: () =>
                              context.push('/teams/${team.teamMemberId}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
            onPressed: () => _showTeamActionDialog(context, ref),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              tr('team.add_button'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.9)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F8E83).withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 34,
                  color: Color(0xFF0F8E83),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr('team.empty_state'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4E6462),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundTeamIcon() {
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
            Icons.groups_2_rounded,
            size: 126,
            color: const Color(0xFF678A85).withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }

  void _showTeamActionDialog(BuildContext context, WidgetRef ref) {
    final parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BackdropFilter(
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
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              _buildActionItem(
                sheetContext,
                icon: Icons.group_add_rounded,
                text: tr('team.create_new'),
                color: const Color(0xFF0F8E83),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateTeamDialog(parentContext, ref);
                },
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                sheetContext,
                icon: Icons.login_rounded,
                text: tr('team.join_existing'),
                color: const Color(0xFF2C74D8),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showJoinTeamDialog(parentContext, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
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
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.95)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF233535),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color.withOpacity(0.75),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SafePlateDialog(
          icon: Icons.add_home_work_rounded,
          accentColor: const Color(0xFF0F8E83),
          title: tr('team.create_dialog_title'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: safePlateDialogInputDecoration(
              labelText: tr('team.team_name_label'),
            ),
          ),
          actions: [
            SafePlateDialogButton.ghost(
              label: tr('common.cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            SafePlateDialogButton.filled(
              label: tr('common.create'),
              onPressed: () async {
                final teamName = controller.text.trim();
                if (teamName.isEmpty) return;
                final success = await ref
                    .read(teamListProvider.notifier)
                    .createTeam(teamName);
                if (success) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext, rootNavigator: true).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.create_success'))),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.create_failed'))),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showJoinTeamDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return SafePlateDialog(
          icon: Icons.group_add_rounded,
          accentColor: const Color(0xFF0F8E83),
          title: tr('team.join_dialog_title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: safePlateDialogInputDecoration(
                    labelText: tr('team.inviter_email_label'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: idCtrl,
                  keyboardType: TextInputType.number,
                  decoration: safePlateDialogInputDecoration(
                    labelText: tr('team.inviter_member_id_label'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: safePlateDialogInputDecoration(
                    labelText: tr('team.my_group_name_label'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SafePlateDialogButton.ghost(
              label: tr('common.cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            SafePlateDialogButton.filled(
              label: tr('common.join'),
              onPressed: () async {
                if (emailCtrl.text.isEmpty ||
                    idCtrl.text.isEmpty ||
                    nameCtrl.text.isEmpty) {
                  return;
                }
                final success = await ref
                    .read(teamListProvider.notifier)
                    .joinTeam(
                      emailCtrl.text.trim(),
                      int.tryParse(idCtrl.text.trim()) ?? 0,
                      nameCtrl.text.trim(),
                    );
                if (success) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext, rootNavigator: true).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.join_success'))),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('team.join_failed'))),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
