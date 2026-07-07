import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../design_system/amen_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../library/domain/prayer_reflection.dart';
import '../data/admin_catalog_repository.dart';
import '../../altar/domain/altar_music_track.dart';
import '../../altar/data/altar_music_repository.dart';

class AdminCatalogScreen extends ConsumerWidget {
  const AdminCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final adminStatus = ref.watch(adminStatusProvider);

    return Scaffold(
      backgroundColor: AmenColors.deepSpace,
      body: SafeArea(
        child: authState.when(
          loading: () => const _AdminLoading(),
          error: (error, _) => _AdminMessage(
            icon: Icons.error_outline_rounded,
            title: 'Admin unavailable',
            message: '$error',
          ),
          data: (user) {
            if (user == null || user.isAnonymous) {
              return const _AdminSignInView();
            }
            return adminStatus.when(
              loading: () => const _AdminLoading(),
              error: (error, _) => _AdminMessage(
                icon: Icons.lock_outline_rounded,
                title: 'Admin check failed',
                message: '$error',
              ),
              data: (status) {
                if (!status.isAdmin) {
                  return _AdminDeniedView(status: status);
                }
                return const _AdminCatalogDashboard();
              },
            );
          },
        ),
      ),
    );
  }
}

class _AdminLoading extends StatelessWidget {
  const _AdminLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AmenColors.amenGold),
    );
  }
}

class _AdminSignInView extends ConsumerStatefulWidget {
  const _AdminSignInView();

  @override
  ConsumerState<_AdminSignInView> createState() => _AdminSignInViewState();
}

class _AdminSignInViewState extends ConsumerState<_AdminSignInView> {
  var _isSigningIn = false;
  String? _error;

  Future<void> _signIn(Future<void> Function() action) async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      await action();
      ref.invalidate(adminStatusProvider);
    } catch (error) {
      setState(() => _error = _friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: AmenColors.amenGold,
                size: 54,
              ),
              const SizedBox(height: 18),
              Text(
                'Amen Admin',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AmenColors.pureWhite,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isSigningIn
                    ? null
                    : () => _signIn(() async {
                        final repo = ref.read(authRepositoryProvider);
                        final credential = await repo.signInWithGoogle();
                        final signedIn =
                            credential?.user?.isAnonymous == false ||
                            repo.currentUser?.isAnonymous == false;
                        if (!signedIn) {
                          throw StateError(
                            'Google sign-in did not complete. Please choose your admin Google account again.',
                          );
                        }
                      }),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSigningIn
                    ? null
                    : () => _signIn(() async {
                        final repo = ref.read(authRepositoryProvider);
                        final credential = await repo.signInWithApple();
                        final signedIn =
                            credential?.user?.isAnonymous == false ||
                            repo.currentUser?.isAnonymous == false;
                        if (!signedIn) {
                          throw StateError(
                            'Apple sign-in did not complete. Please choose your admin Apple account again.',
                          );
                        }
                      }),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Sign in with Apple'),
              ),
              if (_isSigningIn) ...[
                const SizedBox(height: 18),
                const LinearProgressIndicator(color: AmenColors.amenGold),
              ],
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(_error!, style: const TextStyle(color: AmenColors.danger)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyAuthError(Object error) {
  final message = '$error';
  return message
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '')
      .trim();
}

class _AdminDeniedView extends ConsumerWidget {
  const _AdminDeniedView({required this.status});

  final CatalogAdminStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AdminMessage(
      icon: Icons.lock_outline_rounded,
      title: 'Access denied',
      message:
          status.message ?? 'No admin claim was found for ${status.email}.',
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
            ref.invalidate(adminStatusProvider);
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        FilledButton.icon(
          onPressed: () => ref.invalidate(adminStatusProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Check again'),
        ),
      ],
    );
  }
}

class _AdminMessage extends StatelessWidget {
  const _AdminMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AmenColors.amenGold, size: 52),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 22),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCatalogDashboard extends ConsumerStatefulWidget {
  const _AdminCatalogDashboard();

  @override
  ConsumerState<_AdminCatalogDashboard> createState() =>
      _AdminCatalogDashboardState();
}

class _AdminCatalogDashboardState
    extends ConsumerState<_AdminCatalogDashboard> {
  var _locale = 'en';
  String? _selectedCategoryId;
  String? _selectedPrayerId;
  var _isPublishing = false;
  var _currentDashboard = 0; // 0 = Catalog, 1 = Relaxing Music

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(draftCategoriesProvider(_locale));
    final prayersAsync = ref.watch(draftPrayersProvider(_locale));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.church_rounded),
                    label: Text('Prayer Catalog'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.music_note_rounded),
                    label: Text('Relaxing Music'),
                  ),
                ],
                selected: {_currentDashboard},
                onSelectionChanged: (val) {
                  setState(() {
                    _currentDashboard = val.first;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
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
              ),
              const Spacer(),
              if (_currentDashboard == 0) ...[
                _LanguageTabs(
                  locale: _locale,
                  onChanged: (locale) {
                    setState(() {
                      _locale = locale;
                      _selectedPrayerId = null;
                    });
                  },
                ),
                const SizedBox(width: 12),
              ],
              IconButton.filledTonal(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  ref.invalidate(adminStatusProvider);
                },
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign out',
              ),
            ],
          ),
        ),
        Expanded(
          child: _currentDashboard == 1
              ? const _AdminMusicDashboard()
              : categoriesAsync.when(
                  loading: () => const _AdminLoading(),
                  error: (error, _) => _AdminMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Catalog failed',
                    message: '$error',
                  ),
                  data: (categories) {
                    final selectedCategory = _resolveCategory(categories);
                    final allPrayers = prayersAsync.when(
                      data: (items) => items,
                      loading: () => const <PrayerReflection>[],
                      error: (_, _) => const <PrayerReflection>[],
                    );
                    final filteredPrayers = allPrayers
                        .where(
                          (prayer) =>
                              selectedCategory == null ||
                              prayer.categoryId == selectedCategory.id,
                        )
                        .toList(growable: false);
                    final selectedPrayer = _resolvePrayer(filteredPrayers);

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 980;
                        final lists = _CatalogLists(
                          locale: _locale,
                          categories: categories,
                          prayersAsync: prayersAsync,
                          selectedCategory: selectedCategory,
                          selectedPrayer: selectedPrayer,
                          onCategorySelected: (category) {
                            setState(() {
                              _selectedCategoryId = category.id;
                              _selectedPrayerId = null;
                            });
                          },
                          onPrayerSelected: (prayer) {
                            setState(() => _selectedPrayerId = prayer.id);
                          },
                          onCategoryCreated: (id) {
                            setState(() {
                              _selectedCategoryId = id;
                              _selectedPrayerId = null;
                            });
                          },
                          onPrayerCreated: (id) =>
                              setState(() => _selectedPrayerId = id),
                        );
                        final editors = _EditorWorkspace(
                          locale: _locale,
                          category: selectedCategory,
                          prayer: selectedPrayer,
                          categories: categories,
                          onPublish: () => _publishCatalog(context),
                          isPublishing: _isPublishing,
                        );

                        if (compact) {
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                            children: [
                              lists,
                              const SizedBox(height: 16),
                              editors,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: 360, child: lists),
                            const VerticalDivider(
                              color: AmenColors.line,
                              width: 1,
                            ),
                            Expanded(child: editors),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  PrayerCatalogCategory? _resolveCategory(
    List<PrayerCatalogCategory> categories,
  ) {
    if (categories.isEmpty) return null;
    return categories.firstWhere(
      (category) => category.id == _selectedCategoryId,
      orElse: () => categories.first,
    );
  }

  PrayerReflection? _resolvePrayer(List<PrayerReflection> prayers) {
    if (prayers.isEmpty) return null;
    return prayers.firstWhere(
      (prayer) => prayer.id == _selectedPrayerId,
      orElse: () => prayers.first,
    );
  }

  Future<void> _publishCatalog(BuildContext context) async {
    setState(() => _isPublishing = true);
    try {
      final errors = await ref
          .read(adminCatalogRepositoryProvider)
          .publishPrayerCatalog(_locale);
      if (!context.mounted) return;
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_locale.toUpperCase()} catalog published')),
        );
      } else {
        _showErrors(context, 'Publish blocked', errors);
      }
    } catch (error) {
      if (context.mounted) {
        _showErrors(context, 'Publish failed', ['$error']);
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }
}

class _LanguageTabs extends StatelessWidget {
  const _LanguageTabs({required this.locale, required this.onChanged});

  final String locale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'en', label: Text('English')),
        ButtonSegment(value: 'es', label: Text('Spanish')),
        ButtonSegment(value: 'fr', label: Text('French')),
      ],
      selected: {locale},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
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
    );
  }
}

class _CatalogLists extends ConsumerWidget {
  const _CatalogLists({
    required this.locale,
    required this.categories,
    required this.prayersAsync,
    required this.selectedCategory,
    required this.selectedPrayer,
    required this.onCategorySelected,
    required this.onPrayerSelected,
    required this.onCategoryCreated,
    required this.onPrayerCreated,
  });

  final String locale;
  final List<PrayerCatalogCategory> categories;
  final AsyncValue<List<PrayerReflection>> prayersAsync;
  final PrayerCatalogCategory? selectedCategory;
  final PrayerReflection? selectedPrayer;
  final ValueChanged<PrayerCatalogCategory> onCategorySelected;
  final ValueChanged<PrayerReflection> onPrayerSelected;
  final ValueChanged<String> onCategoryCreated;
  final ValueChanged<String> onPrayerCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(adminCatalogRepositoryProvider);
    final allPrayers = prayersAsync.when(
      data: (items) => items,
      loading: () => const <PrayerReflection>[],
      error: (_, _) => const <PrayerReflection>[],
    );
    final prayers = allPrayers
        .where(
          (prayer) =>
              selectedCategory == null ||
              prayer.categoryId == selectedCategory!.id,
        )
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'Catalogs',
            action: IconButton.filledTonal(
              onPressed: () async {
                final id = await repository.createCategory(locale);
                onCategoryCreated(id);
              },
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create catalog',
            ),
          ),
          const SizedBox(height: 10),
          for (final category in categories)
            _CategoryRow(
              category: category,
              selected: category.id == selectedCategory?.id,
              onTap: () => onCategorySelected(category),
            ),
          if (categories.isEmpty)
            const _EmptyPanel(
              icon: Icons.library_add_outlined,
              title: 'No catalogs',
            ),
          const SizedBox(height: 22),
          _PanelHeader(
            title: 'Prayers',
            action: IconButton.filledTonal(
              onPressed: selectedCategory == null
                  ? null
                  : () async {
                      final id = await repository.createPrayer(
                        locale,
                        selectedCategory!.id,
                      );
                      onPrayerCreated(id);
                    },
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create prayer',
            ),
          ),
          const SizedBox(height: 10),
          prayersAsync.when(
            loading: () =>
                const LinearProgressIndicator(color: AmenColors.amenGold),
            error: (error, _) => Text(
              '$error',
              style: const TextStyle(color: AmenColors.danger),
            ),
            data: (_) => Column(
              children: [
                for (final prayer in prayers)
                  _PrayerRow(
                    prayer: prayer,
                    selected: prayer.id == selectedPrayer?.id,
                    onTap: () => onPrayerSelected(prayer),
                  ),
                if (prayers.isEmpty)
                  const _EmptyPanel(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'No prayers',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorWorkspace extends ConsumerWidget {
  const _EditorWorkspace({
    required this.locale,
    required this.category,
    required this.prayer,
    required this.categories,
    required this.onPublish,
    required this.isPublishing,
  });

  final String locale;
  final PrayerCatalogCategory? category;
  final PrayerReflection? prayer;
  final List<PrayerCatalogCategory> categories;
  final VoidCallback onPublish;
  final bool isPublishing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = category;
    final selectedPrayer = prayer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        Row(
          children: [
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final errors = await ref
                      .read(adminCatalogRepositoryProvider)
                      .validatePrayerCatalog(locale);
                  if (!context.mounted) return;
                  if (errors.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catalog is ready')),
                    );
                  } else {
                    _showErrors(context, 'Validation results', errors);
                  }
                } catch (error) {
                  if (context.mounted) {
                    _showErrors(context, 'Validation failed', ['$error']);
                  }
                }
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Validate'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: isPublishing ? null : onPublish,
              icon: isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Publish'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (selectedCategory == null)
          const _EmptyPanel(
            icon: Icons.library_add_outlined,
            title: 'Select a catalog',
          )
        else
          _CategoryEditor(locale: locale, category: selectedCategory),
        const SizedBox(height: 16),
        if (selectedPrayer == null)
          const _EmptyPanel(
            icon: Icons.volunteer_activism_outlined,
            title: 'Select a prayer',
          )
        else
          _PrayerEditor(
            locale: locale,
            prayer: selectedPrayer,
            categories: categories,
          ),
      ],
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.locale, required this.category});

  final String locale;
  final PrayerCatalogCategory category;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortController;
  late bool _isActive;
  var _isSaving = false;
  var _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _sortController = TextEditingController();
    _load(widget.category);
  }

  @override
  void didUpdateWidget(covariant _CategoryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.id != widget.category.id ||
        oldWidget.locale != widget.locale ||
        oldWidget.category.updatedAt != widget.category.updatedAt) {
      _load(widget.category);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  void _load(PrayerCatalogCategory category) {
    _titleController.text = category.title;
    _descriptionController.text = category.description;
    _sortController.text = '${category.sortOrder}';
    _isActive = category.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(adminCatalogRepositoryProvider);

    return _EditorPanel(
      title: 'Catalog details',
      icon: Icons.folder_copy_outlined,
      trailing: Switch(
        value: _isActive,
        activeThumbColor: AmenColors.amenGold,
        onChanged: (value) => setState(() => _isActive = value),
      ),
      children: [
        _MediaPreview(
          url: widget.category.backgroundImageUrl,
          icon: Icons.image_outlined,
          action: OutlinedButton.icon(
            onPressed: _isUploading
                ? null
                : () async {
                    setState(() => _isUploading = true);
                    try {
                      await repository.pickAndUploadMedia(
                        target: CatalogMediaTarget.categoryBackground,
                        ownerId: widget.category.id,
                      );
                    } finally {
                      if (mounted) setState(() => _isUploading = false);
                    }
                  },
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: const Text('Background'),
          ),
        ),
        const SizedBox(height: 14),
        _TextField(label: 'Title', controller: _titleController),
        const SizedBox(height: 12),
        _TextField(
          label: 'Description',
          controller: _descriptionController,
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Sort order',
          controller: _sortController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    try {
                      final updated = widget.category.copyWith(
                        isActive: _isActive,
                        sortOrder:
                            int.tryParse(_sortController.text.trim()) ??
                            widget.category.sortOrder,
                      );
                      await repository.saveCategoryShared(updated);
                      await repository.saveCategoryText(
                        locale: widget.locale,
                        categoryId: widget.category.id,
                        title: _titleController.text,
                        description: _descriptionController.text,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Catalog saved')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save catalog'),
          ),
        ),
      ],
    );
  }
}

class _PrayerEditor extends ConsumerStatefulWidget {
  const _PrayerEditor({
    required this.locale,
    required this.prayer,
    required this.categories,
  });

  final String locale;
  final PrayerReflection prayer;
  final List<PrayerCatalogCategory> categories;

  @override
  ConsumerState<_PrayerEditor> createState() => _PrayerEditorState();
}

class _PrayerEditorState extends ConsumerState<_PrayerEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagsController;
  late final TextEditingController _readTimeController;
  late final TextEditingController _sortController;
  late String _categoryId;
  late TimeOfDayTag _timeOfDay;
  late bool _isActive;
  var _isSaving = false;
  var _uploadingImage = false;
  var _uploadingAudio = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _authorController = TextEditingController();
    _bodyController = TextEditingController();
    _tagsController = TextEditingController();
    _readTimeController = TextEditingController();
    _sortController = TextEditingController();
    _load(widget.prayer);
  }

  @override
  void didUpdateWidget(covariant _PrayerEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayer.id != widget.prayer.id ||
        oldWidget.locale != widget.locale ||
        oldWidget.prayer.updatedAt != widget.prayer.updatedAt) {
      _load(widget.prayer);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    _readTimeController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  void _load(PrayerReflection prayer) {
    _titleController.text = prayer.title;
    _authorController.text = prayer.author;
    _bodyController.text = prayer.body;
    _tagsController.text = prayer.tags.join(', ');
    _readTimeController.text = '${prayer.readTimeMinutes}';
    _sortController.text = '${prayer.sortOrder}';
    _categoryId = prayer.categoryId;
    _timeOfDay = prayer.timeOfDay;
    _isActive = prayer.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(adminCatalogRepositoryProvider);

    return _EditorPanel(
      title: 'Prayer details',
      icon: Icons.volunteer_activism_outlined,
      trailing: Switch(
        value: _isActive,
        activeThumbColor: AmenColors.amenGold,
        onChanged: (value) => setState(() => _isActive = value),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _MediaPreview(
                url: widget.prayer.backgroundImageUrl,
                icon: Icons.image_outlined,
                action: OutlinedButton.icon(
                  onPressed: _uploadingImage
                      ? null
                      : () async {
                          setState(() => _uploadingImage = true);
                          try {
                            await repository.pickAndUploadMedia(
                              target: CatalogMediaTarget.prayerBackground,
                              ownerId: widget.prayer.id,
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _uploadingImage = false);
                            }
                          }
                        },
                  icon: _uploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: const Text('Background'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MediaPreview(
                url: null,
                icon: widget.prayer.audioUrl == null
                    ? Icons.music_off_outlined
                    : Icons.music_note_rounded,
                title: widget.prayer.audioUrl == null
                    ? 'No audio'
                    : 'Audio ready',
                action: OutlinedButton.icon(
                  onPressed: _uploadingAudio
                      ? null
                      : () async {
                          setState(() => _uploadingAudio = true);
                          try {
                            await repository.pickAndUploadMedia(
                              target: CatalogMediaTarget.prayerAudio,
                              ownerId: widget.prayer.id,
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _uploadingAudio = false);
                            }
                          }
                        },
                  icon: _uploadingAudio
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.audio_file_outlined),
                  label: const Text('Music'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue:
              widget.categories.any((category) => category.id == _categoryId)
              ? _categoryId
              : null,
          decoration: const InputDecoration(labelText: 'Catalog'),
          items: [
            for (final category in widget.categories)
              DropdownMenuItem(value: category.id, child: Text(category.title)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _categoryId = value);
          },
        ),
        const SizedBox(height: 12),
        _TextField(label: 'Title', controller: _titleController),
        const SizedBox(height: 12),
        _TextField(label: 'Author or source', controller: _authorController),
        const SizedBox(height: 12),
        _TextField(
          label: 'Body',
          controller: _bodyController,
          minLines: 7,
          maxLines: 14,
        ),
        const SizedBox(height: 12),
        _TextField(label: 'Tags', controller: _tagsController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<TimeOfDayTag>(
                initialValue: _timeOfDay,
                decoration: const InputDecoration(labelText: 'Time'),
                items: [
                  for (final tag in TimeOfDayTag.values)
                    DropdownMenuItem(value: tag, child: Text(tag.displayName)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _timeOfDay = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TextField(
                label: 'Read time',
                controller: _readTimeController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TextField(
                label: 'Sort order',
                controller: _sortController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _PrayerPreviewDialog(
                  prayer: widget.prayer.copyWith(
                    title: _titleController.text,
                    body: _bodyController.text,
                    author: _authorController.text,
                    tags: stringListValue(_tagsController.text),
                    timeOfDay: _timeOfDay,
                    readTimeMinutes:
                        int.tryParse(_readTimeController.text.trim()) ??
                        widget.prayer.readTimeMinutes,
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview'),
            ),
            FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        final updated = widget.prayer.copyWith(
                          categoryId: _categoryId,
                          isActive: _isActive,
                          timeOfDay: _timeOfDay,
                          readTimeMinutes:
                              int.tryParse(_readTimeController.text.trim()) ??
                              widget.prayer.readTimeMinutes,
                          sortOrder:
                              int.tryParse(_sortController.text.trim()) ??
                              widget.prayer.sortOrder,
                        );
                        await repository.savePrayerShared(updated);
                        await repository.savePrayerText(
                          locale: widget.locale,
                          prayerId: widget.prayer.id,
                          title: _titleController.text,
                          body: _bodyController.text,
                          author: _authorController.text,
                          tags: stringListValue(_tagsController.text),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Prayer saved')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save prayer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        action,
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final PrayerCatalogCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableRow(
      selected: selected,
      onTap: onTap,
      leading: _Thumb(
        url: category.backgroundImageUrl,
        icon: Icons.folder_outlined,
      ),
      title: category.title,
      subtitle: category.isActive ? 'Active' : 'Archived',
      trailing: Icon(
        category.isActive ? Icons.check_circle_rounded : Icons.archive_outlined,
        color: category.isActive ? AmenColors.amenGold : AmenColors.mutedText,
        size: 18,
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.selected,
    required this.onTap,
  });

  final PrayerReflection prayer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableRow(
      selected: selected,
      onTap: onTap,
      leading: _Thumb(
        url: prayer.backgroundImageUrl,
        icon: Icons.volunteer_activism_outlined,
      ),
      title: prayer.title,
      subtitle: '${prayer.timeOfDay.icon} ${prayer.readTimeMinutes} min',
      trailing: Icon(
        prayer.audioUrl == null
            ? Icons.music_off_outlined
            : Icons.music_note_rounded,
        color: prayer.audioUrl == null
            ? AmenColors.mutedText
            : AmenColors.amenGold,
        size: 18,
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AmenColors.amenGold.withValues(alpha: 0.16)
            : AmenColors.nightElevated,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AmenColors.amenGold
                              : AmenColors.pureWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AmenColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.icon});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url == null
            ? ColoredBox(
                color: AmenColors.night,
                child: Icon(icon, color: AmenColors.amenGold),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AmenColors.night,
                  child: Icon(icon, color: AmenColors.amenGold),
                ),
              ),
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.night.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AmenColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AmenColors.amenGold),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AmenColors.pureWhite),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.url,
    required this.icon,
    required this.action,
    this.title,
  });

  final String? url;
  final IconData icon;
  final Widget action;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.nightElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AmenColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76,
                height: 56,
                child: url == null
                    ? ColoredBox(
                        color: AmenColors.night,
                        child: Icon(icon, color: AmenColors.amenGold),
                      )
                    : Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: AmenColors.night,
                          child: Icon(icon, color: AmenColors.amenGold),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? (url == null ? 'No image' : 'Image ready'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.nightElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AmenColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AmenColors.amenGold),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PrayerPreviewDialog extends StatelessWidget {
  const _PrayerPreviewDialog({required this.prayer});

  final PrayerReflection prayer;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AmenColors.deepSpace,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Stack(
          children: [
            if (prayer.backgroundImageUrl != null)
              Positioned.fill(
                child: Image.network(
                  prayer.backgroundImageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AmenColors.night.withValues(alpha: 0.78),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prayer.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AmenColors.amenGold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${prayer.category} - ${prayer.readTimeMinutes} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(color: AmenColors.line, height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        prayer.body,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AmenColors.pureWhite,
                          height: 1.6,
                        ),
                      ),
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
}

void _showErrors(BuildContext context, String title, List<String> errors) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AmenColors.deepSpace,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: errors.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AmenColors.line),
                  itemBuilder: (context, index) {
                    return Text(
                      errors[index],
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AdminMusicDashboard extends ConsumerStatefulWidget {
  const _AdminMusicDashboard();

  @override
  ConsumerState<_AdminMusicDashboard> createState() =>
      _AdminMusicDashboardState();
}

class _AdminMusicDashboardState extends ConsumerState<_AdminMusicDashboard> {
  String? _selectedTrackId;

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(altarMusicTracksProvider);

    return Column(
      children: [
        Expanded(
          child: tracksAsync.when(
            loading: () => const _AdminLoading(),
            error: (error, _) => _AdminMessage(
              icon: Icons.error_outline_rounded,
              title: 'Music load failed',
              message: '$error',
            ),
            data: (tracks) {
              if (tracks.isEmpty) {
                Future.microtask(() {
                  ref.read(altarMusicRepositoryProvider).seedDefaultTrack();
                });
              }

              final selectedTrack = tracks.firstWhere(
                (track) => track.id == _selectedTrackId,
                orElse: () => tracks.isNotEmpty
                    ? tracks.first
                    : const AltarMusicTrack(
                        id: '',
                        title: '',
                        artist: '',
                        audioUrl: '',
                        audioPath: '',
                        isActive: true,
                        sortOrder: 0,
                      ),
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 980;

                  final listWidget = _MusicLists(
                    tracks: tracks,
                    selectedTrackId:
                        _selectedTrackId ??
                        (tracks.isNotEmpty ? tracks.first.id : null),
                    onTrackSelected: (trackId) {
                      setState(() => _selectedTrackId = trackId);
                    },
                    onTrackCreated: (trackId) {
                      setState(() => _selectedTrackId = trackId);
                    },
                  );

                  final editorWidget = tracks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 48,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.music_note_outlined,
                                  size: 64,
                                  color: AmenColors.mutedText,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Relaxing Music Tracks Yet',
                                  style: TextStyle(
                                    color: AmenColors.pureWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Upload background tracks for the Altar screen.',
                                  style: TextStyle(
                                    color: AmenColors.mutedText,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () async {
                                    final id = await ref
                                        .read(altarMusicRepositoryProvider)
                                        .createMusicTrack(
                                          title: 'New relaxing track',
                                          artist: 'Unknown Artist',
                                        );
                                    setState(() => _selectedTrackId = id);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AmenColors.amenGold,
                                    foregroundColor: AmenColors.night,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text(
                                    'Add Relaxing Track',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _MusicEditorWorkspace(track: selectedTrack);

                  if (compact) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      children: [
                        listWidget,
                        const SizedBox(height: 16),
                        editorWidget,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 360, child: listWidget),
                      const VerticalDivider(color: AmenColors.line, width: 1),
                      Expanded(child: editorWidget),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MusicLists extends ConsumerWidget {
  const _MusicLists({
    required this.tracks,
    required this.selectedTrackId,
    required this.onTrackSelected,
    required this.onTrackCreated,
  });

  final List<AltarMusicTrack> tracks;
  final String? selectedTrackId;
  final ValueChanged<String> onTrackSelected;
  final ValueChanged<String> onTrackCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(altarMusicRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'Relaxing Music',
            action: IconButton.filledTonal(
              onPressed: () async {
                final id = await repository.createMusicTrack(
                  title: 'New relaxing track',
                  artist: 'Unknown Artist',
                );
                onTrackCreated(id);
              },
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add track',
            ),
          ),
          const SizedBox(height: 10),
          for (final track in tracks)
            _MusicRow(
              track: track,
              selected: track.id == selectedTrackId,
              onTap: () => onTrackSelected(track.id),
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AmenColors.nightElevated,
                    title: const Text(
                      'Delete track?',
                      style: TextStyle(color: AmenColors.pureWhite),
                    ),
                    content: Text(
                      'Are you sure you want to delete "${track.title}"? This action cannot be undone.',
                      style: const TextStyle(color: AmenColors.mutedText),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AmenColors.danger,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await repository.deleteMusicTrack(track);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Track deleted')),
                    );
                  }
                }
              },
            ),
          if (tracks.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final id = await repository.createMusicTrack(
                  title: 'New relaxing track',
                  artist: 'Unknown Artist',
                );
                onTrackCreated(id);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AmenColors.amenGold,
                side: const BorderSide(color: AmenColors.line),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add New Track'),
            ),
          ] else ...[
            const _EmptyPanel(
              icon: Icons.music_off_outlined,
              title: 'No relaxing music',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final id = await repository.createMusicTrack(
                  title: 'New relaxing track',
                  artist: 'Unknown Artist',
                );
                onTrackCreated(id);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AmenColors.amenGold,
                foregroundColor: AmenColors.night,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Track'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MusicRow extends StatelessWidget {
  const _MusicRow({
    required this.track,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final AltarMusicTrack track;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AmenColors.nightElevated : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? AmenColors.amenGold.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Icon(
                  track.isActive
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  color: track.isActive
                      ? AmenColors.amenGold
                      : AmenColors.mutedText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: TextStyle(
                          color: selected
                              ? AmenColors.pureWhite
                              : AmenColors.text,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        style: const TextStyle(
                          color: AmenColors.mutedText,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AmenColors.danger,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicEditorWorkspace extends ConsumerStatefulWidget {
  const _MusicEditorWorkspace({required this.track});
  final AltarMusicTrack track;

  @override
  ConsumerState<_MusicEditorWorkspace> createState() =>
      _MusicEditorWorkspaceState();
}

class _MusicEditorWorkspaceState extends ConsumerState<_MusicEditorWorkspace> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _sortController;
  late bool _isActive;

  var _isSaving = false;
  var _isUploading = false;

  // Preview Player State
  AudioPlayer? _previewPlayer;
  bool _isPreviewPlaying = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _artistController = TextEditingController();
    _sortController = TextEditingController();
    _load(widget.track);
  }

  @override
  void didUpdateWidget(covariant _MusicEditorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id ||
        oldWidget.track.updatedAt != widget.track.updatedAt) {
      _load(widget.track);
      _stopPreview();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _sortController.dispose();
    _previewPlayer?.dispose();
    super.dispose();
  }

  void _load(AltarMusicTrack track) {
    _titleController.text = track.title;
    _artistController.text = track.artist;
    _sortController.text = '${track.sortOrder}';
    _isActive = track.isActive;
  }

  void _togglePreview(String url) async {
    if (_previewPlayer == null) {
      _previewPlayer = AudioPlayer();
      _previewPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPreviewPlaying = state.playing;
          });
        }
      });
    }

    try {
      if (_isPreviewPlaying) {
        await _previewPlayer!.pause();
      } else {
        await _previewPlayer!.setUrl(url);
        await _previewPlayer!.play();
      }
    } catch (_) {}
  }

  void _stopPreview() async {
    if (_previewPlayer != null && _isPreviewPlaying) {
      try {
        await _previewPlayer!.stop();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(altarMusicRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        _EditorPanel(
          title: 'Track details',
          icon: Icons.music_video_outlined,
          trailing: Switch(
            value: _isActive,
            activeThumbColor: AmenColors.amenGold,
            onChanged: (value) => setState(() => _isActive = value),
          ),
          children: [
            // Audio File section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AmenColors.night,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AmenColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AmenColors.nightElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.audiotrack_rounded,
                      color: AmenColors.amenGold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.audioUrl.isNotEmpty
                              ? 'Audio track uploaded'
                              : 'No audio file uploaded',
                          style: const TextStyle(
                            color: AmenColors.pureWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.track.audioUrl.isNotEmpty
                              ? widget.track.audioPath.split('/').last
                              : 'Supports MP3 and M4A',
                          style: const TextStyle(
                            color: AmenColors.mutedText,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.track.audioUrl.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(
                        _isPreviewPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AmenColors.amenGold,
                      ),
                      onPressed: () => _togglePreview(widget.track.audioUrl),
                      tooltip: 'Preview track',
                    ),
                    const SizedBox(width: 4),
                  ],
                  OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              allowMultiple: false,
                              type: FileType.custom,
                              allowedExtensions: ['mp3', 'm4a'],
                              withData: true,
                            );
                            final file = result?.files.single;
                            final bytes = file?.bytes;
                            if (file != null && bytes != null) {
                              setState(() => _isUploading = true);
                              try {
                                await repository.uploadMusicAudio(
                                  trackId: widget.track.id,
                                  filename: file.name,
                                  bytes: bytes,
                                  contentType:
                                      file.name.toLowerCase().endsWith('.m4a')
                                      ? 'audio/mp4'
                                      : 'audio/mpeg',
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Audio uploaded successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  _showErrors(context, 'Upload failed', [
                                    e.toString(),
                                  ]);
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isUploading = false);
                                }
                              }
                            }
                          },
                    icon: _isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AmenColors.amenGold,
                            ),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(
                      widget.track.audioUrl.isNotEmpty ? 'Replace' : 'Upload',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TextField(label: 'Title', controller: _titleController),
            const SizedBox(height: 12),
            _TextField(label: 'Artist / Author', controller: _artistController),
            const SizedBox(height: 12),
            _TextField(
              label: 'Sort order',
              controller: _sortController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        try {
                          final updated = widget.track.copyWith(
                            title: _titleController.text,
                            artist: _artistController.text,
                            isActive: _isActive,
                            sortOrder:
                                int.tryParse(_sortController.text.trim()) ??
                                widget.track.sortOrder,
                          );
                          await repository.updateMusicTrack(updated);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Track details saved'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save track'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
