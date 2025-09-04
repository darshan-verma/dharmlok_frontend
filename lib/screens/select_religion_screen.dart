import 'package:flutter/material.dart';

class SelectReligionScreen extends StatelessWidget {
  const SelectReligionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Select Your Religion',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4F36),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select the following options to your religion.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8B8B8B),
                ),
              ),
              const SizedBox(height: 32),
              ReligionOption(title: 'Sanatan', iconPath: 'assets/images/om.png', onTap: () {
                Navigator.pushNamed(context, '/sign-in');
              }),
              const SizedBox(height: 16),
              ReligionOption(title: 'Buddhism', iconPath: 'assets/images/buddhism.png', onTap: () {
                Navigator.pushNamed(context, '/sign-in');
              }),
              const SizedBox(height: 16),
              ReligionOption(title: 'Sikh', iconPath: 'assets/images/sikh-symbol.png', onTap: () {
                Navigator.pushNamed(context, '/sign-in');
              }),
              const SizedBox(height: 16),
              ReligionOption(title: 'Jain', iconPath: 'assets/images/jainism.png', onTap: () {
                Navigator.pushNamed(context, '/sign-in');
              }),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/sign-in');
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4B4B4B),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B6F4E),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/sign-in');
                    },
                    icon: const SizedBox.shrink(),
                    label: Row(
                      children: const [
                        Text(
                          'Next',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReligionOption extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;
  const ReligionOption({required this.title, required this.iconPath, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFFE6F2D5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(iconPath),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFFBDBDBD), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
