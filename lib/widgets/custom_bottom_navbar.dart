import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFE67C2F),
      unselectedItemColor: const Color(0xFF8B8B8B),
      currentIndex: selectedIndex,
      onTap: (index) {
        onTabSelected(index);
        
        // Use pushNamedAndRemoveUntil to clear the stack and ensure bottom navbar persists
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else if (index == 1) {
          Navigator.pushNamedAndRemoveUntil(context, '/events', (route) => false);
        } else if (index == 2) {
          Navigator.pushNamedAndRemoveUntil(context, '/dharmguru', (route) => false);
        } else if (index == 3) {
          Navigator.pushNamedAndRemoveUntil(context, '/community', (route) => false);
        } else if (index == 4) {
          Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Event Booking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_pin),
          label: 'Dharmguru',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
