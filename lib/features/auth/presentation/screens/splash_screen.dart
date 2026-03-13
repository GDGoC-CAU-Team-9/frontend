import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 56, color: Colors.teal),
              SizedBox(height: 14),
              Text('SafePlate', style: AppDesign.logoTextStyle),
              SizedBox(height: 26),
              CircularProgressIndicator(color: Colors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
