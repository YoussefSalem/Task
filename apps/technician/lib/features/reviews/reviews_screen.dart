import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/tech_colors.dart';
import 'reviews_providers.dart';

/// What customers say about the pro: an average, a count, and the individual
/// ratings + notes. Read-only — reviews are written by customers post-job.
class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  static const String routeName = 'reviews';
  static const String routePath = '/reviews';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Review>> reviewsAsync = ref.watch(myReviewsProvider);
    final summary = ref.watch(ratingSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your reviews'),
        backgroundColor: Colors.transparent,
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Could not load reviews.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) return const _EmptyReviews();
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: reviews.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _SummaryCard(
                    average: summary.average, count: summary.count);
              }
              return _ReviewCard(review: reviews[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.average, required this.count});
  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(average.toStringAsFixed(1),
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  )),
              _Stars(rating: average, size: 18),
              const SizedBox(height: 4),
              Text('$count ${count == 1 ? 'review' : 'reviews'}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Stars(rating: review.rating.toDouble(), size: 16),
              const Spacer(),
              Text(DateFormat('MMM d, yyyy').format(review.createdAt),
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  )),
            ],
          ),
          if (review.note.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(review.note, style: text.bodyMedium?.copyWith(height: 1.4)),
          ],
          if (review.tags.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: review.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 6),
                        decoration: BoxDecoration(
                          color: TechColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(t,
                            style: text.labelMedium?.copyWith(
                              color: TechColors.accent,
                              fontWeight: FontWeight.w600,
                            )),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 16});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (i) {
        final bool full = rating >= i + 1;
        final bool half = !full && rating > i + 0.25;
        return Icon(
          full
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: size,
          color: AppColors.warning,
        );
      }),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.star_border_rounded,
                size: 48, color: scheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text('No reviews yet',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Finish jobs and customer ratings will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    )),
          ],
        ),
      ),
    );
  }
}
