# User Profile Components Usage Guide

This guide demonstrates how to use the new reusable user profile components for different user types (Dharmguru, Kathavachak, Panditji).

## Overview

The refactored user profile system consists of:
- **UserProfileDetailsScreen**: Main screen component
- **UserTypeConfig**: Configuration for different user types
- **UserApiService**: API service factory for different user types
- **User Models**: Data models for different user types
- **Generic Components**: UserBio, UserPosts, UserVideos, UserPhotos

## Quick Start

### 1. Using the Factory Method (Recommended)

```dart
import 'package:dharmlok_frontend/screens/user_profile/user_profile_details_screen.dart';

// For Dharmguru
Widget dharmguruScreen = UserProfileFactory.createDharmguruScreen({
  'id': '123',
  'name': 'Sri Ravishankar Ji',
  'religion': 'Hinduism',
  'profileImageUrl': 'https://example.com/profile.jpg',
});

// For Kathavachak
Widget kathavachakScreen = UserProfileFactory.createKathavachakScreen({
  'id': '456',
  'name': 'Pandit Ramesh Kumar',
  'religion': 'Hinduism',
  'profileImageUrl': 'https://example.com/profile.jpg',
});

// For Panditji
Widget panditjiScreen = UserProfileFactory.createPanditjiScreen({
  'id': '789',
  'name': 'Acharya Vishnu Das',
  'religion': 'Hinduism',
  'profileImageUrl': 'https://example.com/profile.jpg',
});

// Generic method with userType string
Widget genericScreen = UserProfileFactory.createScreen({
  'id': '123',
  'name': 'User Name',
  'religion': 'Hinduism',
}, 'dharmguru');
```

### 2. Direct Component Usage

```dart
import 'package:dharmlok_frontend/screens/user_profile/user_profile_details_screen.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';

Widget userProfileScreen = UserProfileDetailsScreen(
  userData: {
    'id': '123',
    'name': 'Sri Ravishankar Ji',
    'religion': 'Hinduism',
    'profileImageUrl': 'https://example.com/profile.jpg',
    'bannerImageUrl': 'https://example.com/banner.jpg',
  },
  userType: UserType.dharmguru,
);
```

## Navigation Examples

### 1. In Route Configuration

```dart
// main.dart
import 'package:dharmlok_frontend/screens/user_profile/user_profile_details_screen.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';

MaterialApp(
  routes: {
    '/dharmguru-details': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return UserProfileFactory.createDharmguruScreen(args['userData']);
    },
    '/kathavachak-details': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return UserProfileFactory.createKathavachakScreen(args['userData']);
    },
    '/user-profile': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return UserProfileFactory.createScreen(
        args['userData'], 
        args['userType']
      );
    },
  },
)
```

### 2. Navigation Calls

```dart
// Navigate to Dharmguru profile
Navigator.pushNamed(
  context, 
  '/dharmguru-details',
  arguments: {
    'userData': dharmguruData,
  },
);

// Navigate to generic user profile
Navigator.pushNamed(
  context, 
  '/user-profile',
  arguments: {
    'userData': userData,
    'userType': 'kathavachak',
  },
);

// Direct navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UserProfileFactory.createPanditjiScreen(userData),
  ),
);
```

## Individual Component Usage

### UserBio Component

```dart
import 'package:dharmlok_frontend/widgets/user_profile/user_bio.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';

UserBio(
  userId: '123',
  userType: UserType.dharmguru,
)
```

### UserPosts Component

```dart
import 'package:dharmlok_frontend/widgets/user_profile/user_posts.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';

UserPosts(
  userId: '123',
  userType: UserType.kathavachak,
)
```

### UserVideos Component

```dart
import 'package:dharmlok_frontend/widgets/user_profile/user_videos.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';

UserVideos(
  userId: '123',
  userType: UserType.panditji,
)
```

### UserPhotos Component

```dart
import 'package:dharmlok_frontend/widgets/user_profile/user_photos.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';

UserPhotos(
  userId: '123',
  userType: UserType.panditji,
)
```

## Custom Configuration

### Adding New User Type

1. **Update UserType enum in user_type_config.dart:**
```dart
enum UserType {
  dharmguru,
  kathavachak,
  panditji,
  newUserType, // Add new type
}
```

2. **Add configuration:**
```dart
case UserType.newUserType:
  return const UserTypeConfig(
    userType: UserType.newUserType,
    displayName: 'New User Type',
    apiEndpoint: 'newusertype',
    primaryColor: Color(0xFF123456),
    accentColor: Color(0xFF654321),
    bannerText: 'Custom banner text',
    tabLabels: ['Biography', 'Posts', 'Custom Tab', 'Photos'],
    apiPaths: {
      'posts': '/api/posts?userId={userId}&userType=newusertype',
      'user': '/api/users/{userId}',
      // ... other paths
    },
  );
```

3. **Create factory method:**
```dart
static Widget createNewUserTypeScreen(Map<String, dynamic> userData) {
  return UserProfileDetailsScreen(
    userData: userData,
    userType: UserType.newUserType,
  );
}
```

## API Service Usage

### Custom API Calls

```dart
import 'package:dharmlok_frontend/services/user_api_service.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';

// Create service for specific user type
final apiService = UserApiService.forUserType(UserType.dharmguru);

// Fetch user details
final user = await apiService.fetchUser('123');

// Fetch posts
final posts = await apiService.fetchPosts('123');

// Toggle like
final result = await apiService.toggleLike('post123', 'user456', false);
```

## Error Handling

All components include built-in error handling:

```dart
// Components automatically handle:
// - Loading states (CircularProgressIndicator)
// - Error states (retry buttons)
// - Empty states (appropriate messages)
// - Network errors (graceful fallbacks)
```

## Customization Options

### Theme Customization

Each user type has its own color scheme defined in UserTypeConfig:
- `primaryColor`: Main accent color
- `accentColor`: Secondary color
- Colors are automatically applied to tabs, buttons, and UI elements

### Tab Customization

Different user types can have different tabs:
- Dharmguru: Biography, Posts, Videos, Photos
- Kathavachak: Biography, Posts, Videos, Photos
- Panditji: Biography, Posts, Sermons, Photos

### API Endpoint Customization

Each user type can have different API endpoints while maintaining the same interface.

## Migration from Old Components

### Before (Dharmguru-specific)
```dart
DharmguruDetailsScreen(guru: guruData)
```

### After (Generic)
```dart
UserProfileFactory.createDharmguruScreen(guruData)
// or
UserProfileDetailsScreen(
  userData: guruData,
  userType: UserType.dharmguru,
)
```

## Testing

```dart
// Test different user types
testWidgets('Dharmguru profile loads correctly', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: UserProfileFactory.createDharmguruScreen(mockDharmguruData),
  ));
  
  expect(find.text('Biography'), findsOneWidget);
  expect(find.text('Posts'), findsOneWidget);
});

testWidgets('Kathavachak profile loads correctly', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: UserProfileFactory.createKathavachakScreen(mockKathavachakData),
  ));
  
  expect(find.text('Biography'), findsOneWidget);
  expect(find.text('Posts'), findsOneWidget);
});
```

This new architecture provides:
✅ **Reusability**: One component works for all user types
✅ **Maintainability**: Single source of truth for user profile logic
✅ **Scalability**: Easy to add new user types
✅ **Type Safety**: Strong typing with enums and models
✅ **Customization**: Different colors, tabs, and API endpoints per user type
✅ **Error Handling**: Built-in loading, error, and empty states