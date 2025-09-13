import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  final String baseUrl = dotenv.env['API_URL'] ?? "";

  // Check if API URL is properly configured
  bool get isApiConfigured => baseUrl.isNotEmpty && !baseUrl.contains('your-api-endpoint.com');
  
  // Mock mode for testing UI without backend - when API_URL is null or empty
  bool get isMockMode => dotenv.env['API_URL'] == null || dotenv.env['API_URL']!.isEmpty;

  //// Sign In API
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    debugPrint('API URL from env: "${dotenv.env['API_URL']}"');
    debugPrint('Base URL: "$baseUrl"');
    debugPrint('Is mock mode: $isMockMode');
    debugPrint('Is API configured: $isApiConfigured');
    
    // Mock mode - simulate successful sign in for UI testing
    if (isMockMode) {
      debugPrint('Mock mode: Simulating successful sign in');
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return {'success': true, 'message': 'Mock sign in successful', 'user': {'email': email}};
    }
    
    if (!isApiConfigured) {
      throw Exception('API URL not configured. Please update your .env file with a valid API endpoint.');
    }
    
    debugPrint('Attempting sign in with base URL: $baseUrl');
    try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      debugPrint('Sign in response status: ${response.statusCode}');
      debugPrint('Sign in response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.trim().startsWith('<')) {
          throw Exception('API endpoint returned HTML instead of JSON. Please check your API URL.');
        }
        final data = jsonDecode(response.body);
        if (data['user'] != null || data['success'] == true) {
          return data;
        } else {
          // If backend returns error field, show it
          final errorMsg = data['error'] ?? 'Unexpected response: ${response.body}';
          throw Exception(errorMsg);
        }
      } else {
        // For any other status, show backend error if present
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMsg = data['error'] ?? 'Failed to sign in.';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      if (e.toString().contains('FormatException')) {
        throw Exception('Invalid API response format. Please check your API endpoint.');
      }
      throw Exception('Network error: $e');
    }
  }
  
  //// Sign Up API
  Future<Map<String, dynamic>> signUp(String name, String email, String phone, String password) async {
    debugPrint('API URL from env: "$baseUrl"');
    debugPrint('Is mock mode: $isMockMode');
    debugPrint('Is API configured: $isApiConfigured');
    debugPrint('Attempting sign up with:');
    debugPrint('  Name: $name');
    debugPrint('  Email: $email');
    debugPrint('  Phone: $phone');
    debugPrint('  Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} chars)');
    
    // Mock mode - simulate successful sign up for UI testing
    if (isMockMode) {
      debugPrint('Mock mode: Simulating successful sign up');
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return {'success': true, 'message': 'Mock sign up successful', 'user': {'name': name, 'email': email}};
    }
    
    if (!isApiConfigured) {
      throw Exception('API URL not configured. Please update your .env file with a valid API endpoint.');
    }
    
    debugPrint('Attempting sign up with base URL: $baseUrl');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),  // Changed from /api/users/signup
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );
      
      debugPrint('Sign up response status: ${response.statusCode}');
      debugPrint('Sign up response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response is HTML (indicating a redirect or error page)
        if (response.body.trim().startsWith('<')) {
          throw Exception('API endpoint returned HTML instead of JSON. Please check your API URL.');
        }
        final data = jsonDecode(response.body);
        if ((data['message'] == 'User created successfully' && data['user'] != null) || data['success'] == true) {
          return data;
        } else {
          throw Exception('Unexpected response: ${response.body}');
        }
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (e) {
      debugPrint('Sign up error: $e');
      if (e.toString().contains('FormatException')) {
        throw Exception('Invalid API response format. Please check your API endpoint.');
      }
      throw Exception('Network error: $e');
    }
  }
}
