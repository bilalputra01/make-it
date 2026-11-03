import 'package:flutter/material.dart';
import 'screens/task_home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MakeItApp());
}

class MakeItApp extends StatelessWidget {
  const MakeItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Make it',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const TaskHomeScreen(),
    );
  }
}
