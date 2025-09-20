import 'package:flutter/material.dart';
import '../../services/user_api_service.dart';
import '../../config/user_type_config.dart';
import '../../models/user_models.dart';
import '../../widgets/user_profile/user_bio.dart';
import '../../widgets/user_profile/user_posts.dart';
import '../../widgets/user_profile/user_videos.dart';
import '../../widgets/user_profile/user_photos.dart';

class UserProfileDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final UserType userType;
  
  const UserProfileDetailsScreen({
    Key? key, 
    required this.userData,
    required this.userType,
  }) : super(key: key);

  @override
  State<UserProfileDetailsScreen> createState() => _UserProfileDetailsScreenState();
}

class _UserProfileDetailsScreenState extends State<UserProfileDetailsScreen> with SingleTickerProviderStateMixin {
  User? userDetails;
  bool isLoading = true;
  String? error;
  late TabController _tabController;
  late UserTypeConfig config;
  late UserApiService apiService;

  @override
  void initState() {
    super.initState();
    config = UserTypeConfig.getConfig(widget.userType);
    apiService = UserApiService.forUserType(widget.userType);
    _tabController = TabController(length: config.tabLabels.length, vsync: this);
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final userId = widget.userData['id']?.toString() ?? '';
    
    try {
      final user = await apiService.fetchUser(userId);
      setState(() {
        userDetails = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading user details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  fetchUserDetails();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Use userDetails if available, otherwise fall back to widget.userData
    final user = userDetails ?? User.fromJson(widget.userData, widget.userType);
    final userId = user.id;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          user.name.isNotEmpty ? user.name : '${config.displayName} Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with overlay text
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: user.bannerImageUrl != null && user.bannerImageUrl!.isNotEmpty
                    ? Image.network(
                        user.bannerImageUrl!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultBanner();
                        },
                      )
                    : _buildDefaultBanner(),
              ),
              Positioned(
                left: 16,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    config.bannerText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // User profile section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                      ? Icon(Icons.person, size: 32, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.religion ?? config.displayName,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person_add_alt_1, color: config.primaryColor),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: config.primaryColor,
              labelColor: config.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              isScrollable: config.tabLabels.length > 3,
              tabs: config.tabLabels.map((label) => Tab(text: label)).toList(),
            ),
          ),
          
          // Tab content - Expanded allows proper scrolling
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabContent(userId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.primaryColor.withOpacity(0.8),
            config.accentColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 48,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  List<Widget> _buildTabContent(String userId) {
    List<Widget> tabs = [];
    
    for (int i = 0; i < config.tabLabels.length; i++) {
      final tabLabel = config.tabLabels[i];
      
      switch (tabLabel.toLowerCase()) {
        case 'biography':
        case 'bio':
          tabs.add(UserBio(userId: userId, userType: widget.userType));
          break;
          
        case 'posts':
          tabs.add(UserPosts(userId: userId, userType: widget.userType));
          break;
          
        case 'videos':
        case 'sermons':
        case 'devotions':
          tabs.add(UserVideos(userId: userId, userType: widget.userType));
          break;
          
        case 'photos':
          tabs.add(UserPhotos(userId: userId, userType: widget.userType));
          break;
          
        default:
          // Default fallback for unknown tab types
          tabs.add(Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '$tabLabel content coming soon!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ));
      }
    }
    
    return tabs;
  }
}

// Factory method to create the screen with different user types
class UserProfileFactory {
  static Widget createDharmguruScreen(Map<String, dynamic> userData) {
    return UserProfileDetailsScreen(
      userData: userData,
      userType: UserType.dharmguru,
    );
  }

  static Widget createKathavachakScreen(Map<String, dynamic> userData) {
    return UserProfileDetailsScreen(
      userData: userData,
      userType: UserType.kathavachak,
    );
  }

  static Widget createPanditjiScreen(Map<String, dynamic> userData) {
    return UserProfileDetailsScreen(
      userData: userData,
      userType: UserType.panditji,
    );
  }

  static Widget createScreen(Map<String, dynamic> userData, String userTypeString) {
    final userType = UserTypeConfig.userTypeFromString(userTypeString);
    return UserProfileDetailsScreen(
      userData: userData,
      userType: userType,
    );
  }
}