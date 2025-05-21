import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/book_search_delegate.dart';
import 'book_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  bool _showSearchBar = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showSearchBar) setState(() => _showSearchBar = false);
    }
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_showSearchBar) setState(() => _showSearchBar = true);
    }
  }

  Future<void> _loadData() async {
    try {
      await Provider.of<BookProvider>(context, listen: false).fetchCategories();
    } catch (e) {
      // Error handling is done in BookProvider
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookProvider, LanguageProvider>(
      builder: (context, bookProvider, langProvider, _) {
        return Scaffold(
          drawer: const AppDrawer(),
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Custom App Bar
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  expandedHeight: 180.0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    centerTitle: true,
                    title: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Grantha Katha',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    background: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context)
                                    .secondaryHeaderColor
                                    .withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Opacity(
                            opacity: 0.15,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    opacity: _showSearchBar ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shadowColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            showSearch(
                              context: context,
                              delegate: BookSearchDelegate(
                                bookProvider,
                                langProvider,
                              ),
                            );
                          },
                          leading: Icon(
                            Icons.search,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            langProvider.translate('search'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          trailing: Icon(
                            Icons.mic,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Categories Header
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          langProvider.translate('categories'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/categories');
                          },
                          child: Text(langProvider.translate('viewAll')),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories Grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= bookProvider.categories.length)
                          return null;
                        final category = bookProvider.categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookListScreen(
                                  title: category.name,
                                  books: bookProvider
                                      .getFilteredBooks()
                                      .where((book) =>
                                          book.shopCategorie == category.id)
                                      .toList(),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: category.image.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        'https://granthakatha.com/attachments/shop_images/${category.image}',
                                      ),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.4),
                                        BlendMode.darken,
                                      ),
                                    )
                                  : null,
                              gradient: category.image.isEmpty
                                  ? LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.8),
                                      ],
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                category.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: bookProvider.categories.length,
                    ),
                  ),
                ),

                // Recently Added Books Section
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              langProvider.translate('recentlyAdded'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookListScreen(
                                      title: langProvider
                                          .translate('recentlyAdded'),
                                      books: bookProvider.getFilteredBooks(),
                                    ),
                                  ),
                                );
                              },
                              child: Text(langProvider.translate('viewAll')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: bookProvider.getFilteredBooks().length,
                            itemBuilder: (context, index) {
                              final book =
                                  bookProvider.getFilteredBooks()[index];
                              return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 16),
                                child: BookCard(
                                  book: book,
                                  isInLibrary: false,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Padding
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          ),
        );
      },
    );
  }
}
