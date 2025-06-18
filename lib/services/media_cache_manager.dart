import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/book_model.dart';

class MediaCacheManager {
  static final MediaCacheManager _instance = MediaCacheManager._internal();
  factory MediaCacheManager() => _instance;
  MediaCacheManager._internal();

  final _cacheManager = DefaultCacheManager();
  final _dio = Dio();

  Future<String?> getCachedMediaPath(Book book, String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        return fileInfo.file.path;
      }
      return null;
    } catch (e) {
      print('Error checking cache: $e');
      return null;
    }
  }

  Future<File?> downloadAndCacheMedia(
    Book book,
    String url, {
    Function(int, int)? onProgress,
  }) async {
    try {
      // First check cache
      final cachedPath = await getCachedMediaPath(book, url);
      if (cachedPath != null) {
        return File(cachedPath);
      }

      // Download with progress
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200) {
        // Save to cache
        final file = await _cacheManager.putFile(
          url,
          response.data,
          maxAge: const Duration(days: 30), // Cache for 30 days
        );
        return file;
      }
      return null;
    } catch (e) {
      print('Error downloading media: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      int size = await _calculateDirSize(cacheDir);
      return size;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int size = 0;
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File) {
          size += await entity.length();
        } else if (entity is Directory) {
          size += await _calculateDirSize(entity);
        }
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    return size;
  }
}
