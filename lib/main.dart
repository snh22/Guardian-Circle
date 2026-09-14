import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian_circle/core/theme/app_theme.dart';
import 'package:guardian_circle/features/shell/presentation/caregiver_shell.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GuardianCircleApp(),
    ),
  );
}

class GuardianCircleApp extends StatelessWidget {
  const GuardianCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Circle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const CaregiverShell(),
    );
  }
}