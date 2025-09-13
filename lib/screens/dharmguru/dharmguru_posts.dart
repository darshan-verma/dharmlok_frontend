import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_service.dart';
import '../../services/comments_service.dart';

class DharmguruPosts extends StatefulWidget {
  final String guruId;
  const DharmguruPosts({Key? key, required this.guruId}) : super(key: key);

  @override
  State<DharmguruPosts> createState() => _DharmguruPostsState();
}

class _DharmguruPostsState extends State<DharmguruPosts> with AutomaticKeepAliveClientMixin {
  List<dynamic>? posts;
  bool isLoading = true;
  String? error;
  Map<String, PageController> _pageControllers = {};
  Map<String, int> _currentPages = {};
  Set<String> _likingPosts = {}; // Track posts currently being liked/unliked

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
        print('Fetched ${posts?.length ?? 0} posts for dharmguru ${widget.guruId}');
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

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id'] ?? '';
    final caption = post['caption'] ?? '';
    final createdAt = post['createdAt'] ?? '';
    final userType = post['userType'] ?? '';
    final likesList = post['likes'] is List ? post['likes'] as List : [];
    final likesCount = likesList.length;
    final mediaList = post['media'] is List ? post['media'] as List : [];
    
    // Handle comment count - try different possible field names
    final commentsCount = post['commentsCount'] ?? 
                         post['commentCount'] ?? 
                         (post['comments'] is List ? (post['comments'] as List).length : 0);
    
    // Debug print to see the actual post structure
    print('Post structure for debugging:');
    print('- Post ID: $postId');
    print('- Likes: $likesCount');
    print('- Comments count: $commentsCount');
    print('- Available fields: ${post.keys.toList()}');
    
    // Get current user ID from UserService
    final userService = UserService();
    final currentUserId = userService.getDefaultUserId();
    final isLiked = likesList.contains(currentUserId);
    
    // Initialize page controller for this post if not exists
    if (!_pageControllers.containsKey(postId)) {
      _pageControllers[postId] = PageController();
      _currentPages[postId] = 0;
    }
    
    // Debug print to see the post structure
    print('Post data: $post');
    print('Media count: ${mediaList.length}');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Images - Show multiple images with navigation
          if (mediaList.isNotEmpty)
            Container(
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
                      
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                        child: mediaType == 'video'
                          ? Container(
                              color: Colors.black,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                                    SizedBox(height: 8),
                                    Text('Video', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            )
                          : Image.network(
                              mediaUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_not_supported, size: 50),
                                      const SizedBox(height: 8),
                                      Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                            ),
                      );
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
              child: Center(
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
                      onTap: () {
                        // Add haptic feedback for better user experience
                        _toggleLike(postId, isLiked);
                      },
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(isLiked),
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likesCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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

  Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
    // Prevent multiple rapid taps on the same post
    if (_likingPosts.contains(postId)) {
      print('Like request already in progress for post $postId');
      return;
    }
    
    _likingPosts.add(postId);
    
    final userService = UserService();
    final currentUserId = userService.getDefaultUserId();
    
    print('Toggle Like Debug:');
    print('- Post ID: $postId');
    print('- User ID: $currentUserId');
    print('- Currently Liked: $isCurrentlyLiked');
    
    // Send API request FIRST, then update UI only on success
    try {
      final response = await http.post(
        Uri.parse('https://darshan-dharmlok.vercel.app/api/posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': currentUserId,
          'action': isCurrentlyLiked ? 'unlike' : 'like',
        }),
      );
      
      print('API Response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('API success - updating UI');
        // Only update UI after API confirms success
        setState(() {
          if (posts != null) {
            for (var post in posts!) {
              if (post['id'] == postId) {
                List<dynamic> likes = List.from(post['likes'] ?? []);
                
                if (isCurrentlyLiked) {
                  // Unlike - remove user ID
                  likes.removeWhere((id) => id == currentUserId);
                  print('UNLIKE: Removed user from likes. New count: ${likes.length}');
                } else {
                  // Like - add user ID (only if not already there)
                  if (!likes.contains(currentUserId)) {
                    likes.add(currentUserId);
                    print('LIKE: Added user to likes. New count: ${likes.length}');
                  }
                }
                
                post['likes'] = likes;
                break;
              }
            }
          }
        });
      } else {
        print('API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
    } finally {
      // Always remove from the set when done
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
      print('Fetched ${comments.length} comments for post $postId');
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
