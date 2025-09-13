import 'package:flutter/material.dart';
import 'package:dharmlok_frontend/widgets/custom_bottom_navbar.dart';

class EventBookingScreen extends StatefulWidget {
  @override
  _EventBookingScreenState createState() => _EventBookingScreenState();
}

class _EventBookingScreenState extends State<EventBookingScreen> {
  int _selectedIndex = 1; // Event Booking is at index 1 in the navigation bar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Event Booking',
          style: TextStyle(
            color: Color(0xFF8B5C2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Event Booking Screen',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B5C2D),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onItemTapped,
      ),
    );
  }
}
