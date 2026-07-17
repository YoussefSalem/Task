import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import 'package:go_router/go_router.dart';

import '../call/call_controller.dart';
import '../call/call_screen.dart';
import '../jobs/jobs_providers.dart';
import '../profile/technician_profile.dart';
import 'chat_providers.dart';

/// Everything the chat screen needs to open (and, on first send, create) a
/// thread. `technicianId` is this pro's own uid.
class ChatArgs {
  const ChatArgs({
    required this.jobId,
    required this.technicianId,
    this.customerId = '',
    this.customerName = 'Customer',
  });

  final String jobId;
  final String technicianId;
  final String customerId;
  final String customerName;
}

/// A single customer↔technician conversation, from the technician's side.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.args, super.key});

  final ChatArgs args;

  static const String routeName = 'chat';
  static const String routePath = '/chat/:jobId';

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _typingDebounce;
  DateTime? _lastMarkRead;

  ThreadKey get _key =>
      (jobId: widget.args.jobId, technicianId: widget.args.technicianId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _markRead() {
    // Throttle so we don't write a cursor on every rebuild.
    final DateTime now = DateTime.now();
    if (_lastMarkRead != null &&
        now.difference(_lastMarkRead!) < const Duration(seconds: 2)) {
      return;
    }
    _lastMarkRead = now;
    ref.read(messagingRepositoryProvider).markRead(
          jobId: _key.jobId,
          technicianId: _key.technicianId,
          role: SenderRole.technician,
        );
  }

  void _onTyping(String _) {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(messagingRepositoryProvider).setTyping(
            jobId: _key.jobId,
            technicianId: _key.technicianId,
            role: SenderRole.technician,
          );
    });
    setState(() {}); // refresh send-button enabled state
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    final String? uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final profile = ref.read(techProfileProvider).valueOrNull;
    final ChatThread? meta = ref.read(threadMetaProvider(_key)).valueOrNull;
    final String customerId = widget.args.customerId.isNotEmpty
        ? widget.args.customerId
        : (meta?.customerId ?? '');
    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Can’t start this chat yet.')),
      );
      return;
    }

    _input.clear();
    setState(() {});
    final String techName =
        (profile?.fullName ?? '').isEmpty ? 'Technician' : profile!.fullName;
    final result = await ref.read(messagingRepositoryProvider).sendMessage(
          jobId: _key.jobId,
          technicianId: _key.technicianId,
          technicianName: techName,
          customerId: customerId,
          senderId: uid,
          senderRole: SenderRole.technician,
          text: text,
        );
    if (result.isOk) {
      // Drop a message notification into the customer's in-app feed.
      await ref.read(notificationRepositoryProvider).notify(
            recipientUid: customerId,
            draft: NotificationDraft(
              type: NotificationType.message,
              title: 'New message from $techName',
              body: text,
              actorId: uid,
              jobId: _key.jobId,
              threadId: _key.technicianId,
            ),
          );
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Message>> messagesAsync =
        ref.watch(threadMessagesProvider(_key));
    final ChatThread? meta = ref.watch(threadMetaProvider(_key)).valueOrNull;
    final bool customerTyping =
        meta?.isTyping(SenderRole.customer) ?? false;

    // Mark read whenever new messages land while the screen is open.
    ref.listen(threadMessagesProvider(_key), (_, _) => _markRead());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.args.customerName),
            if (customerTyping)
              Text('typing…',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      )),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Call customer',
            icon: const Icon(Icons.call_rounded),
            onPressed: () {
              final String room =
                  ref.read(currentUidProvider) ?? widget.args.technicianId;
              if (room.isEmpty) return;
              context.pushNamed(
                CallScreen.routeName,
                extra: CallArgs(roomId: room, peerName: widget.args.customerName),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load messages.\n$e')),
              data: (messages) {
                if (messages.isEmpty) return const _EmptyChat();
                _scrollToEnd();
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _Bubble(
                    message: messages[i],
                    mine: messages[i].senderRole == SenderRole.technician,
                  ),
                );
              },
            ),
          ),
          _Composer(
            controller: _input,
            onChanged: _onTyping,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76),
        decoration: BoxDecoration(
          color: mine
              ? scheme.primary
              : scheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: mine ? scheme.onPrimary : scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('h:mm a').format(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (mine ? scheme.onPrimary : scheme.onSurface)
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool canSend = controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Message…',
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: canSend
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.12),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: canSend ? onSend : null,
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: Icon(Icons.send_rounded,
                      color: canSend
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.forum_outlined,
                size: 44, color: scheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text('Say hello',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Confirm details or share your ETA with the customer.',
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
