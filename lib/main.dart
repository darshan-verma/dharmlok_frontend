import 'package:dharmlok_frontend/screens/select_religion_screen.dart';
import 'package:dharmlok_frontend/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
// import 'screens/home_screen.dart'; // create later

void main() {
  runApp(const DharmlokApp());
}

class DharmlokApp extends StatelessWidget {
  const DharmlokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dharmlok',
      theme: ThemeData(
        fontFamily: 'Poppins', // add your Figma font if used
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
  '/home': (context) => const HomeScreen(),
  '/select-religion': (context) => const SelectReligionScreen(),
  '/sign-in': (context) => const SignInScreen(),
  '/sign-up': (context) => const SignUpScreen(),
      },
    );
  }
}
