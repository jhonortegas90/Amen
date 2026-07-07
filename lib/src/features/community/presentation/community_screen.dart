import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_button_label.dart';
import '../../../design_system/amen_colors.dart';
import '../../../localization/app_localizations.dart';
import '../data/community_notifier.dart';
import '../domain/circle.dart';
import 'circle_detail_screen.dart';

enum _CommunityPanel { friendRequests, groupInvitations }

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  var _panel = _CommunityPanel.friendRequests;

  void _showCreateCircleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateCircleSheet(),
    );
  }

  void _showJoinCircleDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _JoinCircleDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final communityState = ref.watch(communityStateProvider);

    return CustomScrollView(
      key: const PageStorageKey('community-circles-scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          sliver: SliverList.list(
            children: [
              Text(
                l10n.community,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Private circles for trusted prayer, care, and encouragement.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              
              // Circles Section
              if (communityState.circles.isEmpty)
                _EmptyCirclesView(
                  onCreateTap: () => _showCreateCircleSheet(context),
                  onJoinTap: () => _showJoinCircleDialog(context),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Circles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showJoinCircleDialog(context),
                      icon: const Icon(Icons.group_add_outlined),
                      color: AmenColors.blueMist,
                      tooltip: 'Join Circle',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showCreateCircleSheet(context),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AmenColors.amenGold,
                      tooltip: 'Create Circle',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...communityState.circles.map((circle) => _CircleCard(circle: circle)),
              ],
              
              const SizedBox(height: 28),
              
              SegmentedButton<_CommunityPanel>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<_CommunityPanel>(
                    value: _CommunityPanel.friendRequests,
                    label: AmenButtonLabel(l10n.friends),
                  ),
                  ButtonSegment<_CommunityPanel>(
                    value: _CommunityPanel.groupInvitations,
                    label: AmenButtonLabel(l10n.invites),
                  ),
                ],
                selected: {_panel},
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AmenColors.night
                        : AmenColors.mutedText;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AmenColors.amenGold
                        : AmenColors.nightElevated;
                  }),
                ),
                onSelectionChanged: (selection) {
                  setState(() => _panel = selection.first);
                },
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _panel == _CommunityPanel.friendRequests
                    ? const _FriendRequestsPanel()
                    : const _GroupInvitationsPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle});

  final Circle circle;

  @override
  Widget build(BuildContext context) {
    final gradient = circleGradients[circle.themeGradientIndex % circleGradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.6)),
        gradient: LinearGradient(
          colors: [
            gradient[0].withValues(alpha: 0.35),
            gradient[1].withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => CircleDetailScreen(circleId: circle.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        circle.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AmenColors.text.withValues(alpha: 0.8),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_outlined, size: 14, color: AmenColors.mutedText.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Text(
                                '${circle.memberUids.length} members',
                                style: const TextStyle(color: AmenColors.mutedText, fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.vpn_key_outlined, size: 14, color: AmenColors.amenGold),
                              const SizedBox(width: 4),
                              Text(
                                circle.inviteCode,
                                style: const TextStyle(color: AmenColors.amenGold, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AmenColors.mutedText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCirclesView extends StatelessWidget {
  const _EmptyCirclesView({required this.onCreateTap, required this.onJoinTap});

  final VoidCallback onCreateTap;
  final VoidCallback onJoinTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AmenColors.amenGold.withValues(alpha: 0.13),
              child: const Icon(
                Icons.groups_2_outlined,
                color: AmenColors.amenGold,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noCirclesJoinedYet,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyCirclesExplanation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AmenColors.mutedText,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onJoinTap,
                    icon: const Icon(Icons.group_add_outlined, color: AmenColors.blueMist),
                    label: Text(l10n.joinWithCode, style: const TextStyle(color: AmenColors.blueMist, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AmenColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCreateTap,
                    icon: const Icon(Icons.add_circle_outline, color: AmenColors.night),
                    label: Text(l10n.createCircleButton, style: const TextStyle(color: AmenColors.night, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AmenColors.amenGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCircleSheet extends ConsumerStatefulWidget {
  const _CreateCircleSheet();

  @override
  ConsumerState<_CreateCircleSheet> createState() => _CreateCircleSheetState();
}

class _CreateCircleSheetState extends ConsumerState<_CreateCircleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _selectedGradientIndex = 0;
  var _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(communityStateProvider.notifier).createCircle(
            _nameController.text.trim(),
            _descController.text.trim(),
            _selectedGradientIndex,
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.circleCreatedSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AmenColors.nightElevated,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = AppLocalizations.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        decoration: const BoxDecoration(
          color: AmenColors.deepSpace,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AmenColors.line,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.createPrivateCircleTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.createCircleExplanation,
                  style: const TextStyle(color: AmenColors.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.circleNameRequired : null,
                  decoration: InputDecoration(
                    hintText: l10n.circleNamePlaceholder,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 3,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.circlePurposeRequired : null,
                  decoration: InputDecoration(
                    hintText: l10n.circlePurposePlaceholder,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.chooseCardTheme,
                  style: const TextStyle(
                    color: AmenColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: circleGradients.length,
                    itemBuilder: (context, index) {
                      final colors = circleGradients[index];
                      final isSelected = _selectedGradientIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGradientIndex = index),
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AmenColors.amenGold : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AmenColors.amenGold,
                      foregroundColor: AmenColors.night,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AmenColors.night),
                          )
                        : Text(l10n.createCircleButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinCircleDialog extends ConsumerStatefulWidget {
  const _JoinCircleDialog();

  @override
  ConsumerState<_JoinCircleDialog> createState() => _JoinCircleDialogState();
}

class _JoinCircleDialogState extends ConsumerState<_JoinCircleDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(communityStateProvider.notifier).joinCircle(_codeController.text.trim());
      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinedCircleSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AmenColors.nightElevated,
          ),
        );
      } else {
        setState(() {
          _errorMessage = ref.read(communityStateProvider).error;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AmenColors.nightElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(l10n.joinPrivateCircle, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enterInviteCode,
              style: const TextStyle(color: AmenColors.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _codeController,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.codeIsRequired;
                if (!value.trim().toUpperCase().startsWith('AMEN-')) return l10n.codeMustStartWithAmen;
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'AMEN-XXXX-XXXX',
                hintStyle: TextStyle(letterSpacing: 0, fontWeight: FontWeight.normal),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AmenColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: const TextStyle(color: AmenColors.mutedText)),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AmenColors.amenGold,
            foregroundColor: AmenColors.night,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AmenColors.night),
                )
              : Text(l10n.joinAction, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _FriendRequestsPanel extends StatelessWidget {
  const _FriendRequestsPanel();

  @override
  Widget build(BuildContext context) {
    return const _ManagementPanel(
      key: ValueKey('friend-requests'),
      title: 'Friend Requests',
      rows: [],
    );
  }
}

class _GroupInvitationsPanel extends StatelessWidget {
  const _GroupInvitationsPanel();

  @override
  Widget build(BuildContext context) {
    return const _ManagementPanel(
      key: ValueKey('group-invitations'),
      title: 'Group Invitations',
      rows: [],
    );
  }
}

class _ManagementPanel extends StatelessWidget {
  const _ManagementPanel({super.key, required this.title, required this.rows});

  final String title;
  final List<_ManagementRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    title == 'Friend Requests'
                        ? 'No pending friend requests.'
                        : 'No pending group invitations.',
                    style: const TextStyle(
                      color: AmenColors.mutedText,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...rows,
          ],
        ),
      ),
    );
  }
}

class _ManagementRow extends StatelessWidget {
  const _ManagementRow({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AmenColors.amenGold.withValues(alpha: 0.13),
        child: Icon(icon, color: AmenColors.amenGold),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close_rounded),
            color: AmenColors.mutedText,
            tooltip: l10n.dismiss,
          ),
          IconButton.filled(
            onPressed: () {},
            icon: const Icon(Icons.check_rounded),
            color: AmenColors.night,
            style: IconButton.styleFrom(backgroundColor: AmenColors.amenGold),
            tooltip: l10n.accept,
          ),
        ],
      ),
    );
  }
}
