import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

void main() => runApp(const ProviderScope(child: TechnicianApp()));

/// Phase 2 skeleton. Boots the shared design system to confirm wiring.
class TechnicianApp extends StatelessWidget {
  const TechnicianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task — Technician',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Center(child: Text('Technician app — Phase 2')),
      ),
    );
  }
}
