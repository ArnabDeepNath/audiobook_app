import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/filter_drawer.dart';
import '../constants/menu_items.dart';
import 'book_list_screen.dart';
import 'media_viewer_screen.dart';
import './search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.fetchCategories();
      await bookProvider.fetchBooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'Search books, authors...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Menu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: quickMenuItems.map((item) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Clear previous selections and enable filtering before navigation
                    final provider =
                        Provider.of<BookProvider>(context, listen: false);
                    provider.resetAllFilters();
                    provider.setFilteringMode(true);
                    provider.setCategoryFilter(item.route.replaceAll('/', ''));
                    Navigator.pushNamed(context, item.route);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book, BookProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaViewerScreen(
              book: book,
              provider: provider,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    provider.getBookCoverUrl(book),
                    fit: BoxFit.cover,
                    width: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          book.fileType.toLowerCase() == 'audio'
                              ? Icons.audiotrack
                              : Icons.book,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSection(String title, List<Book> books, String type,
      [bool isRecent = false]) {
    List<Book> filteredBooks;

    if (isRecent) {
      // For Recently Added, sort by time (most recent first) and take latest books
      filteredBooks = List.from(books);
      filteredBooks
          .sort((a, b) => b.time.compareTo(a.time)); // Reverse sort by time
      filteredBooks = filteredBooks.take(10).toList();
    } else if (type.isEmpty) {
      filteredBooks = books.take(10).toList();
    } else {
      filteredBooks = books
          .where((book) => book.fileType.toLowerCase() == type.toLowerCase())
          .take(10)
          .toList();
    }

    // Sort by language abbreviation (except for Recently Added)
    if (!isRecent) {
      filteredBooks.sort((a, b) => a.abbr.compareTo(b.abbr));
    }

    if (filteredBooks.isEmpty) return const SizedBox.shrink();
    final bookProvider = Provider.of<BookProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // Enable filtering mode and set type filter before navigation
                  bookProvider.setFilteringMode(true);
                  bookProvider.setShowAudioOnly(type == 'audio');
                  List<Book> booksToPass;

                  if (title == 'Recently Added') {
                    // For Recently Added: sort by time (most recent first)
                    booksToPass = List.from(books);
                    booksToPass.sort((a, b) => b.time.compareTo(a.time));
                  } else if (type.isEmpty) {
                    booksToPass = books;
                  } else {
                    booksToPass = books
                        .where((book) =>
                            book.fileType.toLowerCase() == type.toLowerCase())
                        .toList();
                  }

                  // Sort books before passing to BookListScreen (except for Recently Added)
                  if (title != 'Recently Added') {
                    booksToPass.sort((a, b) => a.abbr.compareTo(b.abbr));
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookListScreen(
                        title: title,
                        books: booksToPass,
                      ),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) => _buildBookCard(
                filteredBooks[index],
                bookProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories() {
    final categories = Provider.of<BookProvider>(context).categories;
    final topCategories = categories.take(6).toList();

    if (topCategories.isEmpty) return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: topCategories.map((category) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    List<Book> categoryBooks =
                        Provider.of<BookProvider>(context, listen: false)
                            .books
                            .where((book) => book.shopCategorie == category.id)
                            .toList();
                    // Sort books by abbreviation
                    categoryBooks.sort((a, b) => a.abbr.compareTo(b.abbr));

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookListScreen(
                          title: category.name,
                          books: categoryBooks,
                        ),
                      ),
                    );
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        category.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Handler for when filter drawer opens
  void _onEndDrawerChanged(bool isOpen) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.setFilteringMode(isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    // Clear category filters when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookProvider.setCategoryFilter(null);
      bookProvider.setFilteringMode(false);
    });

    final books = bookProvider.getFilteredBooks();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/images/logo_transparent.png',
          height: 40,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: AppDrawer(),
      endDrawer: FilterDrawer(
        onFilterStateChanged: _onEndDrawerChanged,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          controller: _scrollController,
          children: [
            _buildSearchBar(),
            _buildQuickMenu(),
            _buildTopCategories(),
            _buildBookSection('E-Books', books, 'pdf'),
            _buildBookSection('Audiobooks', books, 'audio'),
            _buildBookSection('Recently Added', books, '', true),
          ],
        ),
      ),
    );
  }
}
