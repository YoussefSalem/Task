import 'package:customer/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';
import 'package:web/web.dart' as web;

import '../location/location_provider.dart';
import '../marketplace/marketplace_providers.dart';
import '../offers/offers_screen.dart';

const String _mapsKey = 'AIzaSyBkGqJxUaSwTtMdLG6HEArY2Ca_VO0yZKE';

/// How far along the search sequence we are. Stays alive in the background
/// when the user exits — the job is never cancelled just by leaving.
enum _SearchPhase { searching, prosFound, awaitingOffers, offersReady }

class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key, this.jobId});

  static const String routePath = '/matching';
  static const String routeName = 'matching';

  final String? jobId;

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _radarCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _dotCtrl;
  late final AnimationController _panelCtrl;

  _SearchPhase _phase = _SearchPhase.searching;
  int _prosFound = 0;
  int _offersCount = 0;
  bool _navigatedToOffers = false;

  @override
  void initState() {
    super.initState();

    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    final String? jobId = widget.jobId;
    if (jobId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeSearchProvider.notifier).state =
            ActiveSearch(jobId: jobId);
      });
    }
  }

  void _syncPhaseFromJob(JobRequest? job) {
    if (job == null) return;
    final offers = job.offers;
    final _SearchPhase newPhase;
    if (offers.isNotEmpty && offers.any((o) => o.status == OfferStatus.pending)) {
      newPhase = _SearchPhase.offersReady;
    } else if (offers.isNotEmpty) {
      newPhase = _SearchPhase.awaitingOffers;
    } else if (job.status == JobStatus.biddingActive) {
      newPhase = _SearchPhase.searching;
    } else {
      newPhase = _SearchPhase.searching;
    }

    if (newPhase != _phase) {
      setState(() {
        _phase = newPhase;
        _prosFound = offers.length;
        _offersCount = offers.length;
      });
    }

    if (newPhase == _SearchPhase.offersReady && !_navigatedToOffers) {
      _navigatedToOffers = true;
      final ActiveSearch? current = ref.read(activeSearchProvider);
      if (current != null) {
        ref.read(activeSearchProvider.notifier).state =
            current.copyWith(offersReady: true);
      }
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        context.pushReplacement(OffersScreen.routePath);
      });
    }
  }

  /// Leave the radar but keep the search running in the background. The Home
  /// screen shows an "active search" card so the user can return any time.
  void _goHomeKeepingSearch() => context.go('/home');

  @override
  void dispose() {
    _radarCtrl.dispose();
    _glowCtrl.dispose();
    _dotCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  /// The "Stop search" button shows a dialog: go home (job stays active) vs
  /// cancel the request entirely.
  Future<void> _confirmStop() async {
    final result = await _showExitDialog();
    if (!mounted) return;
    if (result == _ExitChoice.exit) {
      _goHomeKeepingSearch();
    } else if (result == _ExitChoice.cancel) {
      final jobId = widget.jobId;
      if (jobId != null) {
        await ref.read(jobMarketplaceRepositoryProvider).cancelJob(jobId);
      }
      // Clear the active search tracker so the Home card disappears.
      ref.read(activeSearchProvider.notifier).state = null;
      if (!mounted) return;
      context.go('/home');
    }
  }

  Future<_ExitChoice?> _showExitDialog() {
    final AppLocalizations l = AppLocalizations.of(context);
    return showDialog<_ExitChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppColors.surface
            : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.stopSearchQ,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          l.stopSearchBody,
          style: const TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitChoice.cancel),
            child: Text(l.cancelRequest,
                style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.stay),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, _ExitChoice.exit),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l.goHome),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _headlineFor(AppLocalizations l) => switch (_phase) {
    _SearchPhase.searching => l.findingNearbyProfessionals,
    _SearchPhase.prosFound => l.prosFoundNearby(_prosFound),
    _SearchPhase.awaitingOffers => l.waitingForOffers,
    _SearchPhase.offersReady => l.offersReceivedCount(_offersCount),
  };

  String _subFor(AppLocalizations l) => switch (_phase) {
    _SearchPhase.searching => l.scanningYourArea,
    _SearchPhase.prosFound => l.sendingJobDetails,
    _SearchPhase.awaitingOffers => l.prosReviewing,
    _SearchPhase.offersReady => l.openingYourOffers,
  };

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(myJobsProvider).valueOrNull ?? const <JobRequest>[];
    final currentJob = widget.jobId != null
        ? jobs.where((j) => j.id == widget.jobId).firstOrNull
        : (jobs.isNotEmpty ? jobs.first : null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPhaseFromJob(currentJob);
    });

    final AppLocalizations l = AppLocalizations.of(context);
    final loc = ref.watch(locationProvider);
    final double lat = loc.lat ?? 29.9602;
    final double lng = loc.lng ?? 31.2569;
    final text = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);
    final bool offersReady = _phase == _SearchPhase.offersReady;
    final Color accent = offersReady ? AppColors.success : AppColors.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // System/gesture back leaves the radar but keeps the search alive.
        if (!didPop) _goHomeKeepingSearch();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Live Google Maps centered on the user's saved location. The iframe
            // is non-interactive (pointer-events: none), so it's a fixed backdrop
            // and taps fall through to the back button + panel above it.
            Positioned.fill(child: _MapLayer(lat: lat, lng: lng, isDark: isDark)),

            // Gradient overlay — uses scaffold bg to fade map into panel.
            Positioned.fill(
              child: Builder(builder: (context) {
                final Color bg = Theme.of(context).scaffoldBackgroundColor;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bg.withValues(alpha: 0.2),
                        bg.withValues(alpha: 0.1),
                        bg.withValues(alpha: 0.55),
                        bg.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.25, 0.6, 1.0],
                    ),
                  ),
                );
              }),
            ),

            // Radar rings
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 220),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_radarCtrl, _glowCtrl]),
                  builder: (_, __) => CustomPaint(
                    size: const Size(300, 300),
                    painter: _RadarPainter(
                      progress: _radarCtrl.value,
                      glowFactor: _glowCtrl.value,
                      accent: accent,
                    ),
                  ),
                ),
              ),
            ),

            // Center dot
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 220),
                child: AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (_, __) => Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: 20,
                          spreadRadius: 4 + _glowCtrl.value * 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Pro dots
            if (_phase.index >= _SearchPhase.prosFound.index)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 220),
                  child: AnimatedBuilder(
                    animation: _dotCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(300, 300),
                      painter: _ProDotsPainter(
                        count: _prosFound,
                        pulse: _dotCtrl.value,
                        accent: accent,
                      ),
                    ),
                  ),
                ),
              ),

            // Top bar
            Positioned(
              top: mq.padding.top + AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: _goHomeKeepingSearch,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0x14000000),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: offersReady ? AppColors.success : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(l.liveSearch,
                            style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom panel — wrapped so its buttons sit above the map iframe.
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _panelCtrl,
                  curve: Curves.easeOutCubic,
                )),
                child: _BottomPanel(
                  headline: _headlineFor(l),
                  sub: _subFor(l),
                  phase: _phase,
                  offersCount: _offersCount,
                  accent: accent,
                  text: text,
                  bottomPadding: mq.padding.bottom,
                  onExit: _confirmStop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExitChoice { exit, cancel }

// ---------------------------------------------------------------------------
// Map layer — a stylized, painted city map backdrop.
//
// Replaces the previous Google Maps iframe: on Flutter web an HtmlElementView
// iframe is a real DOM element that captures pointer events natively, so taps
// on the back button / bottom panel never reached Flutter (IgnorePointer can't
// fix it). A painted backdrop removes the iframe entirely, is consistent with
// the job-tracking map, and is far cheaper to render.
// ---------------------------------------------------------------------------
class _MapLayer extends StatelessWidget {
  const _MapLayer({required this.lat, required this.lng, required this.isDark});
  final double lat;
  final double lng;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final String viewType = 'radar-map-$lat-$lng';
    final String embedUrl = 'https://www.google.com/maps/embed/v1/place'
        '?key=$_mapsKey&q=$lat,$lng&zoom=15&maptype=roadmap';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
      final web.HTMLIFrameElement iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement
            ..src = embedUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..loading = 'lazy';
      // Non-interactive: the map is a fixed backdrop centered on the user's
      // location. Disabling pointer events also lets taps fall through to the
      // Flutter back button + panel above it.
      iframe.style.setProperty('pointer-events', 'none');
      return iframe;
    });

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Painted map shows underneath while the iframe loads / if it's blocked.
        _PaintedMap(isDark: isDark),
        HtmlElementView(viewType: viewType),
      ],
    );
  }
}

/// Stylized fallback map, used while the real map loads or if it fails.
class _PaintedMap extends StatelessWidget {
  const _PaintedMap({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[Color(0xFF1A2030), Color(0xFF12161F)]
              : const <Color>[Color(0xFFEDEFF4), Color(0xFFE4E7EE)],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _CityMapPainter(isDark: isDark),
      ),
    );
  }
}

/// Paints a calm, abstract city map: a river, a park, soft blocks and a road
/// grid. Deterministic (no randomness) so it never flickers between frames.
class _CityMapPainter extends CustomPainter {
  _CityMapPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Color block = isDark
        ? Colors.white.withValues(alpha: 0.025)
        : Colors.black.withValues(alpha: 0.022);
    final Color road = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.07);
    final Color roadMinor = isDark
        ? Colors.white.withValues(alpha: 0.035)
        : Colors.black.withValues(alpha: 0.04);
    final Color park = const Color(0xFF34D399)
        .withValues(alpha: isDark ? 0.10 : 0.14);
    final Color water = const Color(0xFF38BDF8)
        .withValues(alpha: isDark ? 0.12 : 0.16);

    // Soft city blocks (subtle filled rectangles on a loose grid).
    final Paint blockPaint = Paint()..color = block;
    const List<List<double>> blocks = <List<double>>[
      <double>[0.06, 0.10, 0.16, 0.10],
      <double>[0.30, 0.08, 0.22, 0.12],
      <double>[0.66, 0.12, 0.20, 0.10],
      <double>[0.10, 0.62, 0.18, 0.12],
      <double>[0.40, 0.66, 0.16, 0.10],
      <double>[0.70, 0.60, 0.18, 0.14],
    ];
    for (final List<double> b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(b[0] * w, b[1] * h, b[2] * w, b[3] * h),
          const Radius.circular(6),
        ),
        blockPaint,
      );
    }

    // River — a wide soft diagonal band across the lower-left.
    final Path river = Path()
      ..moveTo(-0.05 * w, 0.74 * h)
      ..lineTo(0.34 * w, 0.92 * h)
      ..lineTo(0.20 * w, 1.06 * h)
      ..lineTo(-0.18 * w, 0.88 * h)
      ..close();
    canvas.drawPath(river, Paint()..color = water);

    // Park — a rounded green patch upper-right.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.62 * w, 0.30 * h, 0.26 * w, 0.16 * h),
        const Radius.circular(18),
      ),
      Paint()..color = park,
    );

    // Road grid — major avenues (thicker) + minor streets (thinner).
    final Paint major = Paint()
      ..color = road
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Paint minor = Paint()
      ..color = roadMinor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Major horizontals + verticals.
    for (final double y in <double>[0.24, 0.55, 0.84]) {
      canvas.drawLine(Offset(0, y * h), Offset(w, y * h), major);
    }
    for (final double x in <double>[0.30, 0.66]) {
      canvas.drawLine(Offset(x * w, 0), Offset(x * w, h), major);
    }
    // A diagonal avenue for visual rhythm.
    canvas.drawLine(Offset(0, 0.40 * h), Offset(0.78 * w, h), major);

    // Minor streets between the majors.
    for (final double y in <double>[0.12, 0.39, 0.70]) {
      canvas.drawLine(Offset(0, y * h), Offset(w, y * h), minor);
    }
    for (final double x in <double>[0.16, 0.48, 0.83]) {
      canvas.drawLine(Offset(x * w, 0), Offset(x * w, h), minor);
    }
  }

  @override
  bool shouldRepaint(_CityMapPainter old) => old.isDark != isDark;
}

// ---------------------------------------------------------------------------
// Radar painter
// ---------------------------------------------------------------------------
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress, required this.glowFactor, required this.accent});
  final double progress;
  final double glowFactor;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final stagger = (progress + i / 3) % 1.0;
      final radius = stagger * maxR;
      final opacity = (1.0 - stagger) * 0.38;
      canvas.drawCircle(
        center, radius,
        Paint()
          ..color = accent.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + (1.0 - stagger) * 2,
      );
    }

    canvas.drawCircle(
      center,
      30 + glowFactor * 8,
      Paint()
        ..color = accent.withValues(alpha: 0.07 + glowFactor * 0.05)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => true;
}

// ---------------------------------------------------------------------------
// Pro dots painter
// ---------------------------------------------------------------------------
class _ProDotsPainter extends CustomPainter {
  _ProDotsPainter({required this.count, required this.pulse, required this.accent});
  final int count;
  final double pulse;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const r = 78.0;

    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi / count) * i - math.pi / 2;
      final dx = center.dx + math.cos(angle) * (r + pulse * 6);
      final dy = center.dy + math.sin(angle) * (r + pulse * 6);
      final offset = Offset(dx, dy);

      canvas.drawCircle(offset, 5.5,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
      canvas.drawCircle(
        offset, 9 + pulse * 4,
        Paint()
          ..color = accent.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ProDotsPainter old) => true;
}

// ---------------------------------------------------------------------------
// Bottom panel
// ---------------------------------------------------------------------------
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.headline,
    required this.sub,
    required this.phase,
    required this.offersCount,
    required this.accent,
    required this.text,
    required this.bottomPadding,
    required this.onExit,
  });

  final String headline;
  final String sub;
  final _SearchPhase phase;
  final int offersCount;
  final Color accent;
  final TextTheme text;
  final double bottomPadding;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final bool offersReady = phase == _SearchPhase.offersReady;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
        bottomPadding + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.background.withValues(alpha: 0.94)
            : AppColors.backgroundLight.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.18))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0x22000000),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Status row
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _StatusRow(
              key: ValueKey(phase),
              phase: phase,
              headline: headline,
              sub: sub,
              accent: accent,
              text: text,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Phase progress bar
          _PhaseBar(current: phase, accent: accent),

          const SizedBox(height: AppSpacing.xl),

          // "You can exit — job stays active" note
          if (!offersReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0x06000000),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0x10000000),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 15,
                      color: isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppColors.textSecondaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.youCanExitNote,
                      style: text.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondary.withValues(alpha: 0.5)
                            : AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!offersReady) const SizedBox(height: AppSpacing.lg),

          // Exit button (not cancel)
          if (!offersReady)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onExit,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0x22000000),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.stopSearch,
                    style: text.titleSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),

          if (offersReady) ...[
            GlowButton(
              label: l.viewOffersCount(offersCount),
              icon: Icons.local_offer_rounded,
              onPressed: () => context.pushReplacement(OffersScreen.routePath),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    super.key,
    required this.phase,
    required this.headline,
    required this.sub,
    required this.accent,
    required this.text,
  });
  final _SearchPhase phase;
  final String headline;
  final String sub;
  final Color accent;
  final TextTheme text;

  IconData get _icon => switch (phase) {
    _SearchPhase.searching => Icons.cell_tower_rounded,
    _SearchPhase.prosFound => Icons.people_alt_rounded,
    _SearchPhase.awaitingOffers => Icons.hourglass_top_rounded,
    _SearchPhase.offersReady => Icons.local_offer_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_icon, color: accent, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(sub,
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary.withValues(alpha: 0.6)
                        : AppColors.textSecondaryLight,
                    height: 1.3,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhaseBar extends StatelessWidget {
  const _PhaseBar({required this.current, required this.accent});
  final _SearchPhase current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<String> labels = <String>[
      l.phaseSearching,
      l.phaseFound,
      l.phaseWaiting,
      l.phaseOffers,
    ];
    return Row(
      children: List.generate(_SearchPhase.values.length, (i) {
        final active = i <= current.index;
        final isLast = i == _SearchPhase.values.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: active
                            ? accent
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0x18000000)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: active
                            ? accent
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Circle button
// ---------------------------------------------------------------------------
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background.withValues(alpha: 0.7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
