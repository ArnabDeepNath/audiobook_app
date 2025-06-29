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
      'library_stats': 'Library Statistics',
      'English': 'English',
      'Assamese': 'Assamese',
      'termsTitle': "Terms and Condiiton",
      'about': "About Us",
      'terms': "Terms and Condiitons",
      'privacyPolicy': "Privacy Policy",
      'accountSettings': "Account Settings",
      'deleteAccount': "Delete Account",
      'deleteAccountConfirmation':
          "You will be redirected to a web page where you can delete your account. Are you sure you want to continue?",
      'delete': "Delete",
      'cancel': "Cancel"
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
      'library_stats': 'লাইব্ৰেৰী পৰিসংখ্যা',
      'English': 'ইংৰাজী',
      'Assamese': 'অসমীয়া',
      'termsTitle': 'চৰ্তাৱলী',
      'about': 'আমাৰ বিষয়ে',
      'terms': "চৰ্তাৱলী",
      'privacyPolicy': "গোপনীয়তা নীতি",
      'accountSettings': "একাউণ্ট ছেটিংছ",
      'deleteAccount': "একাউণ্ট বিলোপ কৰক",
      'deleteAccountConfirmation':
          "আপুনি আপোনাৰ একাউণ্ট বিলোপ কৰিব পৰা এটা ৱেব পৃষ্ঠালৈ পুনঃনিৰ্দেশিত হ'ব। আপুনি অব্যাহত ৰাখিব বিচাৰে নে?",
      'delete': "বিলোপ কৰক",
      'cancel': "বাতিল কৰক"
    },
  };

  String translate(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}
