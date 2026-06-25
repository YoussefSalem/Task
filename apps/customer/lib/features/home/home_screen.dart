import 'dart:async';

import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../assistant/ai_chat_screen.dart';
import '../location/location_provider.dart';
import '../location/pick_location_screen.dart';
import '../matching/matching_screen.dart';
import '../offers/offers_screen.dart';
import 'active_job_card.dart';
import 'home_shell.dart';
import '../marketplace/all_services_screen.dart';
import '../marketplace/job_create_stub_screen.dart';
import '../marketplace/marketplace_providers.dart';
import '../profile/user_profile.dart';
import '../services/category_l10n.dart';
import '../services/technician_catalog.dart';

/// Home dashboard. The hero is the AI request flow - describe a problem, set
/// your own price - which is what makes Task different from a plain services
/// directory. Trust stats, a services grid and a top-rated pro carousel
/// support it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<JobCategory> _gridOrder = <JobCategory>[
    JobCategory.plumbing, JobCategory.electrical, JobCategory.ac,
    JobCategory.cleaning, JobCategory.carpentry, JobCategory.painting,
    JobCategory.satelliteInstallation, JobCategory.smartHome,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;

    // One-shot browser geolocation on first entry — defaults the active
    // location to where the user is; they can change it via the location bar.
    ref.watch(locationBootstrapProvider);

    void startCategory(JobCategory c) {
      ref.read(jobDraftProvider.notifier).startCategory(c);
      context.push(JobCreateStubScreen.routePath);
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.13),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, _kBarClearance),
            children: <Widget>[
              _TopBar(text: text),
              const SizedBox(height: AppSpacing.md),
              const _LocationBar(),
              const SizedBox(height: AppSpacing.md),
              const ActiveJobCard(),
              const _ActiveSearchCard(),
              const SizedBox(height: AppSpacing.xl),
              _AskAiHero(
                onTap: () => context.push(AiChatScreen.routePath),
                onSubmit: (msg) => context.push(AiChatScreen.routePath, extra: msg),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _HeroBannerCarousel(),
              const SizedBox(height: AppSpacing.lg),
              const _TrustStrip(),
              const SizedBox(height: AppSpacing.xxl),
              _PopularServices(onTap: startCategory),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: AppLocalizations.of(context).services,
                actionLabel: AppLocalizations.of(context).browseAll,
                onAction: () => context.push(AllServicesScreen.routePath),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CategoryGrid(order: _gridOrder, onTap: startCategory),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: AppLocalizations.of(context).topRatedNearYou),
              const SizedBox(height: AppSpacing.lg),
              _TopProsCarousel(
                onTap: (Technician t) => startCategory(t.category),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

/// Bottom padding so list content clears the floating nav bar. Mirrors
/// HomeShell.barClearance without importing the shell.
const double _kBarClearance = 120;

// ─────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.text});
  final TextTheme text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    // Firestore-backed profile streams live (the Auth displayName stream does
    // not re-emit on profile updates), so a freshly-saved name shows at once.
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final String first = (profile?.firstName ?? '').trim();
    final String displayName = first.isNotEmpty ? first : l.demoUserName;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(l.helloUsername(displayName),
              style: text.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        _CircleButton(
          icon: Icons.notifications_none_rounded,
          label: l.notifications,
          showDot: true,
          onTap: () {},
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () => context.go(HomeShell.profileRoutePath),
          child: Semantics(
            label: l.yourProfile,
            button: true,
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: _Avatar(seed: 'ahmed-user', initials: l.demoUserName.substring(0, 1)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.6)
            : const Color(0xFFF0EEFF),
        shape: CircleBorder(
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.09)
                : const Color(0x14000000),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 46,
            width: 46,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(icon,
                    size: 22,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight),
                if (showDot)
                  Positioned(
                    top: 12,
                    right: 13,
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.background
                              : AppColors.backgroundLight,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Location bar
// ─────────────────────────────────────────────────────────────────────────

class _LocationBar extends ConsumerWidget {
  const _LocationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);
    final text = Theme.of(context).textTheme;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary =
        isDark ? AppColors.textSecondary.withValues(alpha: 0.6) : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: () => context.push(PickLocationScreen.routePath),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface.withValues(alpha: 0.45) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0x12000000),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(AppLocalizations.of(context).serviceAt,
                      style: text.labelSmall?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      )),
                  const SizedBox(height: 1),
                  Text(loc.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: secondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Signature: the AI "describe your problem" hero
// ─────────────────────────────────────────────────────────────────────────

class _AskAiHero extends StatelessWidget {
  const _AskAiHero({required this.onTap, required this.onSubmit});
  final VoidCallback onTap;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.describeYourProblemToAi,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 6),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 32,
              spreadRadius: -10,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF6D28D9), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -18,
                bottom: -24,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 150, color: Colors.white.withValues(alpha: 0.10)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l.aiAssistant,
                                  style: text.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  )),
                              const Spacer(),
                              _PriceTag(text: text),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(l.whatNeedsFixing,
                              style: text.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              )),
                          const SizedBox(height: 6),
                          Text(
                            l.describeItInYourWords,
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FauxInput(text: text, onSubmit: onSubmit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "You set the price" badge on the hero.
class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.text});
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.sell_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(AppLocalizations.of(context).youSetThePrice,
              style: text.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

class _FauxInput extends StatefulWidget {
  const _FauxInput({required this.text, required this.onSubmit});
  final TextTheme text;
  final ValueChanged<String> onSubmit;

  @override
  State<_FauxInput> createState() => _FauxInputState();
}

class _FauxInputState extends State<_FauxInput>
    with SingleTickerProviderStateMixin {
  List<String> _examples = const <String>[''];
  int _i = 0;
  int _charCount = 0;
  Timer? _typeTimer;
  Timer? _cycleTimer;
  bool _reduceMotion = false;
  bool _focused = false;
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final hasFocus = _focus.hasFocus;
    if (hasFocus == _focused) return;
    setState(() => _focused = hasFocus);
    if (hasFocus) {
      _typeTimer?.cancel();
      _cycleTimer?.cancel();
    } else if (_ctrl.text.isEmpty && !_reduceMotion) {
      _charCount = _examples[_i].length;
      _startCycle();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppLocalizations l = AppLocalizations.of(context);
    _examples = <String>[
      l.myAcIsLeakingWater,
      l.powerKeepsTripping,
      l.needDeepCleanWeekend,
      l.kitchenSinkIsBlocked,
    ];
    if (_i >= _examples.length) _i = 0;
    _reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!_focused) {
      _typeTimer?.cancel();
      _cycleTimer?.cancel();
      if (!_reduceMotion) {
        _charCount = _examples[_i].length;
        _startCycle();
      }
    }
  }

  void _startCycle() {
    _cycleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _focused) return;
      _eraseAndType();
    });
  }

  void _eraseAndType() {
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 24), (_) {
      if (!mounted || _focused) return;
      if (_charCount > 0) {
        setState(() => _charCount--);
      } else {
        _typeTimer?.cancel();
        _i = (_i + 1) % _examples.length;
        _typeTimer = Timer.periodic(const Duration(milliseconds: 38), (_) {
          if (!mounted || _focused) return;
          if (_charCount < _examples[_i].length) {
            setState(() => _charCount++);
          } else {
            _typeTimer?.cancel();
            _startCycle();
          }
        });
      }
    });
  }

  void _submit() {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
    _ctrl.clear();
    _focus.unfocus();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cycleTimer?.cancel();
    _ctrl.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String placeholder = _reduceMotion
        ? _examples[_i]
        : _examples[_i].substring(0, _charCount);
    final bool showTypewriter = !_focused && _ctrl.text.isEmpty;

    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  style: widget.text.bodyMedium?.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: showTypewriter ? '' : AppLocalizations.of(context).describeYourProblem,
                    hintStyle: widget.text.bodyMedium?.copyWith(
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  cursorColor: AppColors.primary,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
                if (showTypewriter)
                  IgnorePointer(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            placeholder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: widget.text.bodyMedium?.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (!_reduceMotion)
                          const _BlinkingCursor(color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _submit,
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});
  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 530),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink,
      child: Container(
        width: 2,
        height: 18,
        margin: const EdgeInsets.only(left: 1),
        color: widget.color,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hero banner carousel
// ─────────────────────────────────────────────────────────────────────────

@immutable
class _BannerData {
  const _BannerData({
    required this.headline,
    required this.sub,
    required this.gradient,
    required this.icon,
    this.badge,
  });
  final String headline;
  final String sub;
  final List<Color> gradient;
  final IconData icon;
  final String? badge;
}

List<_BannerData> _bannersFor(AppLocalizations l) => <_BannerData>[
      _BannerData(
        headline: l.summerAcCheckup,
        sub: l.bookFullAcService,
        gradient: const [Color(0xFF0EA5E9), Color(0xFF0369A1)],
        icon: Icons.ac_unit_rounded,
        badge: l.badgeLimited,
      ),
      _BannerData(
        headline: l.referAndEarn,
        sub: l.shareYourCode,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        icon: Icons.card_giftcard_rounded,
        badge: l.newTag,
      ),
      _BannerData(
        headline: l.ramadanDeepClean,
        sub: l.professionalWholeHomeCleaning,
        gradient: const [Color(0xFF10B981), Color(0xFF047857)],
        icon: Icons.cleaning_services_rounded,
      ),
    ];

class _HeroBannerCarousel extends StatefulWidget {
  const _HeroBannerCarousel();

  @override
  State<_HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<_HeroBannerCarousel> {
  final PageController _page = PageController(viewportFraction: 1.0);
  int _current = 0;
  Timer? _autoScroll;
  List<_BannerData> _banners = const <_BannerData>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _banners = _bannersFor(AppLocalizations.of(context));
    if (_current >= _banners.length) _current = 0;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _autoScroll?.cancel();
    if (!reduce) {
      _autoScroll = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        final next = (_current + 1) % _banners.length;
        _page.animateToPage(next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _page,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => _bannerCard(_banners[i], text),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Builder(builder: (context) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: active ? 20 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppColors.primary.withValues(alpha: 0.22)),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _bannerCard(_BannerData b, TextTheme text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: b.gradient,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -12,
            bottom: -16,
            child: Icon(b.icon,
                size: 100, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (b.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(b.badge!,
                      style: text.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      )),
                ),
              Text(b.headline,
                  style: text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 4),
              Text(b.sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.35,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Trust strip
// ─────────────────────────────────────────────────────────────────────────

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0x12000000),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TrustStat(
                value: '1,200+', label: l.verifiedPros, icon: Icons.verified_rounded),
          ),
          const _StatDivider(),
          Expanded(
            child: _TrustStat(
                value: '4.9', label: l.avgRating, icon: Icons.star_rounded),
          ),
          const _StatDivider(),
          Expanded(
            child: _TrustStat(
                value: '~30m', label: l.avgArrival, icon: Icons.bolt_rounded),
          ),
        ],
      ),
    );
  }
}

class _TrustStat extends StatelessWidget {
  const _TrustStat(
      {required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(value,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures()
                  ],
                )),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: text.labelSmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                  : AppColors.textSecondaryLight,
            )),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 30,
      width: 1,
      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0x14000000),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Popular / Book-it-again horizontal scroll
// ─────────────────────────────────────────────────────────────────────────

@immutable
class _PopularItem {
  const _PopularItem({
    required this.category,
    required this.label,
    required this.price,
    required this.bookings,
  });
  final JobCategory category;
  final String label;
  final String price;
  final String bookings;
}

List<_PopularItem> _popularItemsFor(AppLocalizations l) => <_PopularItem>[
      _PopularItem(
        category: JobCategory.ac,
        label: l.acDeepClean,
        price: l.from250Egp,
        bookings: '2.4k ${l.booked}',
      ),
      _PopularItem(
        category: JobCategory.plumbing,
        label: l.leakRepair,
        price: l.from150Egp,
        bookings: '1.8k ${l.booked}',
      ),
      _PopularItem(
        category: JobCategory.electrical,
        label: l.outletInstall,
        price: l.from120Egp,
        bookings: '1.2k ${l.booked}',
      ),
      _PopularItem(
        category: JobCategory.cleaning,
        label: l.fullHomeClean,
        price: l.from400Egp,
        bookings: '3.1k ${l.booked}',
      ),
      _PopularItem(
        category: JobCategory.painting,
        label: l.roomRepaint,
        price: l.from600Egp,
        bookings: '900 ${l.booked}',
      ),
    ];

class _PopularServices extends StatelessWidget {
  const _PopularServices({required this.onTap});
  final ValueChanged<JobCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<_PopularItem> items = _popularItemsFor(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: l.popularInYourArea),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final item = items[i];
              final tint = categoryTint(item.category);
              final bool isDark = Theme.of(context).brightness == Brightness.dark;
              return GestureDetector(
                onTap: () => onTap(item.category),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surface.withValues(alpha: 0.45)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0x12000000),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: isDark ? 0.14 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(categoryIcon(item.category),
                            color: tint, size: 18),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      const Spacer(),
                      Text(item.price,
                          style: text.labelSmall?.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(item.bookings,
                          style: text.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondary.withValues(alpha: 0.5)
                                : AppColors.textSecondaryLight,
                            fontSize: 10,
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Services grid
// ─────────────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.order, required this.onTap});
  final List<JobCategory> order;
  final ValueChanged<JobCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.78,
      children: order
          .map((JobCategory c) => _CategoryTile(
                label: categoryLabel(c, l),
                fullLabel: categoryLabel(c, l),
                icon: categoryIcon(c),
                tint: categoryTint(c),
                onTap: () => onTap(c),
              ))
          .toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.fullLabel,
    required this.icon,
    required this.tint,
    required this.onTap,
  });
  final String label;
  final String fullLabel;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: fullLabel,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isDark
              ? null
              : Border.all(color: const Color(0x12000000)),
        ),
        child: Material(
          color: isDark ? AppColors.surface.withValues(alpha: 0.45) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: isDark ? 0.16 : 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: tint.withValues(alpha: isDark ? 0.28 : 0.35)),
                  ),
                  child: Icon(icon, color: tint, size: 24),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Top pros carousel
// ─────────────────────────────────────────────────────────────────────────

class _TopProsCarousel extends StatelessWidget {
  const _TopProsCarousel({required this.onTap});
  final ValueChanged<Technician> onTap;

  @override
  Widget build(BuildContext context) {
    final List<Technician> pros = technicians(AppLocalizations.of(context));
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: pros.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) {
          final Technician t = pros[i];
          return _ProCard(tech: t, onTap: () => onTap(t));
        },
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.tech, required this.onTap});
  final Technician tech;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: '${tech.name}, ${tech.specialty}, rated '
          '${tech.rating.toStringAsFixed(1)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isDark ? null : Border.all(color: const Color(0x12000000)),
        ),
        child: Material(
        color: isDark ? AppColors.surface.withValues(alpha: 0.55) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          child: SizedBox(
                            height: 52,
                            width: 52,
                            child: _Avatar(
                                seed: tech.id,
                                initials: tech.initials,
                                url: tech.photoUrl),
                          ),
                        ),
                        Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            height: 14,
                            width: 14,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.surface : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(tech.rating.toStringAsFixed(1),
                              style: text.labelSmall?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w800,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(tech.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(tech.specialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.65)
                          : AppColors.textSecondaryLight,
                    )),
                const Spacer(),
                Row(
                  children: <Widget>[
                    StatusPill(label: tech.badge.label(AppLocalizations.of(context)), tint: tech.badge.tint),
                    const Spacer(),
                    Text('${tech.hourlyRate} ${AppLocalizations.of(context).egpPerHour}',
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures()
                          ],
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Active Search card — shown on home whenever a search is in progress
// ─────────────────────────────────────────────────────────────────────────

class _ActiveSearchCard extends ConsumerWidget {
  const _ActiveSearchCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ActiveSearch? search = ref.watch(activeSearchProvider);
    if (search == null) return const SizedBox.shrink();

    final bool hasOffers = search.offersReady;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);

    void navigate() {
      if (hasOffers) {
        context.push(OffersScreen.routePath);
      } else {
        context.push('${MatchingScreen.routePath}?jobId=${search.jobId}');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: navigate,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.25),
            ),
          ),
          child: Row(
            children: <Widget>[
              // Pulsing dot
              _PulsingDot(color: hasOffers ? AppColors.success : AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hasOffers ? l.offersReceived : l.searchingForPros,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasOffers ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasOffers
                          ? l.tapToReviewHire
                          : l.tapToViewProgress,
                      style: text.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondary.withValues(alpha: 0.7)
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small circle that pulses to signal live activity.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Outer pulse ring
          Opacity(
            opacity: (1 - _c.value) * 0.4,
            child: Transform.scale(
              scale: 1.0 + _c.value * 0.8,
              child: Container(
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          // Solid inner dot
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────

/// Network photo with a deterministic colored initials fallback (used while the
/// image loads or if it fails - keeps cards readable offline).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed, required this.initials, this.url});
  final String seed;
  final String initials;
  final String? url;

  static const List<Color> _palette = <Color>[
    Color(0xFF7C3AED),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
  ];

  @override
  Widget build(BuildContext context) {
    final Color bg = _palette[seed.hashCode.abs() % _palette.length];
    final Widget fallback = ColoredBox(
      color: bg,
      child: Center(
        child: Text(initials,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
      ),
    );
    if (url == null) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? p) =>
          p == null ? child : fallback,
    );
  }
}
