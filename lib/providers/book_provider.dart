import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book_model.dart';
import '../models/category_model.dart';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  List<Book> _libraryBooks = [];
  List<Category> _categories = [];
  Map<String, List<Book>> _booksByCategory = {};
  String? _token;
  String _currentLanguage = 'as'; // default to Assamese

  // URLs for media files
  final String mediaBaseUrl = 'https://granthakatha.com';
  final String mediaApiUrl = 'https://granthakatha.com/pdoapp/public';

  // URL for categories and tags
  final String localApiUrl = 'https://granthakatha.com/pdoapp/public';

  // Additional properties for filtering
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  bool _showFreeOnly = false;
  bool _showAudioOnly = false;

  // Getters
  List<Book> get books => _books;
  List<Book> get libraryBooks => _libraryBooks;
  List<Category> get categories => filteredCategories;
  Map<String, List<Book>> get booksByCategory => _booksByCategory;
  bool get isAuthenticated => _token != null;

  // Getters for filters
  String get searchQuery => _searchQuery;
  List<String> get selectedCategories => _selectedCategories;
  bool get showFreeOnly => _showFreeOnly;
  bool get showAudioOnly => _showAudioOnly;

  // Language handling
  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
    fetchCategories(); // Refresh data with new language
  }

  // URL helpers
  String getBookCoverUrl(Book book) {
    return '$mediaBaseUrl/attachments/shop_images/${book.image}';
  }

  String getMediaUrl(Book book) {
    final path = book.filePath.replaceFirst('storage/', '');
    return '$mediaBaseUrl/storage/$path';
  }

  // Data fetching methods
  Future<void> fetchCategories() async {
    try {
      final Uri uri = Uri.parse('$localApiUrl/get_categories.php')
          .replace(queryParameters: {'lang': _currentLanguage});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _categories = data.map((json) => Category.fromJson(json)).toList();
        _categories.sort(
            (a, b) => int.parse(a.position).compareTo(int.parse(b.position)));
        notifyListeners();

        // After fetching categories, fetch books for each category
        for (var category in _categories) {
          await fetchBooksByCategory(category.id);
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Failed to load categories');
    }
  }

  Future<void> fetchBooks() async {
    try {
      final response = await http.get(
        Uri.parse('$mediaApiUrl/get_audiobooks.php'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _books = data.map((json) => Book.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error fetching books: $e');
      throw Exception('Failed to load books');
    }
  }

  Future<void> fetchBooksByCategory(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$localApiUrl/get_books_by_category.php?category_id=$categoryId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _booksByCategory[categoryId] =
            data.map((json) => Book.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load books for category $categoryId');
      }
    } catch (e) {
      print('Error fetching books for category $categoryId: $e');
      _booksByCategory[categoryId] = [];
    }
  }

  // Auth methods
  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/auth/login'),
        body: json.encode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        notifyListeners();
        await fetchBooks();
      } else {
        throw Exception('Failed to login');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/auth/register'),
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 201) {
        throw Exception('Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Library methods
  Future<void> fetchLibrary() async {
    if (!isAuthenticated) return;

    try {
      final response = await http.get(
        Uri.parse('$mediaApiUrl/user/library/translations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _libraryBooks = data.map((json) => Book.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load library');
      }
    } catch (e) {
      print('Error fetching library: $e');
      throw Exception('Failed to load library');
    }
  }

  Future<void> updateProgress(int bookId, int position, bool completed) async {
    if (_token == null) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/progress/$bookId'),
        body: json.encode({
          'currentPosition': position,
          'completed': completed,
        }),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchLibrary();
      }
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  void logout() {
    _token = null;
    _libraryBooks = [];
    notifyListeners();
  }

  // Update filter methods
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleCategory(String categoryId) {
    if (_selectedCategories.contains(categoryId)) {
      _selectedCategories.remove(categoryId);
    } else {
      _selectedCategories.add(categoryId);
    }
    notifyListeners();
  }

  void clearSelectedCategories() {
    _selectedCategories.clear();
    notifyListeners();
  }

  void setShowFreeOnly(bool value) {
    _showFreeOnly = value;
    notifyListeners();
  }

  void setShowAudioOnly(bool value) {
    _showAudioOnly = value;
    notifyListeners();
  }

  // Filter categories by language
  List<Category> get filteredCategories {
    return _categories.where((category) {
      return _currentLanguage == 'as'
          ? category.isAssamese
          : !category.isAssamese;
    }).toList();
  }

  // Helper method to detect if text contains Assamese characters
  bool _containsAssamese(String text) {
    // Assamese Unicode range (includes Bengali since they share the same script)
    RegExp assameseRegex = RegExp(r'[\u0980-\u09FF]');
    return assameseRegex.hasMatch(text);
  }

  // Get filtered books with language detection
  List<Book> getFilteredBooks() {
    List<Book> filteredBooks = [];

    // Get all books from categories
    for (var entry in _booksByCategory.entries) {
      filteredBooks.addAll(entry.value.where((book) {
        // Filter by language based on content
        bool matchesLanguage = _currentLanguage == 'as'
            ? _containsAssamese(book.title) ||
                _containsAssamese(book.description)
            : !_containsAssamese(book.title) &&
                !_containsAssamese(book.description);

        // Filter by search query
        bool matchesSearch = _searchQuery.isEmpty ||
            book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            book.description.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filter by category
        bool matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(book.shopCategorie);

        // Filter by free/premium
        bool matchesFree = !_showFreeOnly || book.isFree == 'yes';

        // Filter by file type
        bool matchesType = !_showAudioOnly || book.fileType == 'audio';

        return matchesLanguage &&
            matchesSearch &&
            matchesCategory &&
            matchesFree &&
            matchesType;
      }));
    }

    // Remove duplicates based on book ID
    return filteredBooks.toSet().toList();
  }
}
