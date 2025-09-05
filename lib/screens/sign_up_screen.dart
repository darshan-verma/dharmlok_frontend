import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final UserService userService = UserService();
  bool showPassword = false;
  bool showConfirm = false;

  String get passwordStrength {
    final password = _passwordController.text;
    if (password.length > 10 && RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password)) {
      return 'Amazing!';
    } else if (password.length > 6) {
      return 'Good';
    } else if (password.isNotEmpty) {
      return 'Weak';
    }
    return '';
  }

  double get passwordStrengthValue {
    final password = _passwordController.text;
    if (password.length > 10 && RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password)) {
      return 1.0;
    } else if (password.length > 6) {
      return 0.7;
    } else if (password.isNotEmpty) {
      return 0.4;
    }
    return 0.0;
  }

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
                      SvgPicture.asset(
                        'assets/images/dharmlok_logo.svg',
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign up to gain access to Dharmlok',
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
                // Name
                const Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFFB2C94B)),
                    hintText: 'Name',
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
                // Email
                const Text(
                  'Email Address',
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
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFB2C94B)),
                    hintText: 'elementary221b@gmail.com',
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
                // Phone
                const Text(
                  'Phone number',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFFB2C94B)),
                    hintText: '+91 98769543210',
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
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFB2C94B)),
                    hintText: '********************',
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
                // Password strength bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: passwordStrengthValue,
                        minHeight: 4,
                        backgroundColor: Colors.grey[300],
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            passwordStrength.isNotEmpty
                                ? 'Password strength: $passwordStrength'
                                : '',
                            style: const TextStyle(
                              color: Color(0xFF8B8B8B),
                              fontSize: 16,
                            ),
                          ),
                          if (passwordStrength == 'Amazing!')
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.star, color: Colors.green, size: 20),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Confirm Password
                const Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  obscureText: !showConfirm,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFB2C94B)),
                    hintText: '********************',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirm ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xFFB2C94B),
                      ),
                      onPressed: () {
                        setState(() {
                          showConfirm = !showConfirm;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B6F4E),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12), // reduced from 16
                      elevation: 0,
                    ),
                    onPressed: () async {
                      // Validate inputs
                      if (_nameController.text.isEmpty ||
                          _emailController.text.isEmpty ||
                          _phoneController.text.isEmpty ||
                          _passwordController.text.isEmpty ||
                          _confirmController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_passwordController.text != _confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        await userService.signUp(
                          _nameController.text,
                          _emailController.text,
                          _phoneController.text,
                          _passwordController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account created successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pushReplacementNamed(context, '/sign-in');
                      } catch (e) {
                        // Handle error - show user-friendly message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sign up failed. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        // For debugging, you can use debugPrint which is removed in release builds
                        debugPrint('Sign up error: $e');
                      }
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16, color: Colors.white), // reduced font size
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "I already have an account? ",
                        style: TextStyle(fontSize: 16, color: Color(0xFF8B8B8B)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/sign-in');
                        },
                        child: const Text(
                          'Login',
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
              ],
              
            ),
          ),
        ),
      ),
    );
  }
}
