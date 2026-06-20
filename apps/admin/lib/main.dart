import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

void main() => runApp(const ProviderScope(child: AdminApp()));

/// Phase 3 skeleton (Flutter Web). Boots the shared design system.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task — Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Center(child: Text('Admin dashboard — Phase 3')),
      ),
    );
  }
}
