import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_colors.dart';
import '../data/library_repository.dart';
import '../domain/prayer_reflection.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(libraryRepositoryProvider);
    final textTheme = Theme.of(context).textTheme;
    final items = repository.getItems(
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );

    return Scaffold(
      backgroundColor: AmenColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'PRAYERS & REFLECTIONS',
          style: textTheme.titleMedium?.copyWith(
            letterSpacing: 2.0,
            color: AmenColors.amenGold,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AmenColors.pureWhite),
              decoration: InputDecoration(
                hintText: 'Search prayers, themes, scriptures...',
                hintStyle: TextStyle(color: AmenColors.mutedText.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.search, color: AmenColors.amenGold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AmenColors.mutedText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AmenColors.nightElevated,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AmenColors.blueMist.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AmenColors.blueMist.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AmenColors.amenGold,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: repository.categories.length,
              itemBuilder: (context, index) {
                final cat = repository.categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AmenColors.amenGold.withValues(alpha: 0.25),
                    backgroundColor: AmenColors.nightElevated,
                    checkmarkColor: AmenColors.amenGold,
                    labelStyle: TextStyle(
                      color: isSelected ? AmenColors.amenGold : AmenColors.mutedText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AmenColors.amenGold
                          : AmenColors.blueMist.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No prayers found matching "$_searchQuery"',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AmenColors.mutedText,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _LibraryCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.item});

  final PrayerReflection item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AmenColors.nightElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AmenColors.amenGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AmenColors.night.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: AmenColors.amenGold,
        collapsedIconColor: AmenColors.mutedText,
        title: Text(
          item.title,
          style: textTheme.titleMedium?.copyWith(
            color: AmenColors.pureWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Text(
                '${item.timeOfDay.icon} ${item.category}',
                style: textTheme.labelSmall?.copyWith(
                  color: AmenColors.amenGold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.schedule,
                size: 14,
                color: AmenColors.mutedText.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '${item.readTimeMinutes} min read',
                style: textTheme.labelSmall?.copyWith(
                  color: AmenColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AmenColors.blueMist, height: 24),
                Text(
                  item.body.trim(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: AmenColors.pureWhite.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  children: item.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AmenColors.night,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AmenColors.blueMist.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: textTheme.labelSmall?.copyWith(
                          color: AmenColors.mutedText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
