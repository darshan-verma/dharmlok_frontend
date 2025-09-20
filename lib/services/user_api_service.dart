import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/user_type_config.dart';
import '../models/user_models.dart';

class UserApiService {
  final String baseUrl;
  final UserTypeConfig config;

  UserApiService({
    this.baseUrl = 'https://darshan-dharmlok.vercel.app',
    required this.config,
  });

  // Factory method to create service for specific user type
  factory UserApiService.forUserType(UserType userType, {String? baseUrl}) {
    final config = UserTypeConfig.getConfig(userType);
    return UserApiService(
      baseUrl: baseUrl ?? 'https://darshan-dharmlok.vercel.app',
      config: config,
    );
  }

  /// Fetch user details
  Future<User?> fetchUser(String userId) async {
    try {
      final url = config.getApiUrl('user', userId, baseUrl: baseUrl);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromJson(userData, config.userType);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  /// Fetch user biography
  Future<List<dynamic>?> fetchBiography(String userId) async {
    try {
      final url = config.getApiUrl('bio', userId, baseUrl: baseUrl);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final bioData = userData['bio'];
        
        if (bioData is String && bioData.isNotEmpty) {
          return json.decode(bioData);
        } else if (bioData is List) {
          return bioData;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load biography: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching biography: $e');
      return null;
    }
  }

  /// Fetch user posts
  Future<List<dynamic>?> fetchPosts(String userId) async {
    try {
      final url = config.getApiUrl('posts', userId, baseUrl: baseUrl);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : data['posts'] ?? [];
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      return null;
    }
  }

  /// Fetch user videos
  Future<List<dynamic>?> fetchVideos(String userId) async {
    try {
      final url = config.getApiUrl('videos', userId, baseUrl: baseUrl);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['videos'] != null && data['videos'] is List) {
          return data['videos'];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching videos: $e');
      return null;
    }
  }

  /// Fetch user photos
  Future<List<dynamic>?> fetchPhotos(String userId) async {
    try {
      final url = config.getApiUrl('photos', userId, baseUrl: baseUrl);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both 'images' array and single 'image' field
        if (data['images'] != null && data['images'] is List) {
          return data['images'];
        } else if (data['image'] != null) {
          // If single image, wrap it in a list
          return [data['image']];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load photos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching photos: $e');
      return null;
    }
  }

  /// Like/Unlike a post
  Future<Map<String, dynamic>?> toggleLike(String postId, String userId, bool isCurrentlyLiked) async {
    try {
      final url = '$baseUrl/api/posts/$postId/like';
      final response = isCurrentlyLiked 
        ? await http.delete(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': userId}),
          )
        : await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': userId}),
          );
      
      // If DELETE is not supported, fall back to POST with action
      if (response.statusCode == 405 || response.statusCode == 404) {
        final fallbackResponse = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': userId,
            'action': isCurrentlyLiked ? 'unlike' : 'like',
          }),
        );
        
        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
          return json.decode(fallbackResponse.body);
        }
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      
      return null;
    } catch (e) {
      print('Error toggling like: $e');
      return null;
    }
  }

  /// Fetch like status for a post
  Future<Map<String, dynamic>?> fetchLikeStatus(String postId, String userId) async {
    try {
      final url = '$baseUrl/api/posts/$postId';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final likes = data['likes'] is List ? data['likes'] as List : [];
        
        return {
          'likeCount': likes.length,
          'isLiked': likes.contains(userId),
        };
      }
      return null;
    } catch (e) {
      print('Error fetching like status: $e');
      return null;
    }
  }

  /// Fetch list of users for the given user type
  Future<List<User>> fetchUsers() async {
    try {
      final url = '$baseUrl/api/users?userType=${config.userType.name.toLowerCase()}';
      final response = await http.get(Uri.parse(url));
      
      print('${config.displayName} API Status: ${response.statusCode}');
      print('${config.displayName} API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> usersData;
        
        // Handle different response structures
        if (decoded is Map && decoded.containsKey('users')) {
          usersData = decoded['users'];
        } else if (decoded is Map && decoded.containsKey(config.userType.name.toLowerCase() + 's')) {
          usersData = decoded[config.userType.name.toLowerCase() + 's'];
        } else if (decoded is List) {
          usersData = decoded;
        } else {
          usersData = [];
        }
        
        print('Parsed ${usersData.length} ${config.displayName}s');
        
        return usersData
            .map((userData) => User.fromJson(userData, config.userType))
            .toList();
      } else {
        throw Exception('Failed to load ${config.displayName}s: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching ${config.displayName}s: $e');
      throw Exception('Error fetching ${config.displayName}s: $e');
    }
  }
}