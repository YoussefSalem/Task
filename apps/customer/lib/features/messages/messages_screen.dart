import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../chat/chat_providers.dart';
import '../chat/chat_screen.dart';

/// Messages inbox: lists all active conversations from Firestore, newest first.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String? uid = ref.watch(currentUidProvider);
    final AsyncValue<List<ChatThread>> threadsAsync = uid == null
        ? const AsyncValue<List<ChatThread>>.data(<ChatThread>[])
        : ref.watch(_userThreadsProvider(uid));

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.08),
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
                child: Text(l.messages,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
              ),
              Expanded(
                child: threadsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                      child: Text(l.error(e.toString()),
                          style: text.bodyMedium)),
                  data: (threads) {
                    if (threads.isEmpty) return _empty(context, text, l, isDark);
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, 0, AppSpacing.xl, 112),
                      itemCount: threads.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0x12FFFFFF)
                            : const Color(0x12000000),
                      ),
                      itemBuilder: (_, i) =>
                          _ThreadTile(thread: threads[i], uid: uid!),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty(
      BuildContext context, TextTheme text, AppLocalizations l, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.chat_bubble_outline_rounded,
              size: 56,
              color: isDark
                  ? AppColors.textSecondary.withValues(alpha: 0.3)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          Text(l.noMessagesYet,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.whenTechniciansRespond,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                  : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

final _userThreadsProvider =
    StreamProvider.family<List<ChatThread>, String>((ref, uid) {
  return ref.watch(messagingRepositoryProvider).watchThreadsForUser(uid);
});

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.uid});
  final ChatThread thread;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasUnread = thread.lastMessageAt != null &&
        (thread.lastReadByCustomer == null ||
            thread.lastMessageAt!.isAfter(thread.lastReadByCustomer!));
    final initials = thread.technicianName
        .split(' ')
        .map((s) => s.isEmpty ? '' : s[0])
        .take(2)
        .join();

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary,
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      title: Text(thread.technicianName,
          style: text.titleSmall?.copyWith(
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
          )),
      subtitle: Text(
        thread.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(
          color: isDark
              ? AppColors.textSecondary.withValues(alpha: hasUnread ? 0.8 : 0.5)
              : (hasUnread
                  ? AppColors.textSecondaryLight
                  : AppColors.textSecondaryLight.withValues(alpha: 0.7)),
        ),
      ),
      trailing: hasUnread
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            )
          : null,
      onTap: () => context.push(
        ChatScreen.routePath,
        extra: ChatArgs(
          jobId: thread.jobId,
          technicianId: thread.technicianId,
          technicianName: thread.technicianName,
        ),
      ),
    );
  }
}
