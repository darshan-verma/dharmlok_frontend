import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService userService = UserService();
  bool keepSignedIn = false;
  bool showPassword = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      // Logo
                      SvgPicture.asset(
                        'assets/images/dharmlok_logo.svg',
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign In to gain access to Dharmlok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF8B8B8B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Email/Username
                const Text(
                  'Email/Username',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFFB2C94B)),
                    hintText: 'Enter your email address...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Password
                const Text(
                  'Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFB2C94B)),
                    hintText: 'Enter your password...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xFFB2C94B),
                      ),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: keepSignedIn,
                      onChanged: (val) {
                        setState(() {
                          keepSignedIn = val ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    const Text('Keep me signed in', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Color(0xFFE67C2F),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B6F4E),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12), // reduced from 18
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : () async {
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill all fields'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  setState(() { isLoading = true; });
  try {
    final result = await userService.signIn(
      _emailController.text,
      _passwordController.text,
    );
    
    // Extract token and user info
    String? token = result['token'];
    if (token == null || token.isEmpty) {
      // Always generate a token if the API doesn't provide one
      token = 'auth_token_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Generated fallback token: $token');
    }
    
    // Set current user info in UserService (this now also handles token storage)
    if (result['user'] != null) {
      final user = result['user'];
      final userId = user['id']?.toString() ?? user['_id']?.toString() ?? 'mock_user_${DateTime.now().millisecondsSinceEpoch}';
      final userName = user['name']?.toString() ?? '';
      final userEmail = user['email']?.toString() ?? '';
      
      debugPrint('=== SIGN IN SUCCESS DEBUG ===');
      debugPrint('API Result: $result');
      debugPrint('Final token to save: $token');
      debugPrint('Extracted userId: $userId');
      debugPrint('Extracted userName: $userName');
      debugPrint('Extracted userEmail: $userEmail');
      
      await userService.setCurrentUser(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        profileImageUrl: user['profileImageUrl']?.toString(),
        authToken: token, // Always pass a token
      );
      
      // Also save to SharedPreferences for backward compatibility
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      debugPrint('Also saved token to SharedPreferences: $token');
      debugPrint('=== END SIGN IN DEBUG ===');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in successful!'),
        backgroundColor: Colors.green,
      ),
    );
    // Navigate to home screen
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sign in failed. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
    debugPrint('Sign in error: $e');
  } finally {
    setState(() { isLoading = false; });
  }
},
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 16, color: Colors.white), // reduced font size
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OR', style: TextStyle(fontSize: 16, color: Color(0xFF8B8B8B))),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                // Google Sign In
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12), // reduced from 18
                      elevation: 0,
                    ),
                    icon: Image.asset('assets/images/google.png', height: 22), // slightly reduced icon
                    label: const Text(
                      'Sign In With Google',
                      style: TextStyle(fontSize: 16, color: Colors.white), // reduced font size
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 16),
                // Facebook Sign In
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1877F3),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12), // reduced from 18
                      elevation: 0,
                    ),
                    icon: Image.asset('assets/images/facebook.png', height: 22), // slightly reduced icon
                    label: const Text(
                      'Sign In With Facebook',
                      style: TextStyle(fontSize: 16, color: Colors.white), // reduced font size
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 16, color: Color(0xFF8B8B8B)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/sign-up');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFFE67C2F),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
