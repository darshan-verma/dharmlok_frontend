import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_service.dart';
import '../../services/comments_service.dart';
import 'package:video_player/video_player.dart';

class DharmguruPosts extends StatefulWidget {
  final String guruId;
  const DharmguruPosts({Key? key, required this.guruId}) : super(key: key);

  @override
  State<DharmguruPosts> createState() => _DharmguruPostsState();
}

class _DharmguruPostsState extends State<DharmguruPosts> with AutomaticKeepAliveClientMixin {
  // For video controls visibility
  Map<String, bool> _showVideoControls = {};
    // Helper for video controls auto-hide
    void showControls(String videoKey) {
      setState(() {
        _showVideoControls[videoKey] = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showVideoControls[videoKey] = false;
          });
        }
      });
    }
  List<dynamic>? posts;
  bool isLoading = true;
  String? error;
  Map<String, PageController> _pageControllers = {};
  Map<String, int> _currentPages = {};
  Map<String, VideoPlayerController?> _videoControllers = {};
  
  // Like state management (similar to your JS useState)
  Map<String, int> _likeCounts = {}; // postId -> likeCount
  Map<String, bool> _likeStatuses = {}; // postId -> isLiked
  Set<String> _likingPosts = {}; // Track posts currently being liked/unliked
  
  // Comment count state management
  Map<String, int> _commentCounts = {}; // postId -> commentCount

  @override
  bool get wantKeepAlive => true; // This prevents the widget from being recreated

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('https://darshan-dharmlok.vercel.app/api/posts?userId=${widget.guruId}&userType=dharmguru'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          posts = data is List ? data : data['posts'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load posts: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading posts: $e';
        isLoading = false;
      });
    }
  }

  // Fetch like status and count (similar to your useEffect)
  Future<void> _fetchLikeStatus(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('https://darshan-dharmlok.vercel.app/api/posts/$postId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userService = UserService();
        final currentUserId = userService.getDefaultUserId();
        final likes = data['likes'] is List ? data['likes'] as List : [];
        
        setState(() {
          _likeCounts[postId] = likes.length;
          _likeStatuses[postId] = likes.contains(currentUserId);
        });
      }
        } catch (e) {
      print('Error fetching like status for post $postId: $e');
    }
  }

  // Fetch comment count for a post
  Future<void> _fetchCommentCount(String postId) async {
    try {
      final comments = await CommentsService.fetchComments(postId);
      setState(() {
        _commentCounts[postId] = comments.length;
      });
    } catch (e) {
      print('Error fetching comment count for post $postId: $e');
      // Set to 0 if there's an error
      setState(() {
        _commentCounts[postId] = 0;
      });
    }
  }  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id'] ?? '';
    final caption = post['caption'] ?? '';
    final createdAt = post['createdAt'] ?? '';
    final userType = post['userType'] ?? '';
    final mediaList = post['media'] is List ? post['media'] as List : [];
    
    // Handle comment count - check API field first, then fallback to fetched count
    final apiCommentCount = post['commentCount'];
    final commentsCount = apiCommentCount ?? _commentCounts[postId] ?? 0;
    
    // Initialize comment count for this post if not exists and API doesn't provide it
    if (apiCommentCount == null && !_commentCounts.containsKey(postId)) {
      _fetchCommentCount(postId);
    }
    
    // Initialize like state for this post if not exists (similar to useEffect)
    if (!_likeCounts.containsKey(postId)) {
      _fetchLikeStatus(postId);
    }
    
    // Get like state from our maps (similar to your useState)
    final likesCount = _likeCounts[postId] ?? 0;
    final isLiked = _likeStatuses[postId] ?? false;
    
    // Initialize page controller for this post if not exists
    if (!_pageControllers.containsKey(postId)) {
      _pageControllers[postId] = PageController();
      _currentPages[postId] = 0;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Images - Show multiple images with navigation
          if (mediaList.isNotEmpty)
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // Image PageView
                  PageView.builder(
                    controller: _pageControllers[postId],
                    itemCount: mediaList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPages[postId] = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final mediaUrl = mediaList[index]['url'] ?? '';
                      final mediaType = mediaList[index]['type'] ?? 'image';
                      if (mediaType == 'video' && mediaUrl.isNotEmpty) {
                        // Initialize video controller if not exists
                        final videoKey = '$postId-$index';
                        if (_videoControllers[videoKey] == null) {
                          _videoControllers[videoKey] = VideoPlayerController.network(mediaUrl)
                            ..initialize().then((_) {
                              setState(() {});
                            })
                            ..addListener(() {
                              // Update progress bar in real time
                              if (mounted) setState(() {});
                            });
                        }
                        final controller = _videoControllers[videoKey];
                        _showVideoControls.putIfAbsent(videoKey, () => false);
                        if (controller != null && controller.value.isInitialized) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                            child: GestureDetector(
                              onTap: () => showControls(videoKey),
                              child: Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  ),
                                  // Minimal centered play/pause button
                                  if (_showVideoControls[videoKey] ?? false)
                                    Center(
                                      child: IconButton(
                                        icon: Icon(
                                          controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            controller.value.isPlaying ? controller.pause() : controller.play();
                                          });
                                        },
                                      ),
                                    ),
                                  // Minimal progress bar with better styling
                                  if (_showVideoControls[videoKey] ?? false)
                                    Positioned(
                                      bottom: 12,
                                      left: 16,
                                      right: 16,
                                      child: Container(
                                        height: 20,
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 3,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                            activeTrackColor: Colors.white,
                                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                                            thumbColor: Colors.white,
                                            overlayColor: Colors.white.withOpacity(0.2),
                                          ),
                                          child: Slider(
                                            value: controller.value.position.inMilliseconds.toDouble().clamp(
                                              0.0, 
                                              controller.value.duration.inMilliseconds.toDouble()
                                            ),
                                            min: 0,
                                            max: controller.value.duration.inMilliseconds.toDouble(),
                                            onChanged: (value) {
                                              controller.seekTo(Duration(milliseconds: value.toInt()));
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      } else {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                          child: Image.network(
                            mediaUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade300,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 50),
                                    SizedBox(height: 8),
                                    Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                  
                  // Navigation arrows (only show if more than 1 media)
                  if (mediaList.length > 1) ...[
                    // Left arrow
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              final currentPage = _currentPages[postId] ?? 0;
                              if (currentPage > 0) {
                                _pageControllers[postId]?.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    // Right arrow
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              final currentPage = _currentPages[postId] ?? 0;
                              if (currentPage < mediaList.length - 1) {
                                _pageControllers[postId]?.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Page indicator (only show if more than 1 media)
                  if (mediaList.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_currentPages[postId] ?? 0) + 1}/${mediaList.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            // No images available
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
              ),
              child: const Center(
                child: Text(
                  'No images available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interaction Row: Like, Comment, User Type
                Row(
                  children: [
                    // Like button and count
                    GestureDetector(
                      onTap: _likingPosts.contains(postId) ? null : () {
                        _toggleLike(postId, isLiked);
                      },
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _likingPosts.contains(postId)
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                  ),
                                )
                              : Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  key: ValueKey(isLiked),
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likesCount likes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _likingPosts.contains(postId) ? Colors.grey : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Comment button and count
                    GestureDetector(
                      onTap: () => _showCommentsModal(context, postId),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.comment_outlined,
                            color: Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$commentsCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // User Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        userType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Comments Preview - Show count and option to view
                if (commentsCount > 0) ...[
                  GestureDetector(
                    onTap: () => _showCommentsModal(context, postId),
                    child: Text(
                      commentsCount == 1 
                        ? 'View 1 comment'
                        : 'View all $commentsCount comments',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // Always show option to add comment even if count is 0
                  GestureDetector(
                    onTap: () => _showCommentsModal(context, postId),
                    child: Text(
                      'Add a comment',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Post Caption
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Date
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 30) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  // Handle like (similar to your handleLike function)
  Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
    // Prevent multiple rapid taps on the same post (similar to likeLoading state)
    if (_likingPosts.contains(postId)) {
      return;
    }
    
    _likingPosts.add(postId);
    
    final userService = UserService();
    final currentUserId = userService.getDefaultUserId();
    
    try {
      // Use DELETE for unlike, POST for like (same as your JS code)
      final response = isCurrentlyLiked 
        ? await http.delete(
            Uri.parse('https://darshan-dharmlok.vercel.app/api/posts/$postId/like'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': currentUserId}),
          )
        : await http.post(
            Uri.parse('https://darshan-dharmlok.vercel.app/api/posts/$postId/like'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': currentUserId}),
          );
      
      // If DELETE is not supported, fall back to POST with action
      if (response.statusCode == 405 || response.statusCode == 404) {
        final fallbackResponse = await http.post(
          Uri.parse('https://darshan-dharmlok.vercel.app/api/posts/$postId/like'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': currentUserId,
            'action': isCurrentlyLiked ? 'unlike' : 'like',
          }),
        );
        
        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
          final data = json.decode(fallbackResponse.body);
          setState(() {
            _likeCounts[postId] = data['likes'].length;
            _likeStatuses[postId] = !isCurrentlyLiked;
          });
        }
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _likeCounts[postId] = data['likes'].length;
          _likeStatuses[postId] = !isCurrentlyLiked;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    } finally {
      _likingPosts.remove(postId);
    }
  }

  void _showCommentsModal(BuildContext context, String postId) async {
    final TextEditingController commentController = TextEditingController();
    List<dynamic> comments = [];
    bool isLoading = true;
    String? errorMessage;
    
    // Fetch comments from separate collection
    try {
      comments = await CommentsService.fetchComments(postId);
      isLoading = false;
    } catch (e) {
      print('Error fetching comments: $e');
      errorMessage = 'Unable to load comments';
      isLoading = false;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Modal handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Title
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Comments list
                  Expanded(
                    child: isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, 
                                         size: 48, 
                                         color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      errorMessage,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Comments feature is coming soon!',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            : comments.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No comments yet\nBe the first to comment!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User avatar
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: comment['user']?['profileImageUrl'] != null
                                              ? NetworkImage(comment['user']['profileImageUrl'])
                                              : null,
                                          child: comment['user']?['profileImageUrl'] == null
                                              ? const Icon(Icons.person, size: 16)
                                              : null,
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        
                                        // Comment content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment['user']?['name'] ?? 'Anonymous',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment['text'] ?? '',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                CommentsService.formatDate(comment['createdAt'] ?? ''),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  
                  // Comment input
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            maxLines: null,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (commentController.text.trim().isNotEmpty) {
                              final success = await _addComment(postId, commentController.text);
                              if (success) {
                                commentController.clear();
                                // Refresh comments
                                final newComments = await CommentsService.fetchComments(postId);
                                setModalState(() {
                                  comments = newComments;
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.send, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _addComment(String postId, String commentText) async {
    if (commentText.trim().isEmpty) return false;
    try {
      final userService = UserService();
      final currentUserId = userService.getDefaultUserId();
      print('Sending comment: userId=[32m$currentUserId[0m, text=[32m$commentText[0m'); // DEBUG
      final success = await CommentsService.addComment(
        postId: postId,
        userId: currentUserId,
        text: commentText.trim(),
      );
      
      if (success) {
        fetchPosts(); // Refresh posts to update comment count
        return true;
      } else {
        print('Failed to add comment');
        return false;
      }
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // Dispose all page controllers
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  error = null;
                });
                fetchPosts();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (posts == null || posts!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No posts available',
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
        await fetchPosts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: posts!.length,
        itemBuilder: (context, index) {
          final post = posts![index];
          return _buildPostCard(post);
        },
      ),
    );
  }
}
