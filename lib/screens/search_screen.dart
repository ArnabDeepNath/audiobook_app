import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../widgets/book_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _selectedTags = [];
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadTags();
    // Enable filtering mode when search screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).setFilteringMode(true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    // Reset filtering mode and search query when leaving search screen
    Provider.of<BookProvider>(context, listen: false).setFilteringMode(false);
    Provider.of<BookProvider>(context, listen: false).updateSearchQuery('');
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<BookProvider>(context, listen: false).fetchTags();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTags.contains(tagId)) {
        _selectedTags.remove(tagId);
      } else {
        _selectedTags.add(tagId);
      }
      Provider.of<BookProvider>(context, listen: false)
          .updateTagsFilter(_selectedTags);
    });
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
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search books, authors...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                    Provider.of<BookProvider>(context, listen: false)
                        .updateSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {}); // Trigger rebuild for suffixIcon visibility
          Provider.of<BookProvider>(context, listen: false)
              .updateSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildTagFilters() {
    final provider = Provider.of<BookProvider>(context);
    final tags = provider.tags;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = _selectedTags.contains(tag.id);

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              onSelected: (_) => _toggleTag(tag.id),
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
              elevation: 2,
              pressElevation: 4,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList() {
    return Consumer<BookProvider>(
      builder: (context, provider, child) {
        final books = provider.getFilteredBooks(isFilterView: true);

        // Debug logging for release version troubleshooting
        print(
            'DEBUG Search: Query="${provider.searchQuery}", Books found: ${books.length}, Total books: ${provider.books.length}');

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.books.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Loading books...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No books found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                if (provider.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Try different keywords or filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            return BookCard(
              book: books[index],
              isInLibrary: false,
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Provider.of<BookProvider>(context)
                        .tags
                        .map((tag) => FilterChip(
                              label: Text(tag.name),
                              selected: _selectedTags.contains(tag.id),
                              onSelected: (_) => _toggleTag(tag.id),
                              backgroundColor: Colors.white,
                              selectedColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                              checkmarkColor: Theme.of(context).primaryColor,
                              labelStyle: TextStyle(
                                color: _selectedTags.contains(tag.id)
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[700],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedTags.clear();
                    Provider.of<BookProvider>(context, listen: false)
                        .updateTagsFilter([]);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Clear All Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildFilterDrawer(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTagFilters(),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }
}
