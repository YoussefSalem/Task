import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/tech_colors.dart';
import '../chat/chat_providers.dart';
import '../chat/chat_screen.dart';
import '../jobs/active_job_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/jobs_providers.dart';
import 'notification_providers.dart';

/// The pro's in-app alert feed: new counters, hires, messages, and job updates.
/// A tap marks the entry read and routes back to the job or conversation.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const String routeName = 'notifications';
  static const String routePath = '/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> feedAsync =
        ref.watch(notificationFeedProvider);
    final String? uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          if (uid != null)
            TextButton(
              onPressed: () =>
                  ref.read(notificationRepositoryProvider).markAllRead(uid),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load notifications.\n$e')),
        data: (items) {
          if (items.isEmpty) return const _EmptyFeed();
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _NotificationTile(
              item: items[i],
              uid: uid,
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item, required this.uid});
  final AppNotification item;
  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final (IconData icon, Color tint) = _visual(item.type);

    return Material(
      color: item.read
          ? scheme.surface
          : scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(item.title,
                              style: text.titleSmall?.copyWith(
                                fontWeight: item.read
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              )),
                        ),
                        Text(_stamp(item.createdAt),
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            )),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        )),
                  ],
                ),
              ),
              if (!item.read)
                Container(
                  margin: const EdgeInsets.only(left: AppSpacing.sm, top: 4),
                  height: 9,
                  width: 9,
                  decoration:
                      BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (uid != null && !item.read) {
      await ref.read(notificationRepositoryProvider).markRead(
            uid: uid!,
            notificationId: item.id,
          );
    }
    if (!context.mounted) return;
    final String? jobId = item.jobId;
    if (jobId == null) return;

    if (item.type == NotificationType.message) {
      final JobRequest? job = ref.read(jobByIdProvider(jobId));
      unawaited(context.pushNamed(
        ChatScreen.routeName,
        pathParameters: <String, String>{'jobId': jobId},
        extra: ChatArgs(
          jobId: jobId,
          technicianId: uid ?? item.threadId ?? '',
          customerId: job?.customerId ?? '',
          customerName: 'Customer',
        ),
      ));
      return;
    }

    // Hired / status / offer → the active-job workspace if this pro is on it,
    // else the job brief.
    final JobRequest? job = ref.read(jobByIdProvider(jobId));
    final bool hiredMe = job?.acceptedOffer?.technicianId == uid;
    unawaited(context.pushNamed(
      hiredMe ? ActiveJobScreen.routeName : JobDetailScreen.routeName,
      pathParameters: <String, String>{'jobId': jobId},
    ));
  }

  (IconData, Color) _visual(NotificationType t) => switch (t) {
        NotificationType.message => (Icons.chat_bubble_rounded, TechColors.accent),
        NotificationType.offer => (Icons.gavel_rounded, const Color(0xFF38BDF8)),
        NotificationType.hired => (Icons.verified_rounded, TechColors.online),
        NotificationType.jobStatus =>
          (Icons.local_shipping_rounded, AppColors.warning),
      };

  String _stamp(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return DateFormat('MMM d').format(t);
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.notifications_none_rounded,
                size: 48, color: scheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text('No notifications',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Hires, counters, and messages will show up here.',
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
