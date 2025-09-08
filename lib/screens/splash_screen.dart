import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>{
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? religion = prefs.getString('selectedReligion');

    if (token != null && token.isNotEmpty) {
      if (religion != null && religion.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/select-religion');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/sign-in');
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F0), // off-white background
      body: Stack(
        children: [
          // Top right corner vector
          Positioned(
            top: -40,
            right: -40,
            child: Image.asset(
              'assets/images/corner_vector.png',
              width: 220,
              height: 220,
            ),
          ),
          // Bottom left corner vector
          Positioned(
            bottom: -40,
            left: -40,
            child: Transform.rotate(
              angle: 3.1416, // 180 degrees
              child: Image.asset(
                'assets/images/corner_vector.png',
                width: 220,
                height: 220,
              ),
            ),
          ),
          // Centered logo and subtitle
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  "assets/images/dharmlok_logo.svg",
                  height: 120,
                  width: 320,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const Text(
                  "एक धर्मार्थ संकल्प।",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8B6F4E), // brown shade
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}