import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final bookProvider = Provider.of<BookProvider>(context);

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
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('appTitle'),
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
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(lang.translate('home')),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: Text(lang.translate('library')),
            onTap: () {
              Navigator.pop(context);
              if (bookProvider.isAuthenticated) {
                Navigator.pushNamed(context, '/library');
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
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
              onSelected: (String value) {
                if (value == 'as') {
                  bookProvider.setLanguage('as');
                  lang.setLocale(const Locale('as', 'IN'));
                } else {
                  bookProvider.setLanguage('en');
                  lang.setLocale(const Locale('en', 'US'));
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
          const Spacer(),
          const Divider(),
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
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
