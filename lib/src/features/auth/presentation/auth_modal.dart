import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_button_label.dart';
import '../../../design_system/amen_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../notifications/data/notification_service.dart';
import '../data/auth_repository.dart';

void showAuthModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AuthModal(),
  );
}

class _AuthModal extends ConsumerStatefulWidget {
  const _AuthModal();

  @override
  ConsumerState<_AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<_AuthModal> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    final navigator = Navigator.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signInWithGoogle();
      if (cred != null && mounted) {
        await ref
            .read(notificationServiceProvider)
            .requestAuthorizationPermission();
        if (mounted) navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    final navigator = Navigator.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signInWithApple();
      if (cred != null && mounted) {
        await ref
            .read(notificationServiceProvider)
            .requestAuthorizationPermission();
        if (mounted) navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: AmenColors.night,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AmenColors.amenGold.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AmenColors.amenGold.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AmenColors.mutedText.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                color: AmenColors.amenGold,
                size: 26,
              ),
              const SizedBox(width: 12),
              Text(
                'Account & Identity',
                style: textTheme.titleLarge?.copyWith(
                  color: AmenColors.pureWhite,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user != null && !user.isAnonymous
                ? 'Signed in as ${user.displayName ?? user.email ?? 'Pilgrim'}'
                : 'Sign in to sync your prayers & pin intentions across devices.',
            style: textTheme.bodyMedium?.copyWith(color: AmenColors.mutedText),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Text(
                _errorMessage!,
                style: textTheme.bodySmall?.copyWith(color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AmenColors.amenGold),
              ),
            )
          else if (user != null && !user.isAnonymous) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref.read(authRepositoryProvider).signOut();
                if (mounted) navigator.pop();
              },
              icon: const Icon(Icons.logout, color: AmenColors.amenGold),
              label: AmenButtonLabel(
                l10n.signOut,
                style: const TextStyle(color: AmenColors.amenGold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: AmenColors.amenGold.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: const Icon(
                Icons.g_mobiledata,
                color: Colors.black,
                size: 24,
              ),
              label: AmenButtonLabel(
                l10n.signInWithGoogle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                minimumSize: const Size.fromHeight(47),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleAppleSignIn,
              icon: const Icon(Icons.apple, color: Colors.white, size: 22),
              label: AmenButtonLabel(
                l10n.signInWithApple,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(47),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.continueAnonymously,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AmenColors.mutedText,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
