import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:grantha_katha/providers/book_provider.dart';
import 'package:grantha_katha/providers/language_provider.dart';
import 'package:grantha_katha/screens/home_screen.dart';
import 'package:grantha_katha/screens/auth/login_screen.dart';
import 'package:grantha_katha/screens/auth/register_screen.dart';
import 'package:grantha_katha/screens/categories_screen.dart';
import 'package:grantha_katha/screens/splash_screen.dart';
import 'package:grantha_katha/screens/library_screen.dart';
import 'package:grantha_katha/screens/profile_screen.dart';
import 'package:grantha_katha/screens/privacy_policy_screen.dart';
import 'package:grantha_katha/screens/terms_screen.dart';
import 'package:grantha_katha/screens/about_screen.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Handle Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.toString()}');
    };

    runApp(MyApp());
  }, (Object error, StackTrace stack) {
    debugPrint('Caught error: $error');
    debugPrint('Stack trace: $stack');
  });
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
            debugShowCheckedModeBanner: false,
            title: 'Grantha Katha',
            locale: langProvider.currentLocale,
            theme: ThemeData(
              primarySwatch: Colors.deepPurple,
              secondaryHeaderColor: Colors.orange,
              scaffoldBackgroundColor: Colors.grey[50],
              appBarTheme: AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Color(0xFF6750A4), // Match logo purple
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
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/home': (context) => HomeScreen(),
              '/categories': (context) => const CategoriesScreen(),
              '/library': (context) => const LibraryScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/privacy-policy': (context) => const PrivacyPolicyScreen(),
              '/terms': (context) => const TermsScreen(),
              '/about': (context) => const AboutScreen(),
              '/kids-hub': (context) =>
                  const CategoriesScreen(categoryFilter: 'kids_hub'),
              '/students-hub': (context) =>
                  const CategoriesScreen(categoryFilter: 'students_hub'),
              '/ebooks': (context) =>
                  const CategoriesScreen(categoryFilter: 'ebooks'),
              '/audiobooks': (context) =>
                  const CategoriesScreen(categoryFilter: 'audiobooks'),
              '/poems': (context) =>
                  const CategoriesScreen(categoryFilter: 'poems'),
            },
          );
        },
      ),
    );
  }
}
