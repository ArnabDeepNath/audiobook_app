import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:async';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../services/media_download_manager.dart';

class MediaViewerScreen extends StatefulWidget {
  final Book book;
  final BookProvider provider;

  const MediaViewerScreen({
    Key? key,
    required this.book,
    required this.provider,
  }) : super(key: key);

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localFilePath;
  int? _totalPages;
  int? _currentPage;
  String? _errorMessage;
  final _downloadManager = MediaDownloadManager();
  StreamSubscription? _downloadSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getFileExtension() {
    switch (widget.book.fileType.toLowerCase()) {
      case 'audio':
        return '.mp3';
      case 'pdf':
        return '.pdf';
      default:
        return '';
    }
  }

  Future<void> _initializeMedia() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = widget.provider.getMediaUrl(widget.book);
      final extension =
          _getFileExtension(); // First check if file already exists locally
      final expectedPath =
          await _downloadManager.getLocalPath(widget.book, extension);
      final localFile = File(expectedPath);

      if (await localFile.exists()) {
        final fileSize = await localFile.length();
        if (fileSize > 0) {
          // File exists and has content, use it directly
          print('Using existing file: $expectedPath (size: $fileSize bytes)');
          _localFilePath = expectedPath;
          await _initializePlayer();
          return;
        } else {
          // File exists but is empty, delete it and redownload
          print('Found empty file, deleting: $expectedPath');
          await localFile.delete();
        }
      }

      // Subscribe to download progress updates only if we need to download
      _downloadSubscription?.cancel();
      _downloadSubscription = _downloadManager.downloadStream.listen((info) {
        if (info.book.id == widget.book.id && mounted) {
          setState(() {
            if (info.state == DownloadState.completed) {
              _localFilePath = info.localPath;
              _initializePlayer();
            } else if (info.state == DownloadState.error) {
              _errorMessage = info.error;
              _isLoading = false;
            }
          });
        }
      });

      // Start download
      final filePath = await _downloadManager.downloadMedia(
        widget.book,
        url,
        extension,
      );

      // Double-check if download completed immediately
      if (_downloadManager.isDownloadComplete(widget.book.id)) {
        _localFilePath = filePath;
        await _initializePlayer();
      }
    } catch (e) {
      print('Error loading media: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading media: $e')),
      );
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    if (_localFilePath == null) return;

    try {
      if (widget.book.fileType.toLowerCase() == 'audio') {
        await _audioPlayer.setSource(DeviceFileSource(_localFilePath!));

        _audioPlayer.onDurationChanged.listen((d) {
          if (mounted) setState(() => _duration = d);
        });

        _audioPlayer.onPositionChanged.listen((p) {
          if (mounted) setState(() => _position = p);
        });

        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlaying = false);
        });
      }

      // Set loading to false for both audio and PDF files
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing player: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize media player';
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  Widget _buildAudioControls() {
    final info = _downloadManager.getDownloadInfo(widget.book.id);
    final downloadProgress = info?.progress ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info?.state == DownloadState.downloading)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Buffering: ${(downloadProgress * 100).toInt()}%',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10),
              color: Colors.white,
              iconSize: 32,
              onPressed: () async {
                await _audioPlayer
                    .seek(_position - const Duration(seconds: 10));
              },
            ),
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    key: ValueKey(_isPlaying),
                    color: Colors.black,
                    size: 40,
                  ),
                ),
                onPressed: () async {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    await _audioPlayer.resume();
                  }
                  setState(() => _isPlaying = !_isPlaying);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.forward_30),
              color: Colors.white,
              iconSize: 32,
              onPressed: () async {
                await _audioPlayer
                    .seek(_position + const Duration(seconds: 30));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
          ),
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            min: 0,
            onChanged: (value) async {
              final position = Duration(seconds: value.toInt());
              await _audioPlayer.seek(position);
              setState(() => _position = position);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _isPlaying ? 1.0 : 0.8),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.provider.getBookCoverUrl(widget.book),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.audiotrack,
                                  size: 80,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Text(
                    widget.book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildProgressBar(),
                  ),
                  const SizedBox(height: 20),
                  _buildAudioControls(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFViewer() {
    if (_localFilePath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: _localFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: false,
          pageSnap: false,
          defaultPage: 0,
          fitPolicy: FitPolicy.WIDTH,
          onRender: (pages) {
            if (mounted) {
              setState(() => _totalPages = pages);
            }
          },
          onPageChanged: (page, total) {
            if (mounted) {
              setState(() => _currentPage = page);
            }
          },
          onError: (error) {
            print('PDF Error: $error');
            if (mounted) {
              setState(() {
                _errorMessage = 'Failed to load PDF: $error';
                _isLoading = false;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading PDF: $error')),
            );
          },
        ),
        if (_totalPages != null)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page ${(_currentPage ?? 0) + 1} of $_totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _downloadManager.getDownloadInfo(widget.book.id);

    return WillPopScope(
      onWillPop: () async {
        // Clean up incomplete downloads when navigating back
        if (info?.state == DownloadState.downloading) {
          await _downloadManager.cancelDownload(widget.book.id);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    if (info?.state == DownloadState.downloading)
                      Text(
                        'Downloading: ${(info!.progress * 100).toInt()}%',
                      ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _initializeMedia();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              )
            : widget.book.fileType.toLowerCase() == 'audio'
                ? _buildAudioPlayer()
                : _buildPDFViewer(),
      ),
    );
  }
}
