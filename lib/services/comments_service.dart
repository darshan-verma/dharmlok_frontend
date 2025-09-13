import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentsService {
  static const String baseUrl = 'https://darshan-dharmlok.vercel.app/api';
  
  // Fetch comments for a specific post from the Comment collection
  static Future<List<dynamic>> fetchComments(String postId) async {
    try {
      // Try different possible API endpoints for comments
      List<String> possibleEndpoints = [
        '$baseUrl/comments?postId=$postId',
        '$baseUrl/posts/$postId/comments',
        '$baseUrl/comment?postId=$postId',
      ];
      
      for (String endpoint in possibleEndpoints) {
        try {
          final response = await http.get(Uri.parse(endpoint));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('Successfully fetched comments from: $endpoint');
            // Handle both array response and object with comments array
            return data is List ? data : data['comments'] ?? [];
          }
        } catch (e) {
          print('Endpoint $endpoint failed: $e');
          continue;
        }
      }
      
      print('All comment endpoints failed for postId: $postId');
      return [];
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }
  
  // Add a new comment to the Comment collection
  static Future<bool> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    try {
      final url = '$baseUrl/posts/$postId/comments';
      final body = {
        'userId': userId,
        'text': text,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Successfully added comment via: $url');
        return true;
      } else {
        print('Failed to add comment via $url: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }
  
  // Delete a comment (if user owns it)
  static Future<bool> deleteComment(String commentId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }
  
  // Format date for display
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
