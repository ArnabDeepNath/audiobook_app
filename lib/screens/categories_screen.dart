import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../models/category_model.dart';
import 'book_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('categories')),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: bookProvider.categories.length,
        itemBuilder: (context, index) {
          Category category = bookProvider.categories[index];
          return _buildCategoryCard(context, category, bookProvider);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Category category,
    BookProvider provider,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          provider.toggleCategory(category.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookListScreen(
                title: category.name,
                books: provider
                    .getFilteredBooks()
                    .where(
                      (book) => book.shopCategorie == category.id,
                    )
                    .toList(),
              ),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (category.image.isNotEmpty)
              Image.network(
                'https://granthakatha.com/attachments/shop_images/${category.image}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Category Name
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black45,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
