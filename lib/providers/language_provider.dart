import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('as', 'IN'); // Default to Assamese

  Locale get currentLocale => _currentLocale;

  void setLocale(Locale locale) {
    if (!['en', 'as'].contains(locale.languageCode)) return;
    _currentLocale = locale;
    notifyListeners();
  }

  String get languageCode => _currentLocale.languageCode;

  // Translations map
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Grantha Katha',
      'home': 'Home',
      'library': 'My Library',
      'allBooks': 'All Books',
      'categories': 'Categories',
      'settings': 'Settings',
      'search': 'Search books...',
      'filter': 'Filter',
      'language': 'Language',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'profile': 'Profile',
      'free': 'FREE',
      'premium': 'Premium',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'noBooks': 'No books found',
      'noBookmarks': 'No bookmarks yet',
    },
    'as': {
      'appTitle': 'অডিঅ\'বুক স্টোৰ',
      'home': 'মূল পৃষ্ঠা',
      'library': 'মোৰ লাইব্ৰেৰী',
      'allBooks': 'সকলো কিতাপ',
      'categories': 'শ্ৰেণীসমূহ',
      'settings': 'ছেটিংছ',
      'search': 'কিতাপ বিচাৰক...',
      'filter': 'ফিল্টাৰ',
      'language': 'ভাষা',
      'login': 'লগ ইন',
      'register': 'পঞ্জীয়ন',
      'logout': 'লগ আউট',
      'profile': 'প্ৰ\'ফাইল',
      'free': 'বিনামূলীয়া',
      'premium': 'প্ৰিমিয়াম',
      'loading': 'ল\'ড হৈ আছে...',
      'error': 'ত্ৰুটি',
      'retry': 'পুনৰ চেষ্টা কৰক',
      'noBooks': 'কোনো কিতাপ পোৱা নগ\'ল',
      'noBookmarks': 'এতিয়ালৈকে কোনো বুকমাৰ্ক নাই',
    },
  };

  String translate(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}
