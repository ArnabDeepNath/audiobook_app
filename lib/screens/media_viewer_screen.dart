import 'package:flutter/material.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import '../providers/book_provider.dart';

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
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.book.fileType == 'audio') {
      setupAudioPlayer();
    }
  }

  Future<void> setupAudioPlayer() async {
    final url = widget.provider.getMediaUrl(widget.book);
    await audioPlayer.setSource(UrlSource(url));

    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  Widget buildAudioPlayer() {
    return Stack(
      children: [
        // Background cover image with parallax effect
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          top: isPlaying ? -20 : 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Hero(
            tag:
                '${MediaQuery.of(context).platformBrightness == Brightness.dark ? "library" : "grid"}_book_${widget.book.id}',
            child: Image.network(
              widget.provider.getBookCoverUrl(widget.book),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey[900]),
            ),
          ),
        ),
        // Vignette overlay
        Container(
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
        ),
        // Content
        SafeArea(
          child: Column(
            children: [
              // Top section with title and book info
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated cover art
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isPlaying ? 1.0 : 0.8),
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
                                  child: const Icon(Icons.book,
                                      size: 80, color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    // Title with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Text(
                              widget.book.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Bottom section with controls
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withOpacity(0.2),
                            ),
                            child: Slider(
                              min: 0,
                              max: duration.inSeconds.toDouble(),
                              value: position.inSeconds.toDouble(),
                              onChanged: (value) async {
                                final position =
                                    Duration(seconds: value.toInt());
                                await audioPlayer.seek(position);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatTime(position),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  formatTime(duration),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () async {
                            final newPosition =
                                position - const Duration(seconds: 10);
                            await audioPlayer.seek(newPosition);
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
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                key: ValueKey(isPlaying),
                                color: Colors.black,
                              ),
                            ),
                            iconSize: 40,
                            onPressed: () async {
                              if (isPlaying) {
                                await audioPlayer.pause();
                              } else {
                                await audioPlayer.resume();
                              }
                              setState(() {
                                isPlaying = !isPlaying;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_30),
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () async {
                            final newPosition =
                                position + const Duration(seconds: 30);
                            await audioPlayer.seek(newPosition);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Additional controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.speed),
                            color: Colors.white70,
                            onPressed: () {
                              // TODO: Implement playback speed control
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.timer),
                            color: Colors.white70,
                            onPressed: () {
                              // TODO: Implement sleep timer
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_border),
                            color: Colors.white70,
                            onPressed: () {
                              // TODO: Implement bookmarking
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<File?> downloadPDF() async {
    try {
      final url = widget.provider.getMediaUrl(widget.book);
      print('Downloading PDF from: $url'); // Debug print

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('Received empty PDF file');
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.book.id}.pdf');
      await file.writeAsBytes(bytes);

      if (!await file.exists()) {
        throw Exception('Failed to save PDF file');
      }

      return file;
    } catch (e) {
      print('Error downloading PDF: $e'); // Debug print
      return null;
    }
  }

  Widget buildPdfViewer() {
    return FutureBuilder<File?>(
      future: downloadPDF(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading PDF...')
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Retry loading
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text('Could not load PDF'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Retry loading
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        return PDFView(
          filePath: snapshot.data!.path,
          enableSwipe: true,
          swipeHorizontal:
              false, // Changed to vertical scrolling for better reading
          autoSpacing: true,
          pageFling: false, // Disabled for smoother scrolling
          pageSnap: false, // Disabled for smoother scrolling
          defaultPage: 0,
          fitPolicy: FitPolicy.WIDTH, // Fit to width for better reading
          onError: (error) {
            print('PDF View Error: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          },
          onPageError: (page, error) {
            print('PDF Page $page Error: $error');
          },
          onPageChanged: (int? page, int? total) {
            print('Page ${page ?? 0 + 1} of $total');
          },
          onRender: (pages) {
            print('PDF has $pages pages');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
      ),
      body: SafeArea(
        child: widget.book.fileType == 'pdf'
            ? buildPdfViewer()
            : buildAudioPlayer(),
      ),
    );
  }
}
