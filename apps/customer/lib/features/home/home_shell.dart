import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../assistant/ai_chat_screen.dart';

/// Bottom-nav shell. The four destinations (Home · My Jobs · Wallet · Profile)
/// sit in a frosted, floating pill that hovers over the content (Uber-style),
/// split around a raised AI-assistant button in the center.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const String homeRouteName = 'home';
  static const String homeRoutePath = '/home';
  static const String jobsRouteName = 'jobs';
  static const String jobsRoutePath = '/jobs';
  static const String walletRouteName = 'wallet';
  static const String walletRoutePath = '/wallet';
  static const String profileRouteName = 'profile';
  static const String profileRoutePath = '/profile';

  /// Space the floating bar occupies, so scroll content can clear it.
  static const double barClearance = 112;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _goBranch,
              onAi: () => context.push(AiChatScreen.routePath),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAi,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, bottomInset + AppSpacing.md),
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            // Frosted floating pill.
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2130).withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      _navItem(0, Icons.home_outlined, Icons.home_rounded,
                          'Home'),
                      _navItem(1, Icons.handyman_outlined,
                          Icons.handyman_rounded, 'My Jobs'),
                      const Spacer(), // gap for the raised AI button
                      _navItem(2, Icons.account_balance_wallet_outlined,
                          Icons.account_balance_wallet_rounded, 'Wallet'),
                      _navItem(3, Icons.person_outline_rounded,
                          Icons.person_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
            // Raised center AI button.
            Positioned(
              top: -14,
              child: _AiButton(onTap: onAi),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool active = index == currentIndex;
    return Expanded(
      child: InkResponse(
        onTap: () => onTap(index),
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(active ? activeIcon : icon,
                size: 24,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.75)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.75),
                )),
          ],
        ),
      ),
    );
  }
}

/// The raised, glowing AI-assistant action that overlaps the top of the bar.
class _AiButton extends StatelessWidget {
  const _AiButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask the AI assistant',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ),
            border: Border.all(color: AppColors.background, width: 4),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.55),
                blurRadius: 22,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
