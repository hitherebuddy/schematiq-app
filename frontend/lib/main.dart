import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/screens/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SchematIQApp(),
    ),
  );
}

class SchematIQApp extends StatelessWidget {
  const SchematIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}