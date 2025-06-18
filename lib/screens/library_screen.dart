import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/book_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('library')),
      ),
      body: bookProvider.userLibrary.isEmpty
          ? Center(
              child: Text(
                lang.translate('emptyLibrary'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: bookProvider.userLibrary.length,
              itemBuilder: (context, index) {
                final book = bookProvider.userLibrary[index];
                return BookCard(
                  book: book,
                  isInLibrary: true,
                );
              },
            ),
    );
  }
}
