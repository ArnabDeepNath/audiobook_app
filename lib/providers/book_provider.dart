import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../models/tag_model.dart';

class BookProvider with ChangeNotifier {
  // Core data lists
  List<Book> _books = [];
  List<Book> _libraryBooks = [];
  List<Category> _categories = [];
  Map<String, List<Book>> _booksByCategory = {};

  // Auth and user state
  String? _token;
  String _currentLanguage = 'as'; // default to Assamese
  User? _user;

  // Helper method for headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': _token!,
      };

  // Filtering state
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  Set<String> _selectedTagIds = {}; // Changed to Set for better performance
  bool _showFreeOnly = false;
  bool _showAudioOnly = false;
  String? _categoryFilter;

  // API URLs
  final String mediaBaseUrl = 'https://granthakatha.com';
  final String mediaApiUrl = 'https://granthakatha.com/pdoapp/public';
  final String localApiUrl = 'https://granthakatha.com/pdoapp/public';
  // Constants for filtering
  final Map<String, String> _tagFilters = {
    'students': '11', // Students Hub tag ID
  };
  final Map<String, String> _categoryFilters = {
    'poems': '7', // Poems category ID
  };

  // Public getters
  bool get isAuthenticated => _token != null;
  List<Book> get books {
    // Filter books by current language and sort
    List<Book> languageFilteredBooks =
        _books.where((book) => book.languageCode == _currentLanguage).toList();
    languageFilteredBooks.sort((a, b) => a.abbr.compareTo(b.abbr));
    return List.unmodifiable(languageFilteredBooks);
  }

  List<Book> get userLibrary {
    // Filter library books by current language and sort
    List<Book> languageFilteredLibrary = _libraryBooks
        .where((book) => book.languageCode == _currentLanguage)
        .toList();
    languageFilteredLibrary.sort((a, b) => a.abbr.compareTo(b.abbr));
    return List.unmodifiable(languageFilteredLibrary);
  }

  List<Category> get categories => List.unmodifiable(_categories);
  List<String> get selectedCategories => List.unmodifiable(_selectedCategories);
  List<Tag> get tags => List.unmodifiable(_tags);
  bool get showFreeOnly => _showFreeOnly;
  bool get showAudioOnly => _showAudioOnly;
  String? get categoryFilter => _categoryFilter;
  User? get user => _user;
  String get searchQuery => _searchQuery;
  String get currentLanguage => _currentLanguage;
  List<String> get selectedTagIds =>
      List.unmodifiable(_selectedTagIds.toList());

  // Return filtered categories based on current filter
  List<Category> get filteredCategories {
    if (_categories.isEmpty) return [];
    if (_categoryFilter == null) return List.unmodifiable(_categories);

    print('Filtering categories by: ${_categoryFilter?.toLowerCase()}');
    switch (_categoryFilter?.toLowerCase()) {
      case 'students_hub':
        final studentBooks = _filterBooksByTagId(_tagFilters['students']!);
        final studentCategoryIds =
            studentBooks.map((b) => b.shopCategorie).toSet();
        return _categories
            .where((c) => studentCategoryIds.contains(c.id))
            .toList();
      case 'poems':
        return _categories
            .where((c) => c.id == _categoryFilters['poems'])
            .toList();
      case 'ebooks':
        final pdfBooks = _filterBooksByFileType('pdf');
        final pdfCategoryIds = pdfBooks.map((b) => b.shopCategorie).toSet();
        return _categories.where((c) => pdfCategoryIds.contains(c.id)).toList();
      case 'audiobooks':
        final audioBooks = _filterBooksByFileType('audio');
        final audioCategoryIds = audioBooks.map((b) => b.shopCategorie).toSet();
        return _categories
            .where((c) => audioCategoryIds.contains(c.id))
            .toList();
      default:
        return List.unmodifiable(_categories);
    }
  }

  // Initialize data
  Future<void> initializeData() async {
    await fetchCategories();
    await fetchBooks(); // Load books for the current language
  }

  // Improved book fetching with proper caching
  Future<List<Book>> getCategoryBooks(String categoryId) async {
    // Return cached books if available and not empty
    if (_booksByCategory.containsKey(categoryId) &&
        (_booksByCategory[categoryId]?.isNotEmpty ?? false)) {
      return List.unmodifiable(_booksByCategory[categoryId] ?? []);
    }

    // If not in cache or empty, fetch from server
    try {
      final response = await http.get(
        Uri.parse(
            '$localApiUrl/get_books_by_category.php?category_id=$categoryId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: Raw API data for category $categoryId (first 2 books):');
        if (data.isNotEmpty) {
          for (int i = 0; i < (data.length > 2 ? 2 : data.length); i++) {
            final bookData = data[i];
            print(
                'DEBUG: Book $i - abbr: "${bookData['abbr']}", language: "${bookData['language']}", title: "${bookData['title']}"');
          }
        }

        final books = data.map((json) => Book.fromJson(json)).toList();
        print('DEBUG: Parsed books for category $categoryId: ${books.length}');
        for (int i = 0; i < (books.length > 2 ? 2 : books.length); i++) {
          final book = books[i];
          print(
              'DEBUG: Parsed Book $i - abbr: "${book.abbr}", languageCode: "${book.languageCode}", title: "${book.title}"');
        }

        _booksByCategory[categoryId] = books;

        // Update main books list while preserving other books
        final existingBooks = Set.from(_books);
        final newBooks = books.where((book) => !existingBooks.contains(book));
        _books = [..._books, ...newBooks];

        notifyListeners();
        return List.unmodifiable(books);
      } else {
        throw Exception('Failed to fetch books for category $categoryId');
      }
    } catch (e) {
      print('Error fetching books for category $categoryId: $e');
      return const [];
    }
  }

  // Improved category fetching
  Future<void> fetchCategories() async {
    if (!isAuthenticated) return;

    try {
      final response = await http.get(
        Uri.parse('$localApiUrl/get_categories.php'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _categories = data.map((json) => Category.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Keep existing categories on error
    }
  }

  // Tag management
  List<Tag> _tags = [];
  bool _isLoading = false;

  // List<Tag> get tags => _tags;
  bool get isLoading => _isLoading;

  Future<void> fetchTags() async {
    if (!isAuthenticated) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$localApiUrl/get_tags.php'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _tags = data.map((json) => Tag.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load tags');
      }
    } catch (e) {
      print('Error fetching tags: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateTagsFilter(List<String> tagIds) {
    _selectedTagIds.clear();
    if (tagIds.isNotEmpty) {
      _selectedTagIds.addAll(tagIds.map((id) => id.trim()));
      _isFiltering = true;
    } else {
      _isFiltering = _selectedCategories.isNotEmpty ||
          _showFreeOnly ||
          _showAudioOnly ||
          _searchQuery.isNotEmpty;
    }
    print('Updated tags filter: ${_selectedTagIds.toString()}');
    notifyListeners();
  }

  void toggleTag(String tagId) {
    final trimmedId = tagId.trim();
    if (_selectedTagIds.contains(trimmedId)) {
      _selectedTagIds.remove(trimmedId);
    } else {
      _selectedTagIds.add(trimmedId);
    }

    // Update _isFiltering based on whether any filters are active
    _isFiltering = _selectedTagIds.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _showFreeOnly ||
        _showAudioOnly ||
        _searchQuery.isNotEmpty;
    print(
        'Toggled tag: $trimmedId, Active tags: ${_selectedTagIds.toString()}');
    notifyListeners();
  }

  void clearSelectedTags() {
    _selectedTagIds.clear();
    _isFiltering =
        _selectedCategories.isNotEmpty || _showFreeOnly || _showAudioOnly;
    notifyListeners();
  }

  // Fetch books for the current language
  Future<void> fetchBooks() async {
    try {
      print('DEBUG: Fetching books for language: $_currentLanguage');

      // Fetch books from the language-specific endpoint
      final response = await http.get(
        Uri.parse('$localApiUrl/get_audiobooks.php?lang=$_currentLanguage'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(
            'DEBUG: Fetched ${data.length} books for language $_currentLanguage');

        if (data.isNotEmpty) {
          // Debug: Print first few books
          for (int i = 0; i < (data.length > 3 ? 3 : data.length); i++) {
            final bookData = data[i];
            print('DEBUG: Book $i - title: "${bookData['title']}"');
          }
        }

        // Parse the books
        final books = data.map((json) {
          // For English books, explicitly set the language code
          if (_currentLanguage == 'en') {
            return Book.fromJson(
                {...json, 'abbr': 'en', 'language': 'English'});
          }
          return Book.fromJson(json);
        }).toList();

        // Replace the books list with the new books
        _books = books;

        // Clear category cache
        _booksByCategory.clear();

        print(
            'DEBUG: Successfully loaded ${_books.length} books for language $_currentLanguage');
        notifyListeners();
      } else {
        throw Exception(
            'Failed to fetch books for language $_currentLanguage: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching books for language $_currentLanguage: $e');
      // Keep existing books on error
    }
  }

  // Fetch books for initial load
  Future<void> fetchAllLanguageBooks() async {
    await fetchBooks(); // Just fetch books for the current language
  }

  // Session management constants
  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getString(_userIdKey);
      final userName = prefs.getString(_userNameKey);
      final userEmail = prefs.getString(_userEmailKey);

      if (token != null &&
          userId != null &&
          userName != null &&
          userEmail != null) {
        _token = token;
        _user = User(
          id: userId,
          name: userName,
          email: userEmail,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error restoring session: $e');
      return false;
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    _token = null;
    _user = null;
    _libraryBooks.clear();
    _books.clear();
    _booksByCategory.clear();
    _selectedCategories.clear();
    _selectedTagIds.clear();
    _categories.clear();
    _isFiltering = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearSession();
  }

  // Authentication methods
  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/login.php'),
        body: json.encode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Login response data: $data');

        if (data['message'] == 'Login successful' && data['user'] != null) {
          final userData = data['user'];
          if (userData['id'] == null ||
              userData['username'] == null ||
              userData['email'] == null) {
            throw Exception('Invalid user data received from server');
          }

          // Use user ID as token if no token is provided
          _token = userData['id'].toString();
          _user = User(
            id: userData['id'].toString(),
            name: userData['username'],
            email: userData['email'],
          );

          // Save to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          await prefs.setString(_userIdKey, _user!.id);
          await prefs.setString(_userNameKey, _user!.name);
          await prefs.setString(_userEmailKey, _user!.email);

          notifyListeners();
          await initializeData(); // Load initial data after login
        } else {
          throw Exception(
              data['message'] ?? 'Login failed: Invalid response structure');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else {
        throw Exception(
            'Login failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during login: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception(e.toString());
    }
  }

  Future<void> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/register.php'),
        body: json.encode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['message'] == 'User registered successfully') {
          // Registration successful, user should now login
          return;
        } else {
          throw Exception(data['message'] ?? 'Registration failed');
        }
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during registration: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Media URLs
  String getBookCoverUrl(Book book) {
    return '$mediaBaseUrl/attachments/shop_images/${book.image}';
  }

  String getMediaUrl(Book book, {String quality = 'medium'}) {
    final baseUrl = '$mediaBaseUrl/${book.filePath}';

    if (book.fileType.toLowerCase() == 'audio') {
      // For audio files, we can request different qualities
      // low: 64kbps, medium: 128kbps, high: 256kbps
      switch (quality) {
        case 'low':
          return '$baseUrl?quality=64';
        case 'high':
          return '$baseUrl?quality=256';
        default: // medium
          return '$baseUrl?quality=128';
      }
    }

    // For PDFs, we can request a compressed version for preview
    if (book.fileType.toLowerCase() == 'pdf') {
      // Request compressed version for initial load
      return '$baseUrl?compressed=true';
    }

    return baseUrl;
  }

  /// Get the size of media file before downloading
  Future<int> getMediaSize(Book book, {String quality = 'medium'}) async {
    try {
      final url = getMediaUrl(book, quality: quality);
      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        return int.parse(response.headers['content-length'] ?? '0');
      }
      return 0;
    } catch (e) {
      print('Error getting media size: $e');
      return 0;
    }
  }

  /// Check if media is already cached
  bool isMediaCached(Book book) {
    // Implementation depends on your caching strategy
    // For example, checking if file exists in app's cache directory
    return false; // TODO: Implement actual cache checking
  }

  // Library management
  Future<void> addToLibrary(Book book) async {
    if (!isAuthenticated) return;

    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/add_to_library.php'),
        body: json.encode({
          'book_id': book.id,
        }),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        if (!_libraryBooks.contains(book)) {
          _libraryBooks.add(book);
          notifyListeners();
        }
      } else {
        throw Exception('Failed to add book to library');
      }
    } catch (e) {
      print('Error adding book to library: $e');
      throw Exception('Failed to add book to library: $e');
    }
  }

  Future<void> removeFromLibrary(Book book) async {
    if (!isAuthenticated) return;

    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/remove_from_library.php'),
        body: json.encode({
          'book_id': book.id,
        }),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        _libraryBooks.removeWhere((b) => b.id == book.id);
        notifyListeners();
      } else {
        throw Exception('Failed to remove book from library');
      }
    } catch (e) {
      print('Error removing book from library: $e');
      throw Exception('Failed to remove book from library: $e');
    }
  }

  // Progress tracking
  Future<void> updateProgress(Book book,
      {int? position, bool? completed}) async {
    if (!isAuthenticated) return;

    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/update_progress.php'),
        body: json.encode({
          'book_id': book.id,
          if (position != null) 'current_position': position,
          if (completed != null) 'completed': completed,
        }),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update progress');
      }
    } catch (e) {
      print('Error updating progress: $e');
      throw Exception('Failed to update progress: $e');
    }
  }

  // Category and book filtering methods
  List<Book> getFilteredBooksByType(String filterType) {
    List<Book> result;
    switch (filterType.toLowerCase()) {
      case 'students_hub':
        result = _filterBooksByTagId(_tagFilters['students']!);
        break;
      case 'poems':
        final poemCategory = _categoryFilters['poems'];
        result = poemCategory != null
            ? _books
                .where((book) =>
                    book.shopCategorie == poemCategory &&
                    book.languageCode == _currentLanguage)
                .toList()
            : [];
        break;
      case 'ebooks':
        result = _filterBooksByFileType('pdf');
        break;
      case 'audiobooks':
        result = _filterBooksByFileType('audio');
        break;
      default:
        result = [];
    }
    // Sort by language abbreviation
    result.sort((a, b) => a.abbr.compareTo(b.abbr));
    return result;
  }

  // Whether we are in a search/filter context
  bool _isFiltering = false;

  void setFilteringMode(bool filtering) {
    _isFiltering = filtering;
    notifyListeners();
  }

  List<Book> getFilteredBooks({bool isFilterView = false}) {
    // Debug: Print current language and book information
    print('DEBUG: Current language: $_currentLanguage');
    print('DEBUG: Total books: ${_books.length}');

    // Always apply language filtering based on current language setting
    List<Book> languageFilteredBooks = _books.where((book) {
      bool matches = book.languageCode == _currentLanguage;
      // Debug: Print first few books' language info
      if (_books.indexOf(book) < 5) {
        print(
            'DEBUG: Book "${book.title}" - abbr: "${book.abbr}", languageCode: "${book.languageCode}", matches: $matches');
      }
      return matches;
    }).toList();

    print('DEBUG: Language filtered books: ${languageFilteredBooks.length}');

    // If we're in home view and no other filters are actively applied, return sorted language-filtered books
    if (!isFilterView && !_isFiltering) {
      languageFilteredBooks.sort((a, b) => a.abbr.compareTo(b.abbr));
      return List.unmodifiable(languageFilteredBooks);
    }

    // Apply additional filters if any are active
    if (_selectedTagIds.isEmpty &&
        _selectedCategories.isEmpty &&
        !_showFreeOnly &&
        !_showAudioOnly &&
        _searchQuery.isEmpty) {
      languageFilteredBooks.sort((a, b) => a.abbr.compareTo(b.abbr));
      return List.unmodifiable(languageFilteredBooks);
    }
    print(
        'Applying filters - Search: "$_searchQuery", Tags: ${_selectedTagIds.toString()}, Categories: $_selectedCategories');
    List<Book> filteredBooks = languageFilteredBooks.where((book) {
      // Search filter - improved to handle null/empty values and author search
      bool matchesSearch = _searchQuery.isEmpty ||
          (book.title.isNotEmpty &&
              book.title.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (book.description.isNotEmpty &&
              book.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase())) ||
          (book.folder.isNotEmpty &&
              book.folder.toLowerCase().contains(_searchQuery.toLowerCase()));

      // Category filter
      bool matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.contains(book.shopCategorie); // Tag filter
      bool matchesTags = _selectedTagIds.isEmpty ||
          book.tagIds
              .split(',')
              .map((e) => e.trim())
              .any((tagId) => _selectedTagIds.contains(tagId));

      // Type filters
      bool matchesFree = !_showFreeOnly || book.isFree == 'yes';
      bool matchesType = !_showAudioOnly || book.fileType == 'audio';

      return matchesSearch &&
          matchesCategory &&
          matchesTags &&
          matchesFree &&
          matchesType;
    }).toList();

    // Sort by language abbreviation before returning
    filteredBooks.sort((a, b) => a.abbr.compareTo(b.abbr));
    return filteredBooks;
  }

  // State management methods
  void updateSearchQuery(String query) {
    _searchQuery = query.trim(); // Trim whitespace
    // Update filtering mode based on whether search query is active
    _isFiltering = _searchQuery.isNotEmpty ||
        _selectedTagIds.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _showFreeOnly ||
        _showAudioOnly;
    notifyListeners();
  }

  void toggleCategory(String categoryId) {
    if (_selectedCategories.contains(categoryId)) {
      _selectedCategories.remove(categoryId);
    } else {
      _selectedCategories.add(categoryId);
    }
    // Update filtering mode based on active filters
    _isFiltering = _selectedTagIds.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _showFreeOnly ||
        _showAudioOnly;
    notifyListeners();
  }

  void clearSelectedCategories() {
    _selectedCategories.clear();
    // Update filtering mode based on remaining active filters
    _isFiltering =
        _selectedTagIds.isNotEmpty || _showFreeOnly || _showAudioOnly;
    notifyListeners();
  }

  void setShowFreeOnly(bool value) {
    _showFreeOnly = value;
    // Update filtering mode based on active filters
    _isFiltering = _selectedTagIds.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _showFreeOnly ||
        _showAudioOnly;
    notifyListeners();
  }

  void setShowAudioOnly(bool value) {
    _showAudioOnly = value;
    // Update filtering mode based on active filters
    _isFiltering = _selectedTagIds.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _showFreeOnly ||
        _showAudioOnly;
    notifyListeners();
  }

  void resetAllFilters() {
    if (!_isFiltering) return; // Don't reset if we're not filtering
    _showFreeOnly = false;
    _showAudioOnly = false;
    _selectedCategories.clear();
    _selectedTagIds.clear(); // Clear the Set of selected tags
    _categoryFilter = null;
    _searchQuery = '';
    _isFiltering = false;
    notifyListeners();
  }

  void setCategoryFilter(String? filter) {
    _categoryFilter = filter;
    // Enable filtering mode if a filter is being set
    if (filter != null) {
      _isFiltering = true;
    }
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    print('DEBUG: Setting language from "$_currentLanguage" to "$language"');
    _currentLanguage = language;

    // Clear any active filtering when switching languages
    _isFiltering = false;
    _selectedCategories.clear();
    _selectedTagIds.clear();
    _showFreeOnly = false;
    _showAudioOnly = false;
    _searchQuery = '';
    _categoryFilter = null;

    // Fetch books for the newly selected language and wait for completion
    try {
      await fetchBooks();
      print('DEBUG: Books successfully fetched for language $_currentLanguage');
    } catch (e) {
      print('ERROR: Failed to fetch books for language $_currentLanguage: $e');
    }

    notifyListeners();
  }

  // Session initialization
  Future<bool> initSession() async {
    try {
      final hasSession = await restoreSession();
      if (hasSession) {
        await initializeData();
      }
      return hasSession;
    } catch (e) {
      print('Error initializing session: $e');
      return false;
    }
  }

  // Get user profile info
  Map<String, dynamic> getUserProfile() {
    if (!isAuthenticated) return {};

    return {
      'id': _user!.id,
      'name': _user!.name,
      'email': _user!.email,
      'totalBooks': _libraryBooks.length,
      'audiobooks': _libraryBooks
          .where((book) => book.fileType.toLowerCase() == 'audio')
          .length,
      'ebooks': _libraryBooks
          .where((book) => book.fileType.toLowerCase() == 'pdf')
          .length,
    };
  }

  // Get user library stats
  Map<String, int> getLibraryStats() {
    if (!isAuthenticated) return {};

    return {
      'total': _libraryBooks.length,
      'audiobooks': _libraryBooks
          .where((book) => book.fileType.toLowerCase() == 'audio')
          .length,
      'ebooks': _libraryBooks
          .where((book) => book.fileType.toLowerCase() == 'pdf')
          .length,
      'completed': _libraryBooks.where((book) => book.completed).length,
      'inProgress': _libraryBooks
          .where((book) => !book.completed && book.currentPosition != null)
          .length,
      'notStarted': _libraryBooks
          .where((book) => !book.completed && book.currentPosition == null)
          .length,
    };
  }

  // Update user profile
  Future<void> updateUserProfile(String name, String email) async {
    if (!isAuthenticated || _user == null) return;

    try {
      final response = await http.post(
        Uri.parse('$mediaApiUrl/update_profile.php'),
        body: json.encode({
          'name': name,
          'email': email,
        }),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Create new user object with updated data
        _user = User(
          id: _user!.id,
          name: name,
          email: email,
        );

        // Update shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userNameKey, name);
        await prefs.setString(_userEmailKey, email);

        notifyListeners();
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Helper methods
  List<Book> _filterBooksByTagId(String tagId) {
    List<Book> result = _books.where((book) {
      final tagIds = book.tagIds.split(',').map((e) => e.trim()).toList();
      // Apply both tag filtering and language filtering
      return tagIds.contains(tagId) && book.languageCode == _currentLanguage;
    }).toList();
    result.sort((a, b) => a.abbr.compareTo(b.abbr));
    return result;
  }

  List<Book> _filterBooksByFileType(String fileType) {
    List<Book> result = _books
        .where((book) =>
            book.fileType.toLowerCase() == fileType.toLowerCase() &&
            book.languageCode == _currentLanguage)
        .toList();
    result.sort((a, b) => a.abbr.compareTo(b.abbr));
    return result;
  }

  // Get books by language abbreviation
  List<Book> getBooksByLanguage(String languageAbbr) {
    print('DEBUG: Getting books for language: ${languageAbbr.toLowerCase()}');
    List<Book> result = _books
        .where((book) => book.languageCode == languageAbbr.toLowerCase())
        .toList();
    print(
        'DEBUG: Found ${result.length} books for ${languageAbbr.toLowerCase()}');
    // Print first few books
    if (result.isNotEmpty) {
      for (int i = 0; i < (result.length > 3 ? 3 : result.length); i++) {
        final book = result[i];
        print(
            'DEBUG: ${languageAbbr.toLowerCase()} Book $i - "${book.title}", abbr: "${book.abbr}", languageCode: "${book.languageCode}"');
      }
    }
    result.sort((a, b) => a.abbr.compareTo(b.abbr));
    return result;
  }

  // Get Assamese books
  List<Book> get assameseBooks {
    final books = getBooksByLanguage('as');
    print('DEBUG: Assamese books count: ${books.length}');
    return books;
  }

  // Get English books
  List<Book> get englishBooks {
    final books = getBooksByLanguage('en');
    print('DEBUG: English books count: ${books.length}');
    return books;
  }

  bool _containsAssamese(String text) {
    RegExp assameseRegex = RegExp(r'[\u0980-\u09FF]');
    return assameseRegex.hasMatch(text);
  }

  // Refresh books for current language
  Future<void> refreshCurrentLanguageBooks() async {
    print('DEBUG: Refreshing books for current language: $_currentLanguage');
    await fetchBooks();
  }

  // Get the total count of books for a specific language
  int getBookCountForLanguage(String languageCode) {
    return _books.where((book) => book.languageCode == languageCode).length;
  }
}
