import 'package:flutter/material.dart';
import 'package:dharmlok_frontend/widgets/custom_bottom_navbar.dart';
import 'package:dharmlok_frontend/config/user_type_config.dart';
import 'package:dharmlok_frontend/models/user_models.dart';
import 'package:dharmlok_frontend/services/user_api_service.dart';
import 'package:dharmlok_frontend/screens/user_profile/user_profile_details_screen.dart';

class UserListScreen extends StatefulWidget {
  final UserType userType;
  
  const UserListScreen({
    Key? key,
    required this.userType,
  }) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> users = [];
  bool isLoading = true;
  String? error;
  late UserApiService _apiService;
  late UserTypeConfig _config;

  final List<String> religions = [
    "Sanatan",
    "Jain",
    "Buddhist",
    "Sikh",
  ];

  @override
  void initState() {
    super.initState();
    _apiService = UserApiService.forUserType(widget.userType);
    _config = UserTypeConfig.getConfig(widget.userType);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedUsers = await _apiService.fetchUsers();
      
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching ${_config.displayName}s: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) return '';
    
    List<String> parts = [];
    if (address['city'] != null) parts.add(address['city']);
    if (address['state'] != null) parts.add(address['state']);
    if (address['country'] != null) parts.add(address['country']);
    return parts.join(', ');
  }

  int get _selectedIndex {
    // Return appropriate bottom nav index based on user type
    switch (widget.userType) {
      case UserType.dharmguru:
        return 2; // Assuming dharmguru is at index 2
      default:
        return 0;
    }
  }

  void _onItemTapped(int index) {
    // Handle bottom navigation
    // This could be improved to handle navigation properly
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: _config.primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _config.displayName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _config.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // To balance the back button
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading ${_config.displayName}s',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    // Religion filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: religions.map((religion) {
                          final isSelected = religion == "Sanatan";
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: ChoiceChip(
                              label: Text(
                                religion,
                                style: TextStyle(
                                  color: isSelected
                                      ? _config.accentColor
                                      : _config.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: _config.lightBackgroundColor,
                              backgroundColor: const Color(0xFFF7F3F0),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isSelected
                                      ? _config.accentColor
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              onSelected: (_) {
                                // Handle religion filter
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Users list
                    Expanded(
                      child: users.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No ${_config.displayName}s found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchUsers,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: users.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return _buildUserCard(user);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onItemTapped,
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          user.profileImageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/dharmguru.png',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/dharmguru.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Color(0xFF2B1E0A),
                        ),
                      ),
                      if (user.addresses.isNotEmpty)
                        Text(
                          _formatAddress(user.addresses.first),
                          style: TextStyle(
                            fontSize: 14,
                            color: _config.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileDetailsScreen(
                          userData: {
                            'id': user.id,
                            'name': user.name,
                            'profileImageUrl': user.profileImageUrl,
                            'bannerImageUrl': user.bannerImageUrl,
                            'addresses': user.addresses,
                          },
                          userType: widget.userType,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View Details",
                        style: TextStyle(
                          color: _config.accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: _config.accentColor,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Banner image
            if (user.bannerImageUrl != null && user.bannerImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  user.bannerImageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}