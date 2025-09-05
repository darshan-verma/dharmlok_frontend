import 'package:dharmlok_frontend/screens/select_religion_screen.dart';
import 'package:dharmlok_frontend/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'screens/home_screen.dart'; // create later

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }
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
