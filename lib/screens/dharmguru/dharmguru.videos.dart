import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class DharmguruVideos extends StatefulWidget {
  final String guruId;
  const DharmguruVideos({Key? key, required this.guruId}) : super(key: key);

  @override
  State<DharmguruVideos> createState() => _DharmguruVideosState();
}

class _DharmguruVideosState extends State<DharmguruVideos> with AutomaticKeepAliveClientMixin {
  List<dynamic>? videos;
  bool isLoading = true;
  String? error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    try {
      print('Fetching videos for guruId: ${widget.guruId}');
      final response = await http.get(
        Uri.parse('https://darshan-dharmlok.vercel.app/api/users/${widget.guruId}'),
      );

      print('Videos API Status: ${response.statusCode}');
      print('Videos API Response length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle videos array
        if (data['videos'] != null && data['videos'] is List) {
          videos = data['videos'];
          print('Found ${videos!.length} videos in videos array');
        } else {
          videos = [];
          print('No videos field found in response');
        }
        print('Videos loaded: ${videos?.length ?? 0}');
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load videos: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching videos: $e');
      setState(() {
        error = 'Error loading videos: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load videos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error!.length > 200 ? '${error!.substring(0, 200)}...' : error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  fetchVideos();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (videos == null || videos!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No videos available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          isLoading = true;
          error = null;
        });
        await fetchVideos();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid configuration
          int crossAxisCount = 2;
          double childAspectRatio = 0.8;
          
          if (constraints.maxWidth > 900) {
            crossAxisCount = 4;
            childAspectRatio = 0.75;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 3;
            childAspectRatio = 0.8;
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: videos!.length,
            itemBuilder: (context, index) {
              final video = videos![index];
              final thumbnailUrl = video['thumbnailUrl'] ?? '';
              final videoUrl = video['videoFile'] ?? '';
              final title = video['title'] ?? '';
              final description = video['description'] ?? '';
              final status = video['status'] ?? 'pending';

              return VideoCard(
                thumbnailUrl: thumbnailUrl,
                videoUrl: videoUrl,
                title: title,
                description: description,
                status: status,
                onTap: videoUrl.isNotEmpty 
                    ? () => _showVideoPopup(context, videoUrl, title)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showVideoPopup(BuildContext context, String videoUrl, String title) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.8),
        pageBuilder: (context, animation, _) {
          return FadeTransition(
            opacity: animation,
            child: VideoPopupPlayer(
              videoUrl: videoUrl,
              title: title,
            ),
          );
        },
      ),
    );
  }
}

// Enhanced Video Card Widget
class VideoCard extends StatefulWidget {
  final String thumbnailUrl;
  final String videoUrl;
  final String title;
  final String description;
  final String status;
  final VoidCallback? onTap;

  const VideoCard({
    Key? key,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.status,
    this.onTap,
  }) : super(key: key);

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    if (widget.thumbnailUrl.isEmpty && widget.videoUrl.isNotEmpty) {
      _initializeVideoController();
    }
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thumbnailUrl != oldWidget.thumbnailUrl || 
        widget.videoUrl != oldWidget.videoUrl) {
      _disposeController();
      if (widget.thumbnailUrl.isEmpty && widget.videoUrl.isNotEmpty) {
        _initializeVideoController();
      }
    }
  }

  Future<void> _initializeVideoController() async {
    if (_videoController != null) return;
    
    setState(() {
      _isVideoLoading = true;
      _videoError = null;
    });

    try {
      _videoController = VideoPlayerController.network(widget.videoUrl);
      await _videoController!.initialize();
      // Seek to 1 second to get a frame (not the very first frame which might be black)
      await _videoController!.seekTo(const Duration(seconds: 1));
      setState(() {
        _isVideoLoading = false;
      });
    } catch (error) {
      setState(() {
        _isVideoLoading = false;
        _videoError = error.toString();
      });
    }
  }

  void _disposeController() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                    child: widget.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            widget.thumbnailUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildVideoPreview();
                            },
                          )
                        : _buildVideoPreview(),
                  ),
                  // Gradient overlay for better play button visibility
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  // Enhanced play button overlay
                  if (widget.videoUrl.isNotEmpty)
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title.isNotEmpty)
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_isVideoLoading) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_videoError != null || _videoController == null) {
      return Container(
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              widget.title.isNotEmpty ? widget.title : 'Video Preview',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: widget.title.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController!.value.size.width,
        height: _videoController!.value.size.height,
        child: VideoPlayer(_videoController!),
      ),
    );
  }
}

// Enhanced Video Popup Player with Fullscreen Support
class VideoPopupPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPopupPlayer({
    Key? key,
    required this.videoUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<VideoPopupPlayer> createState() => _VideoPopupPlayerState();
}

class _VideoPopupPlayerState extends State<VideoPopupPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade400,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        autoInitialize: true,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        customControls: const MaterialControls(),
        hideControlsTimer: const Duration(seconds: 3),
        fullScreenByDefault: false,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        systemOverlaysAfterFullScreen: SystemUiOverlay.values,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: $error';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          constraints: const BoxConstraints(
            maxWidth: 800,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with title and controls
              Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.title.isEmpty ? 'Video Player' : widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_chewieController != null)
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.black87),
                        onPressed: () {
                          _chewieController!.enterFullScreen();
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              // Video player
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: _buildVideoPlayer(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return const Center(
      child: Text(
        'Unable to load video player',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}