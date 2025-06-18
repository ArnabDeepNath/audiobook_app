import 'package:flutter_test/flutter_test.dart';
import 'package:audiobook_app/providers/book_provider.dart';
import 'package:audiobook_app/models/book_model.dart';

void main() {
  group('Language Filtering Tests', () {
    late BookProvider bookProvider;

    setUp(() {
      bookProvider = BookProvider();
    });

    test('Should filter books by language correctly', () {
      // Create test books with different languages
      final testBooks = [
        Book(
          id: '1',
          title: 'English Book 1',
          description: 'An English book',
          folder: 'folder1',
          image: 'image1.jpg',
          fileType: 'pdf',
          filePath: 'path1',
          shopCategorie: 'cat1',
          isFree: 'yes',
          abbr: 'en', // English language code
          price: '0',
          userId: 'user1',
          tagIds: '',
        ),
        Book(
          id: '2',
          title: 'অসমীয়া কিতাপ ১',
          description: 'এখন অসমীয়া কিতাপ',
          folder: 'folder2',
          image: 'image2.jpg',
          fileType: 'audio',
          filePath: 'path2',
          shopCategorie: 'cat2',
          isFree: 'no',
          abbr: 'as', // Assamese language code
          price: '10',
          userId: 'user2',
          tagIds: '',
        ),
        Book(
          id: '3',
          title: 'English Book 2',
          description: 'Another English book',
          folder: 'folder3',
          image: 'image3.jpg',
          fileType: 'audio',
          filePath: 'path3',
          shopCategorie: 'cat1',
          isFree: 'yes',
          abbr: 'en', // English language code
          price: '0',
          userId: 'user3',
          tagIds: '',
        ),
      ];

      // Add test books to provider
      // Note: This would require exposing a test method in BookProvider
      // or mocking the data source

      // Test English language filtering
      bookProvider.setLanguage('en');
      final englishBooks = bookProvider.englishBooks;

      expect(englishBooks.length, 2);
      expect(englishBooks.every((book) => book.languageCode == 'en'), true);

      // Test Assamese language filtering
      bookProvider.setLanguage('as');
      final assameseBooks = bookProvider.assameseBooks;

      expect(assameseBooks.length, 1);
      expect(assameseBooks.every((book) => book.languageCode == 'as'), true);
    });

    test('Should return correct language code from book model', () {
      final englishBook = Book(
        id: '1',
        title: 'Test Book',
        description: 'Test',
        folder: 'test',
        image: 'test.jpg',
        fileType: 'pdf',
        filePath: 'test/path',
        shopCategorie: 'test',
        isFree: 'yes',
        abbr: 'EN', // Uppercase to test normalization
        price: '0',
        userId: 'test',
        tagIds: '',
      );

      expect(englishBook.languageCode, 'en');
      expect(englishBook.isEnglish, true);
      expect(englishBook.isAssamese, false);

      final assameseBook = Book(
        id: '2',
        title: 'অসমীয়া',
        description: 'Test',
        folder: 'test',
        image: 'test.jpg',
        fileType: 'pdf',
        filePath: 'test/path',
        shopCategorie: 'test',
        isFree: 'yes',
        abbr: 'AS', // Uppercase to test normalization
        price: '0',
        userId: 'test',
        tagIds: '',
      );

      expect(assameseBook.languageCode, 'as');
      expect(assameseBook.isAssamese, true);
      expect(assameseBook.isEnglish, false);
    });

    test('Should apply language filtering in getFilteredBooks', () {
      // Test that getFilteredBooks respects the current language setting
      bookProvider.setLanguage('en');

      // Mock scenario: Home view without active filters
      final filteredBooks = bookProvider.getFilteredBooks(isFilterView: false);

      // All returned books should match the current language
      expect(filteredBooks.every((book) => book.languageCode == 'en'), true);
    });

    test('Should combine language filtering with other filters', () {
      bookProvider.setLanguage('en');
      bookProvider.setShowFreeOnly(true);

      final filteredBooks = bookProvider.getFilteredBooks(isFilterView: true);

      // Should only return English free books
      expect(
          filteredBooks.every(
              (book) => book.languageCode == 'en' && book.isFree == 'yes'),
          true);
    });
  });
}
