import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../services/user_api_service.dart';
import '../../config/user_type_config.dart';

class UserVideos extends StatefulWidget {
  final String userId;
  final UserType userType;
  
  const UserVideos({
    super.key, 
    required this.userId,
    required this.userType,
  });

  @override
  State<UserVideos> createState() => _UserVideosState();
}

class _UserVideosState extends State<UserVideos> with AutomaticKeepAliveClientMixin {
  List<dynamic>? videos;
  bool isLoading = true;
  String? error;
  late UserApiService apiService;
  late UserTypeConfig config;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    config = UserTypeConfig.getConfig(widget.userType);
    apiService = UserApiService.forUserType(widget.userType);
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    try {
      final videosData = await apiService.fetchVideos(widget.userId);
      setState(() {
        videos = videosData ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading videos: $e';
        isLoading = false;
      });
    }
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
              key: ValueKey('video_popup_${videoUrl}_${DateTime.now().millisecondsSinceEpoch}'),
              videoUrl: videoUrl,
              title: title,
              config: config,
            ),
          );
        },
      ),
    );
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
            key: ValueKey('video_grid_${videos!.length}'),
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
              final videoUrl = video['videoFile'] ?? '';
              final title = video['title'] ?? '';
              final description = video['description'] ?? '';

              return VideoCard(
                key: ValueKey('video_card_${index}_${videoUrl}_${title}'),
                videoUrl: videoUrl,
                title: title,
                description: description,
                config: config,
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
}

// Video Card Widget with Video Preview
class VideoCard extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final UserTypeConfig config;
  final VoidCallback? onTap;

  const VideoCard({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.config,
    this.onTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _previewController;
  bool _isPreviewLoading = true;
  bool _previewError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isNotEmpty) {
      _initializePreview();
    } else {
      setState(() {
        _isPreviewLoading = false;
        _previewError = true;
      });
    }
  }

  Future<void> _initializePreview() async {
    try {
      _previewController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'DharmlokApp/1.0',
          'Range': 'bytes=0-1024', // Only load first few bytes for preview
        },
      );
      
      await _previewController!.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Preview timeout'),
      );
      
      // Seek to a frame a few seconds in to get a better preview
      await _previewController!.seekTo(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
          _previewError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _previewController?.dispose();
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
                    child: _buildVideoPreview(),
                  ),
                  // Play button overlay
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
    if (_isPreviewLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading Preview',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_previewError || _previewController == null || !_previewController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
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
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'TAP TO PLAY',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show the first frame of the video as preview
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _previewController!.value.size.width,
          height: _previewController!.value.size.height,
          child: VideoPlayer(_previewController!),
        ),
      ),
    );
  }
}

// Simple Video Popup Player
class VideoPopupPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final UserTypeConfig config;

  const VideoPopupPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.config,
  });

  @override
  State<VideoPopupPlayer> createState() => _VideoPopupPlayerState();
}

class _VideoPopupPlayerState extends State<VideoPopupPlayer> {
  VideoPlayerController? _videoPlayerController;
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
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'DharmlokApp/1.0',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      );
      
      // Add timeout to prevent excessive loading
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video loading timed out');
        },
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false, // Don't autoplay to save bandwidth and load faster
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: widget.config.primaryColor,
          handleColor: widget.config.primaryColor,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade400,
        ),
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        autoInitialize: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        hideControlsTimer: const Duration(seconds: 2),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().contains('timed out') 
            ? 'Video loading timed out. Please check your connection.'
            : 'Failed to load video: ${error.toString().length > 50 ? error.toString().substring(0, 50) + "..." : error.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
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
              // Header
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading Video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
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