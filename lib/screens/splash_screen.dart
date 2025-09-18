import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Use UserService to check login status (it's already initialized in main.dart)
    final userService = UserService();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? religion = prefs.getString('selectedReligion');

    // Debug logging
    debugPrint('=== SESSION CHECK DEBUG ===');
    debugPrint('UserService.isLoggedIn: ${userService.isLoggedIn}');
    debugPrint('UserService.authToken: ${userService.authToken}');
    debugPrint('UserService.currentUserId: ${userService.currentUserId}');
    debugPrint('UserService.currentUserName: ${userService.currentUserName}');
    debugPrint('SharedPreferences authToken: $token');
    debugPrint('SharedPreferences religion: $religion');
    
    // Check both UserService and token for better reliability
    bool isLoggedIn = userService.isLoggedIn && token != null && token.isNotEmpty;
    debugPrint('Final isLoggedIn decision: $isLoggedIn');
    debugPrint('=== END SESSION CHECK ===');

    if (isLoggedIn) {
      // If user is logged in, go directly to home (skip religion selection)
      debugPrint('User is logged in, navigating to /home');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Clear any stale data if tokens don't match
      if (userService.isLoggedIn != (token != null && token.isNotEmpty)) {
        debugPrint('Clearing stale user data due to mismatch');
        await userService.clearUser();
        await prefs.remove('authToken');
        await prefs.remove('selectedReligion'); // Also clear religion selection
      }
      
      // Check if user has selected religion before (for first-time setup)
      if (religion != null && religion.isNotEmpty) {
        debugPrint('Religion previously selected, navigating to /sign-in');
        Navigator.pushReplacementNamed(context, '/sign-in');
      } else {
        debugPrint('First time user, navigating to /select-religion');
        Navigator.pushReplacementNamed(context, '/select-religion');
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F0), // off-white background
      body: Stack(
        children: [
          // Top right corner vector - Clockwise rotation
          const Positioned(
            top: 0,
            right: 0,
            child: RotatingImage(
              imagePath: 'assets/images/corner_vector.svg',
              width: 200,
              height: 200,
              clockwise: true,
              duration: Duration(seconds: 3),
              curve: Curves.easeOut,
              rotations: 1.0,
            ),
          ),
          // Bottom left corner vector - Counter-clockwise rotation
          const Positioned(
            bottom: 0,
            left: 0,
            child: RotatingImage(
              imagePath: 'assets/images/corner_vector.svg',
              width: 200,
              height: 200,
              clockwise: false,
              duration: Duration(seconds: 3),
              curve: Curves.easeOut,
              rotations: 1.0,
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

// Reusable rotation animation widget for easy customization
class RotatingImage extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final bool clockwise;
  final Duration duration;
  final Curve curve;
  final double rotations; // Number of full rotations (e.g., 1.0 = 360°, 0.5 = 180°)

  const RotatingImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.clockwise = true,
    this.duration = const Duration(seconds: 3),
    this.curve = Curves.easeOut,
    this.rotations = 1.0,
  });

  @override
  State<RotatingImage> createState() => _RotatingImageState();
}

class _RotatingImageState extends State<RotatingImage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final rotationAngle = _animation.value * widget.rotations * 2 * 3.14159;
        return Transform.rotate(
          angle: widget.clockwise ? rotationAngle : -rotationAngle,
          child: SvgPicture.asset(
            widget.imagePath,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}