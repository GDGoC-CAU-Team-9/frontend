import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/custom_button.dart';
import 'shared/widgets/custom_text_field.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePlate',
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SafePlate',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Safe dining for everyone.'),
                SizedBox(height: 32),
                SafePlateTextField(
                  label: 'Test Input',
                  hint: 'Type something...',
                ),
                SizedBox(height: 16),
                SafePlateButton(text: 'Get Started', onPressed: _dummyAction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _dummyAction() {}
