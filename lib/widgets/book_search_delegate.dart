import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/book_card.dart';

class BookSearchDelegate extends SearchDelegate {
  final BookProvider bookProvider;
  final LanguageProvider langProvider;

  BookSearchDelegate(this.bookProvider, this.langProvider);

  @override
  String get searchFieldLabel => langProvider.translate('search');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text(langProvider.translate('search')),
      );
    }

    bookProvider.updateSearchQuery(query);
    final books = bookProvider.getFilteredBooks();

    if (books.isEmpty) {
      return Center(
        child: Text(langProvider.translate('noBooks')),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return BookCard(
          book: books[index],
          isInLibrary: false,
        );
      },
    );
  }
}
