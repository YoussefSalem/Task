import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../widgets/tech_ambient.dart';
import '../home/tech_shell.dart';
import '../jobs/jobs_providers.dart';
import 'chat_providers.dart';
import 'chat_screen.dart';

/// The technician's inbox — every job conversation, newest first. Read state
/// comes from the thread's own cursor, so an unread dot appears the moment a
/// customer replies.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChatThread>> threadsAsync =
        ref.watch(myThreadsProvider);
    final String? uid = ref.watch(currentUidProvider);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient(intensity: 0.12)),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                  child: Text('Messages',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: threadsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Could not load messages.\n$e')),
                    data: (threads) {
                      if (threads.isEmpty) return const _EmptyInbox();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                            AppSpacing.lg, TechShell.barClearance),
                        itemCount: threads.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _ThreadTile(
                          thread: threads[i],
                          uid: uid,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  const _ThreadTile({required this.thread, required this.uid});
  final ChatThread thread;
  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final JobRequest? job = ref.watch(jobByIdProvider(thread.jobId));
    final DateTime? cursor = thread.readCursorFor(SenderRole.technician);
    final bool unread = thread.lastMessageAt != null &&
        (cursor == null || thread.lastMessageAt!.isAfter(cursor));
    final String title = job != null ? job.category.displayLabel : 'Customer';

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.pushNamed(
          ChatScreen.routeName,
          pathParameters: <String, String>{'jobId': thread.jobId},
          extra: ChatArgs(
            jobId: thread.jobId,
            technicianId: uid ?? thread.technicianId,
            customerId: thread.customerId,
            customerName: 'Customer',
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primary.withValues(alpha: 0.14),
                child: Icon(
                  job != null ? categoryIcon(job.category) : Icons.person_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(
                                fontWeight:
                                    unread ? FontWeight.w800 : FontWeight.w600,
                              )),
                        ),
                        if (thread.lastMessageAt != null)
                          Text(_stamp(thread.lastMessageAt!),
                              style: text.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              )),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            thread.lastMessage.isEmpty
                                ? 'No messages yet'
                                : thread.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: unread
                                  ? scheme.onSurface
                                  : scheme.onSurface.withValues(alpha: 0.6),
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsets.only(left: AppSpacing.sm),
                            height: 9,
                            width: 9,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stamp(DateTime t) {
    final DateTime now = DateTime.now();
    if (now.difference(t).inDays == 0) return DateFormat('h:mm a').format(t);
    if (now.difference(t).inDays < 7) return DateFormat('EEE').format(t);
    return DateFormat('MMM d').format(t);
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: scheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text('No conversations yet',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('When you bid on a job, you can message the customer here.',
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
