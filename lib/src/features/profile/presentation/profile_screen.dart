import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_button_label.dart';
import '../../../design_system/amen_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_modal.dart';
import '../../auth/presentation/widgets/legal_terms_modal.dart';
import '../../gamification/data/prayer_streak_notifier.dart';
import '../../intentions/data/intentions_repository.dart';
import '../../intentions/domain/intention.dart';
import '../../notifications/data/notification_service.dart';
import '../data/profile_settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.read(appLocaleProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AmenColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              Text(
                l10n.selectLanguage,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AmenColors.pureWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                const Locale('en'),
                const Locale('es'),
                const Locale('fr'),
              ].map((locale) {
                final isSelected =
                    currentLocale.languageCode == locale.languageCode;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: isSelected
                      ? AmenColors.amenGold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  title: Text(
                    _getLanguageName(locale),
                    style: TextStyle(
                      color: isSelected
                          ? AmenColors.amenGold
                          : AmenColors.pureWhite,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AmenColors.amenGold,
                        )
                      : null,
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale(locale);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAccessibilityModal(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AmenColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final scaleFactor = ref.watch(textScaleFactorProvider);
            final percentage = (scaleFactor * 100).round();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  Text(
                    l10n.fontSizeAdjustment,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AmenColors.pureWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Increase or decrease font size across the app.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AmenColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: scaleFactor > 0.8
                            ? () => ref
                                  .read(textScaleFactorProvider.notifier)
                                  .decrease()
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        iconSize: 28,
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AmenColors.amenGold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        onPressed: scaleFactor < 1.6
                            ? () => ref
                                  .read(textScaleFactorProvider.notifier)
                                  .increase()
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        iconSize: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AmenColors.glass.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AmenColors.line.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Preview: "Peace I leave with you; my peace I give you."',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AmenColors.pureWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref.read(textScaleFactorProvider.notifier).reset();
                      },
                      child: AmenButtonLabel(
                        l10n.resetToDefault,
                        style: const TextStyle(color: AmenColors.mutedText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AmenColors.amenGold,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) {
    final controller = TextEditingController(text: user.displayName ?? '');
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AmenColors.night,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AmenColors.line.withValues(alpha: 0.5),
              width: 1.1,
            ),
          ),
          title: const Text(
            'Edit Display Name',
            style: TextStyle(
              color: AmenColors.pureWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AmenColors.pureWhite),
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(
              hintText: 'Enter name',
              hintStyle: TextStyle(color: AmenColors.mutedText),
              counterStyle: TextStyle(color: AmenColors.mutedText),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AmenColors.line),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AmenColors.amenGold),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AmenColors.mutedText),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await ref
                      .read(authRepositoryProvider)
                      .updateDisplayName(name);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AmenColors.amenGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserHeaderCard(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AmenColors.glass.withValues(alpha: 0.8),
            AmenColors.nightElevated.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AmenColors.amenGold, AmenColors.warmGold],
              ),
              boxShadow: [
                BoxShadow(
                  color: AmenColors.amenGold.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AmenColors.night,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: AmenColors.amenGold,
                      size: 36,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName ?? l10n.pilgrim,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AmenColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AmenColors.amenGold,
                        size: 20,
                      ),
                      onPressed: () => _showEditNameDialog(context, ref, user),
                    ),
                  ],
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AmenColors.mutedText,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AmenColors.amenGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AmenColors.amenGold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AmenColors.amenGold,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.badgeName('Faithful Pilgrim'),
                        style: const TextStyle(
                          color: AmenColors.amenGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHeaderCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AmenColors.glass.withValues(alpha: 0.85),
            AmenColors.nightElevated.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AmenColors.amenGold.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AmenColors.amenGold.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AmenColors.amenGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AmenColors.amenGold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: AmenColors.amenGold,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.beginYourJourney,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AmenColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.guestAccount,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AmenColors.mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              l10n.guestSignInBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AmenColors.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AmenColors.amenGold.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () => showAuthModal(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: AmenColors.amenGold,
                    foregroundColor: AmenColors.night,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login_rounded, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: AmenButtonLabel(
                          l10n.signInConnectAccount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiritualDashboard(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) {
    final l10n = AppLocalizations.of(context);
    final repository = ref.watch(intentionsRepositoryProvider);
    final streak = ref.watch(prayerStreakProvider);

    return StreamBuilder<List<Intention>>(
      stream: repository.watchGlobalWall(),
      builder: (context, snapshot) {
        final intentions = snapshot.data ?? const <Intention>[];
        final mine = intentions
            .where((item) => item.authorUid == user.uid)
            .toList();
        final amensReceived = mine.fold<int>(
          0,
          (total, item) => total + item.amenCount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, l10n.spiritualJourney),
            const SizedBox(height: 6),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF8C00),
                      value: '${streak.currentStreak}',
                      label: l10n.daysStreak,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.menu_book_rounded,
                      iconColor: AmenColors.blueMist,
                      value: '${mine.length}',
                      label: l10n.shared,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite_rounded,
                      iconColor: AmenColors.danger,
                      value: '$amensReceived',
                      label: l10n.amens,
                    ),
                  ),
                ],
              ),
            ),
            if (streak.unlockedBadges.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final badge in streak.unlockedBadges)
                    Chip(
                      avatar: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: AmenColors.amenGold,
                      ),
                      label: Text(l10n.badgeName(badge)),
                      backgroundColor: AmenColors.amenGold.withValues(
                        alpha: 0.10,
                      ),
                      side: BorderSide(
                        color: AmenColors.amenGold.withValues(alpha: 0.28),
                      ),
                      labelStyle: const TextStyle(
                        color: AmenColors.amenGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAccountActionsCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ListTile(
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(authRepositoryProvider).signOut();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Successfully signed out.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              minLeadingWidth: 44,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: AmenColors.amenGold.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AmenColors.amenGold,
                ),
              ),
              title: Text(
                l10n.signOut,
                style: const TextStyle(
                  color: AmenColors.pureWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                l10n.logOutBody,
                style: const TextStyle(
                  color: AmenColors.mutedText,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AmenColors.mutedText,
              ),
            ),
            Divider(
              color: AmenColors.line.withValues(alpha: 0.4),
              height: 1,
              indent: 18,
              endIndent: 18,
            ),
            Theme(
              data: ThemeData.dark().copyWith(
                dividerColor: Colors.transparent,
                expansionTileTheme: const ExpansionTileThemeData(
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                ),
              ),
              child: ExpansionTile(
                key: const PageStorageKey('profile-danger-zone-expansion-tile'),
                collapsedIconColor: AmenColors.mutedText,
                iconColor: Colors.redAccent,
                title: Text(
                  l10n.dangerZone,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0x11FF6B7A),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.deleteAccountWarning,
                          style: const TextStyle(
                            color: AmenColors.mutedText,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AmenColors.night,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  l10n.deleteAccount,
                                  style: const TextStyle(
                                    color: AmenColors.pureWhite,
                                  ),
                                ),
                                content: Text(
                                  l10n.deleteAccountConfirm,
                                  style: const TextStyle(
                                    color: AmenColors.mutedText,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      l10n.cancel,
                                      style: const TextStyle(
                                        color: AmenColors.mutedText,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      l10n.delete,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              try {
                                await ref
                                    .read(authRepositoryProvider)
                                    .deleteAccount();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Account permanently deleted.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to delete account: $e',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: AmenButtonLabel(
                            l10n.deleteAccount,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedLocale = ref.watch(appLocaleProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);
    final scalePercentage = (textScaleFactor * 100).round();
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    return CustomScrollView(
      key: const PageStorageKey('profile-scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          sliver: SliverList.list(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profile,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AmenColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.profilePreferencesSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AmenColors.mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (user != null && !user.isAnonymous) ...[
                _buildUserHeaderCard(context, ref, user),
                const SizedBox(height: 24),
                _buildSpiritualDashboard(context, ref, user),
              ] else ...[
                _buildGuestHeaderCard(context, ref),
              ],
              const SizedBox(height: 28),
              _buildSectionHeader(context, l10n.preferences),
              _PreferenceTile(
                icon: Icons.language_rounded,
                title: l10n.language,
                body: _getLanguageName(selectedLocale),
                onTap: () => _showLanguageSelector(context, ref),
              ),
              const SizedBox(height: 12),
              _PreferenceTile(
                icon: Icons.notifications_none_rounded,
                title: l10n.notifications,
                body: notificationsEnabled
                    ? l10n.gentleRemindersEnabled
                    : l10n.notificationsTurnedOff,
                trailing: Switch(
                  value: notificationsEnabled,
                  activeThumbColor: AmenColors.amenGold,
                  activeTrackColor: AmenColors.amenGold.withValues(alpha: 0.3),
                  onChanged: (val) {
                    ref
                        .read(notificationsEnabledProvider.notifier)
                        .setEnabled(val, ref.read(notificationServiceProvider));
                  },
                ),
              ),
              const SizedBox(height: 12),
              _PreferenceTile(
                icon: Icons.accessibility_new_rounded,
                title: l10n.accessibility,
                body: l10n.adjustFontSize(scalePercentage),
                onTap: () => _showAccessibilityModal(context, ref),
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(context, l10n.aboutLegal),
              _PreferenceTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                body: l10n.readPrivacyPractices,
                onTap: () => showLegalTermsModal(context, isPrivacy: true),
              ),
              const SizedBox(height: 12),
              _PreferenceTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfService,
                body: l10n.readTermsConditions,
                onTap: () => showLegalTermsModal(context, isPrivacy: false),
              ),
              if (user != null && !user.isAnonymous) ...[
                const SizedBox(height: 28),
                _buildSectionHeader(context, l10n.accountSettings),
                _buildAccountActionsCard(context, ref),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AmenColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AmenColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          onTap: onTap,
          minLeadingWidth: 44,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: AmenColors.amenGold.withValues(alpha: 0.13),
            child: Icon(icon, color: AmenColors.amenGold),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AmenColors.pureWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AmenColors.mutedText),
            ),
          ),
          trailing:
              trailing ??
              (onTap != null
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: AmenColors.mutedText,
                    )
                  : null),
        ),
      ),
    );
  }
}
