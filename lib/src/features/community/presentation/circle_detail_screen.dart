import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_colors.dart';
import '../../../design_system/amen_button_label.dart';
import '../../intentions/presentation/widgets/compose_sheet.dart';
import '../data/community_notifier.dart';
import '../domain/circle.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final String circleId;

  @override
  ConsumerState<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen> {
  var _isPrayersTab = true;

  String _getMemberDisplayName(String uid) {
    switch (uid) {
      case 'user-uid':
        return 'You';
      case 'mom-uid':
        return 'Mom';
      case 'dad-uid':
        return 'Dad';
      case 'sister-uid':
        return 'Sister (Sarah)';
      case 'pastor-uid':
        return 'Pastor David';
      case 'sarah-uid':
        return 'Sarah Miller';
      case 'michael-uid':
        return 'Michael Jones';
      case 'emily-uid':
        return 'Emily Davis';
      default:
        return 'Brother/Sister in Faith';
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code $code copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AmenColors.nightElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _leaveCircle(Circle circle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AmenColors.nightElevated,
        title: Text('Leave ${circle.name}?'),
        content: const Text('Are you sure you want to leave this private prayer circle? You will need a new invite code to join again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AmenColors.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: AmenColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(communityStateProvider.notifier).leaveCircle(circle.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left ${circle.name}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AmenColors.nightElevated,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityStateProvider);
    
    // Find the circle from state
    final circleIndex = communityState.circles.indexWhere((c) => c.id == widget.circleId);
    if (circleIndex == -1) {
      return Scaffold(
        backgroundColor: AmenColors.deepSpace,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Circle not found or you have left.')),
      );
    }
    
    final circle = communityState.circles[circleIndex];
    final gradient = circleGradients[circle.themeGradientIndex % circleGradients.length];
    
    // Get intentions shared to this circle
    final intentions = communityState.circleIntentions
        .where((ci) => ci.circleId == circle.id)
        .toList();

    return Scaffold(
      backgroundColor: AmenColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AmenColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          circle.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AmenColors.text),
            color: AmenColors.nightElevated,
            onSelected: (value) {
              if (value == 'leave') {
                _leaveCircle(circle);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AmenColors.danger, size: 20),
                    SizedBox(width: 8),
                    Text('Leave Circle', style: TextStyle(color: AmenColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient decoration at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradient[0].withValues(alpha: 0.25),
                    gradient[1].withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Info header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AmenColors.glass.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AmenColors.text,
                            ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: AmenColors.line, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'INVITATION CODE',
                                style: TextStyle(
                                  color: AmenColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                circle.inviteCode,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AmenColors.amenGold,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _copyInviteCode(circle.inviteCode),
                            icon: const Icon(Icons.copy_rounded, color: AmenColors.blueMist, size: 18),
                            label: const Text(
                              'Copy',
                              style: TextStyle(color: AmenColors.blueMist, fontWeight: FontWeight.bold),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: AmenColors.blueMist.withValues(alpha: 0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tab switcher
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.wb_sunny_outlined),
                      label: AmenButtonLabel('Prayers'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.people_alt_outlined),
                      label: AmenButtonLabel('Members'),
                    ),
                  ],
                  selected: {_isPrayersTab},
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
                    setState(() => _isPrayersTab = selection.first);
                  },
                ),
                
                const SizedBox(height: 18),
                
                // Tab Content
                if (_isPrayersTab) ...[
                  if (intentions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.spa_outlined, color: AmenColors.mutedText, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No circle prayers shared yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AmenColors.mutedText,
                                ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...intentions.map((ci) => _CircleIntentionCard(intention: ci, circleId: circle.id))
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AmenColors.nightElevated.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AmenColors.line.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: circle.memberUids.map((uid) {
                        final name = _getMemberDisplayName(uid);
                        final isCurrentUser = uid == 'user-uid';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrentUser
                                ? AmenColors.amenGold.withValues(alpha: 0.15)
                                : AmenColors.blueMist.withValues(alpha: 0.15),
                            child: Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                color: isCurrentUser ? AmenColors.amenGold : AmenColors.blueMist,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: isCurrentUser ? AmenColors.amenGold : AmenColors.text,
                              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isCurrentUser
                              ? const Chip(
                                  label: Text('Creator', style: TextStyle(fontSize: 10, color: AmenColors.night)),
                                  backgroundColor: AmenColors.amenGold,
                                  padding: EdgeInsets.zero,
                                )
                              : const Text('Member', style: TextStyle(color: AmenColors.mutedText, fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 120), // Spacing for Compose FAB
              ],
            ),
          ),
          
          // Floating compose button pre-configured for this circle
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: AmenColors.amenGold,
              foregroundColor: AmenColors.night,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Request Prayer', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                showComposeSheet(context, ref, defaultCircleId: circle.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIntentionCard extends ConsumerWidget {
  const _CircleIntentionCard({required this.intention, required this.circleId});

  final CircleIntention intention;
  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = intention.isAnonymous ? 'Anonymous' : (intention.authorName ?? 'Brother/Sister');
    final dateStr = '${intention.createdAt.hour.toString().padLeft(2, '0')}:${intention.createdAt.minute.toString().padLeft(2, '0')}';
    final hasAmened = intention.amenUserUids.contains('user-uid');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                intention.category.icon,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  author,
                  style: const TextStyle(
                    color: AmenColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  color: AmenColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            intention.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(communityStateProvider.notifier).sayAmenToCircleIntention(circleId, intention.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: hasAmened
                        ? AmenColors.amenGold.withValues(alpha: 0.15)
                        : AmenColors.night.withValues(alpha: 0.5),
                    border: Border.all(
                      color: hasAmened ? AmenColors.amenGold : AmenColors.line,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 16,
                        color: hasAmened ? AmenColors.amenGold : AmenColors.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Amen',
                        style: TextStyle(
                          color: hasAmened ? AmenColors.amenGold : AmenColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (intention.amenCount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${intention.amenCount}',
                          style: TextStyle(
                            color: hasAmened ? AmenColors.amenGold : AmenColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
