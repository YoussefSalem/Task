import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// Foundation landing screen. Proves the design system, theming, and RTL
/// before feature work begins. Replaced by the auth flow in the next phase.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String routeName = 'welcome';
  static const String routePath = '/';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 88,
                width: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: AppColors.textPrimary, size: 44),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Task',
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'خدمات منزلية عند الطلب', // "On-demand home services"
                textAlign: TextAlign.center,
                style: textTheme.titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: () {},
                child: const Text('ابدأ الآن'), // "Get started"
              ),
            ],
          ),
        ),
      ),
    );
  }
}
