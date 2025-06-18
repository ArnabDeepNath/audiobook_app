import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/book_model.dart';

enum DownloadState {
  none,
  downloading,
  paused,
  completed,
  error,
}

class DownloadInfo {
  final Book book;
  final String url;
  final String localPath;
  DownloadState state;
  double progress;
  int received;
  final int total;
  String? error;
  final completer = Completer<String>();
  StreamSubscription? subscription;
  IOSink? fileSink;

  DownloadInfo({
    required this.book,
    required this.url,
    required this.localPath,
    required this.total,
    this.state = DownloadState.none,
    this.progress = 0.0,
    this.received = 0,
  });

  bool get isComplete => state == DownloadState.completed;
  bool get isDownloading => state == DownloadState.downloading;
  bool get canResume =>
      state == DownloadState.paused || state == DownloadState.error;
}

class MediaDownloadManager {
  static final MediaDownloadManager _instance =
      MediaDownloadManager._internal();
  factory MediaDownloadManager() => _instance;
  MediaDownloadManager._internal();

  final Map<String, DownloadInfo> _downloads = {};
  final _controller = StreamController<DownloadInfo>.broadcast();
  Stream<DownloadInfo> get downloadStream => _controller.stream;

  Future<String> getLocalPath(Book book, String fileExtension) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${book.id}$fileExtension';
  }

  bool isDownloading(String bookId) {
    return _downloads[bookId]?.isDownloading ?? false;
  }

  bool isDownloadComplete(String bookId) {
    return _downloads[bookId]?.isComplete ?? false;
  }

  DownloadInfo? getDownloadInfo(String bookId) => _downloads[bookId];

  Future<String> downloadMedia(
      Book book, String url, String fileExtension) async {
    // Check if already downloading
    if (_downloads.containsKey(book.id)) {
      final info = _downloads[book.id]!;
      if (info.isComplete) return info.localPath;
      if (info.isDownloading) return info.completer.future;
      if (info.canResume) {
        return _resumeDownload(info);
      }
    }

    final localPath = await getLocalPath(book, fileExtension);
    final file = File(localPath); // Check if file exists and is complete
    if (await file.exists()) {
      final fileSize = await file.length();
      final response = await http.head(Uri.parse(url));
      final totalSize = int.parse(response.headers['content-length'] ?? '0');

      if (fileSize > 0 && (totalSize == 0 || fileSize == totalSize)) {
        _downloads[book.id] = DownloadInfo(
          book: book,
          url: url,
          localPath: localPath,
          total: totalSize > 0 ? totalSize : fileSize,
          received: fileSize,
          progress: 1.0,
          state: DownloadState.completed,
        );
        return localPath;
      }
    }

    return _startNewDownload(book, url, localPath);
  }

  Future<String> _startNewDownload(
      Book book, String url, String localPath) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);
    final total = response.contentLength ?? 0;

    final info = DownloadInfo(
      book: book,
      url: url,
      localPath: localPath,
      total: total,
      state: DownloadState.downloading,
    );
    _downloads[book.id] = info;

    final file = File(localPath);
    info.fileSink = file.openWrite();

    info.subscription = response.stream.listen(
      (chunk) {
        if (info.state == DownloadState.downloading) {
          info.fileSink!.add(chunk);
          info.received += chunk.length;
          info.progress = info.received / info.total;
          _controller.add(info);
        }
      },
      onDone: () async {
        await info.fileSink?.close();
        info.state = DownloadState.completed;
        _controller.add(info);
        info.completer.complete(localPath);
      },
      onError: (error) async {
        await info.fileSink?.close();
        info.state = DownloadState.error;
        info.error = error.toString();
        _controller.add(info);
        info.completer.completeError(error);
      },
      cancelOnError: true,
    );

    return info.completer.future;
  }

  Future<String> _resumeDownload(DownloadInfo info) async {
    final file = File(info.localPath);
    final fileSize = await file.length();

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(info.url));
    request.headers['Range'] = 'bytes=$fileSize-';

    final response = await client.send(request);
    info.fileSink = file.openWrite(mode: FileMode.append);
    info.state = DownloadState.downloading;

    info.subscription = response.stream.listen(
      (chunk) {
        if (info.state == DownloadState.downloading) {
          info.fileSink!.add(chunk);
          info.received += chunk.length;
          info.progress = info.received / info.total;
          _controller.add(info);
        }
      },
      onDone: () async {
        await info.fileSink?.close();
        info.state = DownloadState.completed;
        _controller.add(info);
        info.completer.complete(info.localPath);
      },
      onError: (error) async {
        await info.fileSink?.close();
        info.state = DownloadState.error;
        info.error = error.toString();
        _controller.add(info);
        info.completer.completeError(error);
      },
      cancelOnError: true,
    );

    return info.completer.future;
  }

  Future<void> pauseDownload(String bookId) async {
    final info = _downloads[bookId];
    if (info?.isDownloading ?? false) {
      await info!.subscription?.cancel();
      await info.fileSink?.flush();
      info.state = DownloadState.paused;
      _controller.add(info);
    }
  }

  Future<void> cancelDownload(String bookId) async {
    final info = _downloads[bookId];
    if (info != null) {
      await info.subscription?.cancel();
      await info.fileSink?.close();
      _downloads.remove(bookId);

      // Delete partial file
      final file = File(info.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> dispose() async {
    for (final info in _downloads.values) {
      await info.subscription?.cancel();
      await info.fileSink?.close();
    }
    _downloads.clear();
    await _controller.close();
  }
}
