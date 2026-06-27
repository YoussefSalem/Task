import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../chat/chat_providers.dart';
import '../chat/chat_screen.dart';

/// The customer's in-app notification feed. Streams `users/{uid}/notifications`
/// newest-first, lets the customer mark entries read, and routes a message
/// notification straight into its conversation.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const String routePath = '/notifications';
  static const String routeName = 'notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String? uid = ref.watch(currentUidProvider);
    final AsyncValue<List<AppNotification>> feedAsync =
        ref.watch(notificationFeedProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l.notificationsTitle),
        actions: <Widget>[
          if (uid != null)
            TextButton(
              onPressed: () =>
                  ref.read(notificationRepositoryProvider).markAllRead(uid),
              child: Text(l.notificationsMarkAll),
            ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            Center(child: Text(l.chatLoadError, style: text.bodyMedium)),
        data: (List<AppNotification> items) {
          if (items.isEmpty) {
            return _EmptyState(message: l.notificationsEmpty);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (BuildContext context, int i) => _NotificationTile(
              item: items[i],
              onTap: () => _open(context, ref, uid, items[i]),
            ),
          );
        },
      ),
    );
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    String? uid,
    AppNotification n,
  ) {
    if (uid != null && !n.read) {
      ref
          .read(notificationRepositoryProvider)
          .markRead(uid: uid, notificationId: n.id);
    }
    // A message notification routes back into its conversation.
    if (n.type == NotificationType.message &&
        n.jobId != null &&
        n.threadId != null) {
      context.push(
        ChatScreen.routePath,
        extra: ChatArgs(
          jobId: n.jobId!,
          technicianId: n.threadId!,
          technicianName: n.actorId ?? '',
        ),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  ({IconData icon, Color color}) get _visual => switch (item.type) {
        NotificationType.message => (
            icon: Icons.chat_bubble_rounded,
            color: AppColors.primary
          ),
        NotificationType.offer => (
            icon: Icons.local_offer_rounded,
            color: AppColors.success
          ),
        NotificationType.hired => (
            icon: Icons.handshake_rounded,
            color: AppColors.success
          ),
        NotificationType.jobStatus => (
            icon: Icons.info_rounded,
            color: AppColors.warning
          ),
      };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ({IconData icon, Color color}) v = _visual;

    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: v.color.withValues(alpha: 0.16),
        ),
        child: Icon(v.icon, color: v.color, size: 22),
      ),
      title: Text(
        item.title,
        style: text.titleSmall?.copyWith(
          fontWeight: item.read ? FontWeight.w600 : FontWeight.w800,
        ),
      ),
      subtitle: Text(
        item.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: item.read
          ? null
          : Container(
              height: 10,
              width: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.notifications_off_rounded,
              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(message,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
