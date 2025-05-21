import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../widgets/book_card.dart';

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
    if (_searchQuery.isEmpty) return widget.books;
    return widget.books
        .where((book) =>
            book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            book.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
