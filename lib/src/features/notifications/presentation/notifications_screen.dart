import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../intentions/presentation/widgets/amen_background.dart';
import '../data/notifications_repository.dart';
import '../domain/prayer_notification.dart';
import 'widgets/notification_card.dart';

enum NotificationFilter { all, amens, encouragements }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final user = ref.watch(authStateProvider).value;
    final currentUid = user?.uid ?? 'guest';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AmenBackground()),
          SafeArea(
            child: Column(
              children: [
                // Top App Bar Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AmenColors.pureWhite,
                          size: 20,
                        ),
                        tooltip: l10n.back,
                      ),
                      const SizedBox(width: 8),

                      // Title & Unread Count Badge
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.notifications,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                  color: AmenColors.pureWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            notificationsAsync.maybeWhen(
                              data: (list) {
                                final unreadCount = list
                                    .where((n) => !n.isRead)
                                    .length;
                                if (unreadCount == 0) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AmenColors.amenGold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    l10n.unreadCount(unreadCount),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      // Mark All As Read Button
                      IconButton(
                        onPressed: () {
                          ref
                              .read(notificationsRepositoryProvider)
                              .markAllAsRead(currentUid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.allNotificationsRead),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.done_all_rounded),
                        color: AmenColors.amenGold,
                        tooltip: l10n.readAll,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Filter Segmented Chips
                notificationsAsync.maybeWhen(
                  data: (allNotifs) {
                    final amenCount = allNotifs
                        .where((n) => n.type == NotificationType.amen)
                        .length;
                    final encCount = allNotifs
                        .where((n) => n.type == NotificationType.supportMessage)
                        .length;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AmenColors.nightElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AmenColors.line.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FilterChip(
                              label: '${l10n.allLabel} (${allNotifs.length})',
                              isSelected:
                                  _selectedFilter == NotificationFilter.all,
                              onTap: () => setState(
                                () => _selectedFilter = NotificationFilter.all,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _FilterChip(
                              label: 'Amens ($amenCount)',
                              isSelected:
                                  _selectedFilter == NotificationFilter.amens,
                              onTap: () => setState(
                                () =>
                                    _selectedFilter = NotificationFilter.amens,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _FilterChip(
                              label: '${l10n.messagesLabel} ($encCount)',
                              isSelected:
                                  _selectedFilter ==
                                  NotificationFilter.encouragements,
                              onTap: () => setState(
                                () => _selectedFilter =
                                    NotificationFilter.encouragements,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Notification Feed List
                Expanded(
                  child: notificationsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AmenColors.amenGold,
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        l10n.errorLoadingNotifications(err),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    data: (allNotifications) {
                      final filtered = allNotifications.where((n) {
                        if (_selectedFilter == NotificationFilter.amens) {
                          return n.type == NotificationType.amen;
                        }
                        if (_selectedFilter ==
                            NotificationFilter.encouragements) {
                          return n.type == NotificationType.supportMessage;
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const _EmptyNotificationsView();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return NotificationCard(
                            notification: item,
                            onTap: () {
                              if (!item.isRead) {
                                ref
                                    .read(notificationsRepositoryProvider)
                                    .markAsRead(item.id);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AmenColors.amenGold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.black : AmenColors.mutedText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AmenColors.amenGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: AmenColors.amenGold.withValues(alpha: 0.4),
                ),
              ),
              child: const Text('🕊️', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyNotificationsTitle,
              style: textTheme.titleMedium?.copyWith(
                color: AmenColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyNotificationsBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AmenColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AmenColors.nightElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AmenColors.blueMist.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '“For where two or three gather in my name, there am I with them.”\n— Matthew 18:20',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AmenColors.amenGold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
