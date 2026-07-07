import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/amen_button_label.dart';
import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../gamification/data/prayer_streak_notifier.dart';
import '../../../intentions/domain/intention.dart';
import '../../data/notifications_repository.dart';

void showSendSupportMessageModal(BuildContext context, Intention intention) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SendSupportMessageModal(intention: intention),
  );
}

class SendSupportMessageModal extends ConsumerStatefulWidget {
  const SendSupportMessageModal({super.key, required this.intention});

  final Intention intention;

  @override
  ConsumerState<SendSupportMessageModal> createState() =>
      _SendSupportMessageModalState();
}

class _SendSupportMessageModalState
    extends ConsumerState<SendSupportMessageModal> {
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final senderName = _isAnonymous
          ? l10n.anonymousBeliever
          : (_nameController.text.trim().isEmpty
                ? l10n.brotherSisterInFaith
                : _nameController.text.trim());

      await repo.sendSupportMessage(
        intentionId: widget.intention.id,
        intentionText: widget.intention.text,
        category: widget.intention.category,
        recipientUid: widget.intention.authorUid.isEmpty
            ? 'community'
            : widget.intention.authorUid,
        messageText: text,
        senderName: senderName,
      );
      await ref.read(prayerStreakProvider.notifier).recordPrayerSupport();

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AmenColors.amenGold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.supportMessageSent)),
            ],
          ),
          backgroundColor: AmenColors.nightElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AmenColors.amenGold.withValues(alpha: 0.4)),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.supportMessageError(e)),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: AmenColors.night,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: AmenColors.amenGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AmenColors.amenGold.withValues(alpha: 0.15),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AmenColors.mutedText.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AmenColors.amenGold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AmenColors.amenGold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AmenColors.amenGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sendPrayerSupportNote,
                      style: textTheme.titleMedium?.copyWith(
                        color: AmenColors.pureWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.supportNoteSubtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AmenColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Prayer Request Snippet Preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AmenColors.nightElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AmenColors.blueMist.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.intention.category.icon,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '“${widget.intention.text}”',
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

          const SizedBox(height: 18),

          // Message Input Box
          TextField(
            controller: _messageController,
            maxLength: 250,
            maxLines: 4,
            style: const TextStyle(color: AmenColors.pureWhite, fontSize: 15),
            decoration: InputDecoration(
              hintText: l10n.supportMessageHint,
              hintStyle: TextStyle(
                color: AmenColors.mutedText.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AmenColors.nightElevated,
              counterStyle: const TextStyle(color: AmenColors.mutedText),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AmenColors.line.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AmenColors.amenGold,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sender Name Field & Anonymous Toggle
          if (!_isAnonymous)
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AmenColors.pureWhite, fontSize: 14),
              decoration: InputDecoration(
                labelText: l10n.yourNameOptional,
                labelStyle: const TextStyle(color: AmenColors.mutedText),
                filled: true,
                fillColor: AmenColors.nightElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AmenColors.line.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),

          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                activeColor: AmenColors.amenGold,
                checkColor: Colors.black,
                onChanged: (val) {
                  setState(() => _isAnonymous = val ?? false);
                },
              ),
              Expanded(
                child: Text(
                  l10n.sendAnonymouslyAsBeliever,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AmenColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AmenColors.amenGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: AmenButtonLabel(
                            l10n.sendEncouragement,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
}
