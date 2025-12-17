import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

class HereMapApp extends StatelessWidget {
  const HereMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HERE Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
