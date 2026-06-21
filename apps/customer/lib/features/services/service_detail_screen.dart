import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';
import 'service_catalog.dart';

/// Detail for a single service: hero, trust stats, what's included, and a
/// pinned book bar that seeds the booking draft and enters the flow.
class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({required this.serviceId, super.key});

  final String serviceId;

  static const List<String> _included = <String>[
    'Verified, background-checked professional',
    'Upfront price, approve any extra before work starts',
    'Live tracking from dispatch to done',
    '30-day workmanship guarantee',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Service service = serviceById(serviceId);
    final TextTheme text = Theme.of(context).textTheme;

    void book() {
      ref.read(bookingProvider.notifier).start(service.id);
      context.push('/book/configure');
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.12),
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                expandedHeight: 220,
                flexibleSpace: FlexibleSpaceBar(
                  background: _Hero(service: service),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 140),
                sliver: SliverList.list(
                  children: <Widget>[
                    Text(
                      service.name,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.tagline,
                      style: text.titleMedium?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: <Widget>[
                        _stat(text, Icons.star_rounded, '${service.rating}',
                            'rating', AppColors.warning),
                        _divider(),
                        _stat(
                            text,
                            Icons.verified_rounded,
                            '${(service.jobsDone / 1000).toStringAsFixed(1)}k',
                            'jobs done',
                            AppColors.success),
                        _divider(),
                        _stat(text, Icons.schedule_rounded,
                            service.durationLabel, 'typical', service.tint),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      "What's included",
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._included.map((String line) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(Icons.check_circle_rounded,
                                  size: 20, color: AppColors.success),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(line,
                                    style: text.bodyLarge?.copyWith(height: 1.3)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BookBar(service: service, onBook: book),
          ),
        ],
      ),
    );
  }

  Widget _stat(TextTheme text, IconData icon, String value, String label,
      Color tint) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, color: tint, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: text.bodySmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              )),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: const Color(0x18FFFFFF),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            service.tint.withValues(alpha: 0.28),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Container(
          height: 96,
          width: 96,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: service.tint.withValues(alpha: 0.5)),
          ),
          child: Icon(service.icon, size: 46, color: service.tint),
        ),
      ),
    );
  }
}

class _BookBar extends StatelessWidget {
  const _BookBar({required this.service, required this.onBook});
  final Service service;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Starting at',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  )),
              Text('${service.basePrice} EGP',
                  style: text.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: GlowButton(label: 'Book this service', onPressed: onBook)),
        ],
      ),
    );
  }
}
