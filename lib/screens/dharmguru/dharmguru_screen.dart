import 'package:dharmlok_frontend/screens/dharmguru/dharmguru_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:dharmlok_frontend/widgets/custom_bottom_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DharmguruScreen extends StatefulWidget {
  @override
  _DharmguruScreenState createState() => _DharmguruScreenState();
}

class _DharmguruScreenState extends State<DharmguruScreen> {
  List<dynamic> gurus = [];
  bool isLoading = true;
  String? error;

  final List<String> religions = [
    "Sanatan",
    "Jain",
    "Buddhist",
    "Sikh",
  ];

  Future<void> fetchDharmgurus() async {
  try {
    // Try the users endpoint with userType filter
    final response = await http.get(
      Uri.parse('https://darshan-dharmlok.vercel.app/api/users?userType=Dharmguru'),
    );
    
    print('Dharmguru API Status: ${response.statusCode}');
    print('Dharmguru API Response: ${response.body}');
    
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Adjust this depending on your API response structure
      List<dynamic> dharmgurus;
      if (decoded is Map && decoded.containsKey('users')) {
        dharmgurus = decoded['users'];
      } else if (decoded is Map && decoded.containsKey('dharmgurus')) {
        dharmgurus = decoded['dharmgurus'];
      } else if (decoded is List) {
        dharmgurus = decoded;
      } else {
        dharmgurus = [];
      }
      
      print('Parsed ${dharmgurus.length} dharmgurus');
      
      setState(() {
        gurus = dharmgurus;
        isLoading = false;
      });
    } else {
      setState(() {
        error = 'Failed to load dharmgurus: ${response.statusCode} - ${response.body}';
        isLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching dharmgurus: $e');
    setState(() {
      error = e.toString();
      isLoading = false;
    });
  }
}
  

  int _selectedIndex =
      2; // Dharmguru is at index 2 in the updated navigation bar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _formatAddress(Map<String, dynamic> address) {
    List<String> parts = [];
    if (address['city'] != null) parts.add(address['city']);
    if (address['state'] != null) parts.add(address['state']);
    if (address['country'] != null) parts.add(address['country']);
    return parts.join(', ');
  }

  @override
  void initState() {
    super.initState();
    fetchDharmgurus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF8B5C2D)),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "Dharmguru",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B5C2D),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 48), // To balance the back button
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : Column(
              children: [
                SizedBox(height: 16),
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
                                  ? Color(0xFFFFA54F)
                                  : Color(0xFF8B5C2D),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Color(0xFFFFF3E3),
                          backgroundColor: Color(0xFFF7F3F0),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? Color(0xFFFFA54F)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          onSelected: (_) {},
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: gurus.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final guru = gurus[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFEDEDED)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: guru["profileImageUrl"] != null && guru["profileImageUrl"].toString().isNotEmpty
                                        ? Image.network(
                                            guru["profileImageUrl"],
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/dharmguru.png',
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          guru["name"] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                            color: Color(0xFF2B1E0A),
                                          ),
                                        ),
                                        if (guru["addresses"] != null && (guru["addresses"] as List).isNotEmpty)
                                          Text(
                                            _formatAddress(guru["addresses"][0]),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF8B5C2D),
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
                                            builder: (context) => DharmguruDetailsScreen(guru: guru),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "View Details",
                                            style: TextStyle(
                                              color: Color(0xFFFFA54F),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Color(0xFFFFA54F),
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (guru["bannerImageUrl"] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    guru["bannerImageUrl"],
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
}
