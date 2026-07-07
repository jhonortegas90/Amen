import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/amen_button_label.dart';
import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../../../intentions/domain/intention.dart';
import '../../data/notifications_repository.dart';
import '../../domain/prayer_notification.dart';
import 'send_support_message_modal.dart';

class NotificationCard extends ConsumerWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final PrayerNotification notification;
  final VoidCallback onTap;

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;

    IconData iconData;
    Color iconColor;
    String actionLabel;

    switch (notification.type) {
      case NotificationType.amen:
        iconData = Icons.auto_awesome_rounded;
        iconColor = AmenColors.amenGold;
        actionLabel = 'prayed Amen for your request';
        break;
      case NotificationType.supportMessage:
        iconData = Icons.volunteer_activism_rounded;
        iconColor = Colors.lightBlueAccent;
        actionLabel = 'sent an encouraging prayer note';
        break;
      case NotificationType.answered:
        iconData = Icons.wb_sunny_rounded;
        iconColor = Colors.amber;
        actionLabel = 'celebrated an answered prayer with you';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isUnread
            ? AmenColors.nightElevated
            : AmenColors.night.withValues(alpha: 0.6),
        border: Border.all(
          color: isUnread
              ? AmenColors.amenGold.withValues(alpha: 0.5)
              : AmenColors.line.withValues(alpha: 0.3),
          width: isUnread ? 1.2 : 0.8,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: AmenColors.amenGold.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Icon badge, Sender Name & Time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withValues(alpha: 0.14),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.senderName,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: AmenColors.pureWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                _timeAgo(notification.createdAt),
                                style: textTheme.labelSmall?.copyWith(
                                  color: AmenColors.mutedText,
                                ),
                              ),
                              if (isUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AmenColors.amenGold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            actionLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: AmenColors.pureWhite.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Prayer Request Snippet Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AmenColors.night.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AmenColors.blueMist.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        notification.category.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '“${notification.intentionText}”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AmenColors.pureWhite.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Encouraging Note Body (if supportMessage)
                if (notification.type == NotificationType.supportMessage &&
                    notification.messageText != null &&
                    notification.messageText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AmenColors.amenGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AmenColors.amenGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: AmenColors.amenGold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.messageText!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AmenColors.pureWhite,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Bottom Quick Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Mark read if needed
                        if (isUnread) {
                          ref
                              .read(notificationsRepositoryProvider)
                              .markAsRead(notification.id);
                        }
                        // Open support modal to send gratitude note back
                        showSendSupportMessageModal(
                          context,
                          Intention(
                            id: notification.intentionId,
                            authorUid: notification.senderUid,
                            text: 'Re: ${notification.intentionText}',
                            createdAt: DateTime.now(),
                            amenCount: 0,
                            isPinned: false,
                            locale: 'en',
                            status: 'approved',
                            category: notification.category,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AmenColors.amenGold,
                        side: BorderSide(
                          color: AmenColors.amenGold.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.reply_rounded,
                        size: 16,
                        color: AmenColors.amenGold,
                      ),
                      label: AmenButtonLabel(
                        notification.type == NotificationType.supportMessage
                            ? l10n.sendThanks
                            : l10n.sayAmenBack,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
