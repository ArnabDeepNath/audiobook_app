import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../models/tag_model.dart';

class FilterDrawer extends StatefulWidget {
  final Function(bool)? onFilterStateChanged;

  const FilterDrawer({
    Key? key,
    this.onFilterStateChanged,
  }) : super(key: key);

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late final BookProvider _bookProvider;

  @override
  void initState() {
    super.initState();
    _bookProvider = Provider.of<BookProvider>(context, listen: false);
    _loadTags();
    // Enable filtering mode when drawer opens
    _bookProvider.setFilteringMode(true);
    widget.onFilterStateChanged?.call(true);
  }

  @override
  void dispose() {
    // Only disable filtering mode if no filters are active
    if (_bookProvider.selectedTagIds.isEmpty &&
        _bookProvider.selectedCategories.isEmpty &&
        !_bookProvider.showFreeOnly &&
        !_bookProvider.showAudioOnly) {
      _bookProvider.setFilteringMode(false);
      widget.onFilterStateChanged?.call(false);
    }
    super.dispose();
  }

  Future<void> _loadTags() async {
    await _bookProvider.fetchTags();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        // Don't change filtering mode here - it's managed by the filter state
        return true;
      },
      child: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor,
                child: Text(
                  lang.translate('filter'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSwitchTile(
                      context: context,
                      title: lang.translate('freeOnly'),
                      value: _bookProvider.showFreeOnly,
                      onChanged: (value) =>
                          _bookProvider.setShowFreeOnly(value),
                    ),
                    _buildSwitchTile(
                      context: context,
                      title: lang.translate('audioOnly'),
                      value: _bookProvider.showAudioOnly,
                      onChanged: (value) =>
                          _bookProvider.setShowAudioOnly(value),
                    ),
                    const Divider(),
                    Text(
                      lang.translate('tags'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._bookProvider.tags.map((tag) {
                      return _buildTagChip(
                        context: context,
                        tag: tag,
                        provider: _bookProvider,
                      );
                    }),
                    const Divider(),
                    Text(
                      lang.translate('categories'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._bookProvider.categories.map((category) {
                      return _buildCategoryCheckbox(
                        context: context,
                        category: category,
                        provider: _bookProvider,
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    // Reset all filters using the central reset method
                    _bookProvider.resetAllFilters();
                  },
                  child: Text(lang.translate('resetFilters')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildCategoryCheckbox({
    required BuildContext context,
    required dynamic category,
    required BookProvider provider,
  }) {
    return CheckboxListTile(
      title: Text(category.name),
      value: provider.selectedCategories.contains(category.id),
      onChanged: (bool? value) {
        if (value != null) {
          provider.toggleCategory(category.id);
        }
      },
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTagChip({
    required BuildContext context,
    required Tag tag,
    required BookProvider provider,
  }) {
    final isSelected = provider.selectedTagIds.contains(tag.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilterChip(
        label: Text(tag.name),
        selected: isSelected,
        onSelected: (bool selected) {
          final tagIds = List<String>.from(provider.selectedTagIds);
          if (selected) {
            tagIds.add(tag.id);
          } else {
            tagIds.remove(tag.id);
          }
          provider.updateTagsFilter(tagIds);
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        ),
        elevation: 2,
        pressElevation: 4,
      ),
    );
  }
}
