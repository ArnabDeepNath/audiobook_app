import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../providers/book_provider.dart';
import 'package:provider/provider.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          final provider = Provider.of<BookProvider>(context, listen: false);
          provider.toggleCategory(category.id);
        },
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade400,
                Colors.indigo.shade700,
              ],
            ),
          ),
          child: Stack(
            children: [
              if (category.image.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://granthakatha.com/pdoapp/public/storage/images/${category.image}',
                      fit: BoxFit.cover,
                      color: Colors.black26,
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                ),
              Center(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                ),
              ),
              Consumer<BookProvider>(
                builder: (context, provider, child) {
                  final isSelected =
                      provider.selectedCategories.contains(category.id);
                  if (!isSelected) return const SizedBox();
                  return Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
