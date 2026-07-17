import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../../app/tech_colors.dart';
import '../chat/chat_providers.dart';
import '../notifications/notification_providers.dart';
import '../profile/technician_profile.dart';

/// Bottom-nav shell for the four top-level destinations: Dashboard · Jobs ·
/// Messages · Earnings. A frosted floating bar (sibling of the customer app's)
/// carries the availability status as a live dot on the Dashboard tab, so a pro
/// always knows whether they're taking work — no center assistant button here;
/// the tool is the job board.
class TechShell extends StatelessWidget {
  const TechShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const String dashboardRouteName = 'dashboard';
  static const String dashboardRoutePath = '/dashboard';
  static const String jobsRouteName = 'jobs-feed';
  static const String jobsRoutePath = '/jobs-feed';
  static const String messagesRouteName = 'messages';
  static const String messagesRoutePath = '/messages';
  static const String earningsRouteName = 'earnings';
  static const String earningsRoutePath = '/earnings';

  /// Space the floating bar occupies, so scroll content can clear it.
  static const double barClearance = 104;

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
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends ConsumerWidget {
  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final bool online =
        ref.watch(techProfileProvider).valueOrNull?.available ?? false;
    final bool newAssignment = ref.watch(hasNewAssignmentProvider);
    final bool unreadMessages = ref.watch(unreadThreadsProvider) > 0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl,
          bottomInset + AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF16201F).withValues(alpha: 0.86)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? const Color(0x22FFFFFF) : const Color(0x14000000),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                _NavItem(
                  index: 0,
                  active: currentIndex == 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  dotColor: online ? TechColors.online : TechColors.offline,
                  onTap: onTap,
                ),
                _NavItem(
                  index: 1,
                  active: currentIndex == 1,
                  icon: Icons.work_outline_rounded,
                  activeIcon: Icons.work_rounded,
                  label: 'Jobs',
                  // Red dot on a new job assignment (customer just hired us).
                  dotColor: newAssignment ? AppColors.error : null,
                  onTap: onTap,
                ),
                _NavItem(
                  index: 2,
                  active: currentIndex == 2,
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  // Red dot on unread messages.
                  dotColor: unreadMessages ? AppColors.error : null,
                  onTap: onTap,
                ),
                _NavItem(
                  index: 3,
                  active: currentIndex == 3,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Earnings',
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.index,
    required this.active,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.dotColor,
  });

  final int index;
  final bool active;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  /// A small dot painted over the icon — availability status (Dashboard) or a
  /// red notification indicator (new message / new assignment).
  final Color? dotColor;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color inactive = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.7)
        : AppColors.textSecondaryLight;
    final Color color = widget.active ? scheme.primary : inactive;

    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.active,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            setState(() => _pressed = false);
            widget.onTap(widget.index);
          },
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        widget.active ? widget.activeIcon : widget.icon,
                        key: ValueKey<bool>(widget.active),
                        size: 24,
                        color: color,
                      ),
                    ),
                    if (widget.dotColor != null)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          height: 9,
                          width: 9,
                          decoration: BoxDecoration(
                            color: widget.dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                        widget.active ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
