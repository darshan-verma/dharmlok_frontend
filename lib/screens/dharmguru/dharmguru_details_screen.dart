import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dharmlok_frontend/screens/dharmguru/dharmguru_bio.dart';
import 'package:dharmlok_frontend/screens/dharmguru/dharmguru_posts.dart';

class DharmguruDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> guru;
  DharmguruDetailsScreen({Key? key, required this.guru}) : super(key: key);

  @override
  State<DharmguruDetailsScreen> createState() => _DharmguruDetailsScreenState();
}

class _DharmguruDetailsScreenState extends State<DharmguruDetailsScreen> with SingleTickerProviderStateMixin {
  String? bannerImageUrl;
  bool isLoading = true;
  String? error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchBannerImageUrl();
  }

  Future<void> fetchBannerImageUrl() async {
    final guruId = widget.guru['id'];
    print('Selected guruId: $guruId');
    try {
      final response = await http.get(Uri.parse('https://darshan-dharmlok.vercel.app/api/users/$guruId'));
      if (response.statusCode == 200) {
        final guruData = json.decode(response.body);
        print('API response: $guruData');
        setState(() {
          // Check for different possible banner image field names
          bannerImageUrl = guruData['bannerImageUrl'] ?? 
                          guruData['imageUrl'] ?? 
                          guruData['coverImageUrl'];
          isLoading = false;
        });
        print('Fetched bannerImageUrl: $bannerImageUrl');
      } else {
        setState(() {
          error = 'Failed to load user';
          isLoading = false;
        });
      }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        body: Center(child: Text(error!)),
      );
    }
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
          widget.guru["name"] ?? 'Dharmguru Details',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner with overlay text
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: bannerImageUrl != null && bannerImageUrl!.isNotEmpty
                      ? Image.network(
                          bannerImageUrl!,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/dharmguru.png',
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
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
                    child: const Text(
                      'कौन हैं श्री रविशंकर जी महाराज',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Guru profile section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: widget.guru["profileImageUrl"] != null && widget.guru["profileImageUrl"].toString().isNotEmpty
                        ? NetworkImage(widget.guru["profileImageUrl"])
                        : const AssetImage('assets/images/dharmguru.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.guru["name"] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.guru["religion"] ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFED7B30)),
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
                indicatorColor: const Color(0xFFED7B30),
                labelColor: const Color(0xFFED7B30),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Biography'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Photos'),
                ],
              ),
            ),
            SizedBox(
              height: 900, // Fixed height for TabBarView
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Biography Tab
                  DharmguruBio(guruId: widget.guru['id']),
                  // Posts Tab
                  DharmguruPosts(guruId: widget.guru['id']),
                  // Videos Tab
                  Center(child: Text('Videos', style: TextStyle(fontSize: 16))),
                  // Photos Tab
                  Center(child: Text('Photos', style: TextStyle(fontSize: 16))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

