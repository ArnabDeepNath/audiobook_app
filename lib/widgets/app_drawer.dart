import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../constants/app_branding.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final bookProvider = Provider.of<BookProvider>(context);
    final isAssamese = lang.languageCode == 'as';

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppBranding.appLogoWhite,
                    width: 64,
                    height: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAssamese
                        ? AppBranding.appNameAssamese
                        : AppBranding.appNameEnglish,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(lang.translate('home')),
                  onTap: () {
                    Navigator.pop(context);
                    bookProvider.setFilteringMode(false);
                    bookProvider.resetAllFilters();
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                if (bookProvider.isAuthenticated) ...[
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(lang.translate('profile')),
                    onTap: () {
                      Navigator.pop(context);
                      bookProvider.setFilteringMode(false);
                      bookProvider.resetAllFilters();
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.library_books),
                    title: Text(lang.translate('library')),
                    onTap: () {
                      Navigator.pop(context);
                      bookProvider.setFilteringMode(false);
                      bookProvider.resetAllFilters();
                      Navigator.pushNamed(context, '/library');
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(lang.translate('categories')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/categories');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(lang.translate('language')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String value) async {
                      if (value == 'as') {
                        await bookProvider.setLanguage('as');
                        lang.setLocale(const Locale('as', 'IN'));
                      } else {
                        await bookProvider.setLanguage('en');
                        lang.setLocale(const Locale('en', 'US'));
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'en',
                        child: Text(lang.translate('English')),
                      ),
                      PopupMenuItem<String>(
                        value: 'as',
                        child: Text(lang.translate('Assamese')),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Language Statistics
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('library_stats'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      '${bookProvider.assameseBooks.length}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    Text(
                                      lang.translate('Assamese'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      '${bookProvider.englishBooks.length}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    Text(
                                      lang.translate('English'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(lang.translate('about')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
                if (!bookProvider.isAuthenticated)
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: Text(lang.translate('login')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(lang.translate('logout')),
                    onTap: () {
                      bookProvider.logout();
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
