import 'package:flutter/material.dart';

enum UserType {
  dharmguru,
  kathavachak,
  panditji,
}

class UserTypeConfig {
  final UserType userType;
  final String displayName;
  final String apiEndpoint;
  final Color primaryColor;
  final Color accentColor;
  final Color lightBackgroundColor;
  final String bannerText;
  final List<String> tabLabels;
  final Map<String, String> apiPaths;

  const UserTypeConfig({
    required this.userType,
    required this.displayName,
    required this.apiEndpoint,
    required this.primaryColor,
    required this.accentColor,
    required this.lightBackgroundColor,
    required this.bannerText,
    required this.tabLabels,
    required this.apiPaths,
  });

  static UserTypeConfig getConfig(UserType userType) {
    switch (userType) {
      case UserType.dharmguru:
        return const UserTypeConfig(
          userType: UserType.dharmguru,
          displayName: 'Dharmguru',
          apiEndpoint: 'dharmguru',
          primaryColor: Color(0xFFED7B30),
          accentColor: Color(0xFF8B6F4E),
          lightBackgroundColor: Color(0xFFFFF3E3),
          bannerText: 'कौन हैं श्री रविशंकर जी महाराज',
          tabLabels: ['Biography', 'Posts', 'Videos', 'Photos'],
          apiPaths: {
            'posts': '/api/posts?userId={userId}&userType=dharmguru',
            'user': '/api/users/{userId}',
            'bio': '/api/users/{userId}',
            'videos': '/api/users/{userId}',
            'photos': '/api/users/{userId}',
          },
        );

      case UserType.kathavachak:
        return const UserTypeConfig(
          userType: UserType.kathavachak,
          displayName: 'Kathavachak',
          apiEndpoint: 'kathavachak',
          primaryColor: Color(0xFF6B4F36),
          accentColor: Color(0xFFB2C94B),
          lightBackgroundColor: Color(0xFFF0F5E6),
          bannerText: 'महान कथावाचक की दिव्य कथा',
          tabLabels: ['Biography', 'Posts', 'Videos', 'Photos'],
          apiPaths: {
            'posts': '/api/posts?userId={userId}&userType=kathavachak',
            'user': '/api/users/{userId}',
            'bio': '/api/users/{userId}',
            'videos': '/api/users/{userId}',
            'photos': '/api/users/{userId}',
          },
        );

      case UserType.panditji:
        return const UserTypeConfig(
          userType: UserType.panditji,
          displayName: 'Panditji',
          apiEndpoint: 'panditji',
          primaryColor: Color(0xFF8B4513),
          accentColor: Color(0xFFDEB887),
          lightBackgroundColor: Color(0xFFFAF5EF),
          bannerText: 'पंडित जी के धार्मिक ज्ञान की गंगा',
          tabLabels: ['Biography', 'Posts', 'Sermons', 'Photos'],
          apiPaths: {
            'posts': '/api/posts?userId={userId}&userType=panditji',
            'user': '/api/users/{userId}',
            'bio': '/api/users/{userId}',
            'videos': '/api/users/{userId}', // Note: 'Sermons' uses videos endpoint
            'photos': '/api/users/{userId}',
          },
        );
    }
  }

  // Get API URL with userId replaced
  String getApiUrl(String apiKey, String userId, {String baseUrl = 'https://darshan-dharmlok.vercel.app'}) {
    final path = apiPaths[apiKey];
    if (path == null) {
      throw Exception('API path not found for key: $apiKey');
    }
    return '$baseUrl${path.replaceAll('{userId}', userId)}';
  }

  // Helper to get UserType from string
  static UserType userTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'dharmguru':
        return UserType.dharmguru;
      case 'kathavachak':
        return UserType.kathavachak;
      case 'panditji':
        return UserType.panditji;
      default:
        throw Exception('Unknown user type: $typeString');
    }
  }

  // Helper to get string from UserType
  static String userTypeToString(UserType userType) {
    return userType.toString().split('.').last;
  }
}