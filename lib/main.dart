import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audiobook_app/providers/book_provider.dart';
import 'package:audiobook_app/providers/language_provider.dart';
import 'package:audiobook_app/screens/home_screen.dart';
import 'package:audiobook_app/screens/auth/login_screen.dart';
import 'package:audiobook_app/screens/auth/register_screen.dart';
import 'package:audiobook_app/screens/categories_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, child) {
          return MaterialApp(
            title: 'Grantha Katha',
            locale: langProvider.currentLocale,
            theme: ThemeData(
              primarySwatch: Colors.teal,
              secondaryHeaderColor: Colors.orange,
              scaffoldBackgroundColor: Colors.grey[50],
              appBarTheme: AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Colors.teal,
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            initialRoute: '/home',
            routes: {
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/home': (context) => HomeScreen(),
              '/categories': (context) => const CategoriesScreen(),
            },
          );
        },
      ),
    );
  }
}
