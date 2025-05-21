import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';

class FilterDrawer extends StatelessWidget {
  const FilterDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Drawer(
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
                    value: bookProvider.showFreeOnly,
                    onChanged: (value) => bookProvider.setShowFreeOnly(value),
                  ),
                  _buildSwitchTile(
                    context: context,
                    title: lang.translate('audioOnly'),
                    value: bookProvider.showAudioOnly,
                    onChanged: (value) => bookProvider.setShowAudioOnly(value),
                  ),
                  const Divider(),
                  Text(
                    lang.translate('categories'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...bookProvider.categories.map((category) {
                    return _buildCategoryCheckbox(
                      context: context,
                      category: category,
                      provider: bookProvider,
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  // Reset all filters
                  bookProvider.setShowFreeOnly(false);
                  bookProvider.setShowAudioOnly(false);
                  bookProvider.clearSelectedCategories();
                },
                child: Text(lang.translate('resetFilters')),
              ),
            ),
          ],
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
}
