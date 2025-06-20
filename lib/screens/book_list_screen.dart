import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../widgets/book_card.dart';
import '../providers/book_provider.dart';

class BookListScreen extends StatefulWidget {
  final String title;
  final List<Book> books;

  const BookListScreen({
    Key? key,
    required this.title,
    required this.books,
  }) : super(key: key);

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Book> get _filteredBooks {
    List<Book> filtered;
    if (_searchQuery.isEmpty) {
      filtered = widget.books;
    } else {
      filtered = widget.books
          .where((book) =>
              book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              book.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Only sort by language abbreviation if not "Recently Added"
    if (widget.title != 'Recently Added') {
      filtered.sort((a, b) => a.abbr.compareTo(b.abbr));
    }
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Reset filters when leaving the screen
    Provider.of<BookProvider>(context, listen: false).setFilteringMode(false);
    Provider.of<BookProvider>(context, listen: false).resetAllFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Book grid
          Expanded(
            child: _filteredBooks.isEmpty
                ? const Center(
                    child: Text('No books found'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      return BookCard(
                        book: _filteredBooks[index],
                        isInLibrary: false,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
