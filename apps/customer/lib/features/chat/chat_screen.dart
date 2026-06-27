import 'dart:async';

import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_core/task_core.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import 'chat_providers.dart';

/// Args passed via GoRouter extra when navigating to chat.
class ChatArgs {
  const ChatArgs({
    required this.jobId,
    required this.technicianId,
    required this.technicianName,
  });

  final String jobId;
  final String technicianId;
  final String technicianName;
}

/// Live customer↔technician chat for one job, backed by Firestore. Streams the
/// per-(job, technician) thread, shows the technician's typing state and read
/// receipts, and writes a notification into the technician's feed on send.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.jobId,
    required this.technicianId,
    required this.technicianName,
  });

  static const String routePath = '/chat';
  static const String routeName = 'chat';

  final String jobId;
  final String technicianId;
  final String technicianName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _typingDebounce;
  int _lastMarkedReadCount = -1;
  bool _sending = false;

  ThreadKey get _key =>
      (jobId: widget.jobId, technicianId: widget.technicianId);

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String _) {
    // Debounce typing pings so we write at most once every couple of seconds.
    if (_typingDebounce?.isActive ?? false) return;
    _typingDebounce = Timer(const Duration(seconds: 2), () {});
    ref.read(messagingRepositoryProvider).setTyping(
          jobId: widget.jobId,
          technicianId: widget.technicianId,
          role: SenderRole.customer,
        );
  }

  Future<void> _send() async {
    final String text = _ctrl.text.trim();
    final String? uid = ref.read(currentUidProvider);
    if (text.isEmpty || uid == null || _sending) return;

    setState(() => _sending = true);
    _ctrl.clear();

    final Result<void, Failure> r =
        await ref.read(messagingRepositoryProvider).sendMessage(
              jobId: widget.jobId,
              technicianId: widget.technicianId,
              technicianName: widget.technicianName,
              customerId: uid,
              senderId: uid,
              senderRole: SenderRole.customer,
              text: text,
            );

    if (!mounted) return;
    setState(() => _sending = false);

    if (r.isErr) {
      // Put the text back so the customer can retry.
      _ctrl.text = text;
      final AppLocalizations l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.chatLoadError)),
      );
      return;
    }

    // Notify the technician's in-app feed (no server fan-out yet).
    final AppLocalizations l = AppLocalizations.of(context);
    await ref.read(notificationRepositoryProvider).notify(
          recipientUid: widget.technicianId,
          draft: NotificationDraft(
            type: NotificationType.message,
            title: l.notifNewMessageTitle(l.customerWord),
            body: text,
            actorId: uid,
            jobId: widget.jobId,
            threadId: widget.technicianId,
          ),
        );
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Advance the customer's read cursor once new messages have arrived.
  void _markReadIfNeeded(List<Message> messages) {
    if (messages.length == _lastMarkedReadCount) return;
    _lastMarkedReadCount = messages.length;
    if (messages.isEmpty) return;
    ref.read(messagingRepositoryProvider).markRead(
          jobId: widget.jobId,
          technicianId: widget.technicianId,
          role: SenderRole.customer,
        );
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String? uid = ref.watch(currentUidProvider);

    final AsyncValue<List<Message>> messagesAsync =
        ref.watch(threadMessagesProvider(_key));
    final ChatThread? thread = ref.watch(threadMetaProvider(_key)).valueOrNull;

    // Mark incoming messages read as they stream in.
    messagesAsync.whenData(_markReadIfNeeded);

    final bool techTyping = thread?.isTyping(SenderRole.technician) ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  widget.technicianName
                      .split(' ')
                      .map((String s) => s.isEmpty ? '' : s[0])
                      .take(2)
                      .join(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.technicianName,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  techTyping ? l.typingIndicator : l.online,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: uid == null
          ? Center(child: Text(l.chatSignedOut, style: text.bodyMedium))
          : Column(
              children: <Widget>[
                Expanded(
                  child: messagesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object e, _) =>
                        Center(child: Text(l.chatLoadError, style: text.bodyMedium)),
                    data: (List<Message> messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(l.chatEmpty,
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              )),
                        );
                      }
                      final DateTime? techRead = thread?.lastReadByTechnician;
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                            AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                        itemCount: messages.length,
                        itemBuilder: (BuildContext context, int i) {
                          final Message m = messages[i];
                          final bool fromMe =
                              m.senderRole == SenderRole.customer;
                          final bool isLast = i == messages.length - 1;
                          // "Seen" under my latest message once the technician's
                          // read cursor has passed it.
                          final bool seen = fromMe &&
                              isLast &&
                              techRead != null &&
                              !m.createdAt.isAfter(techRead);
                          return _Bubble(
                            text: m.text,
                            fromMe: fromMe,
                            time: TimeOfDay.fromDateTime(m.createdAt)
                                .format(context),
                            seenLabel: seen ? l.seenLabel : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                _composer(text, isDark, l),
              ],
            ),
    );
  }

  Widget _composer(TextTheme text, bool isDark, AppLocalizations l) {
    final EdgeInsets pad = MediaQuery.of(context).padding;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + pad.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.6)
            : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0x12000000),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.background.withValues(alpha: 0.6)
                    : const Color(0xFFF0EEFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0x14000000),
                ),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                style: text.bodyMedium,
                maxLines: 3,
                minLines: 1,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: l.messageHint,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : AppColors.textSecondaryLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sending
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.primary,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.fromMe,
    required this.time,
    this.seenLabel,
  });

  final String text;
  final bool fromMe;
  final String time;
  final String? seenLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment:
            fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: fromMe
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.surface.withValues(alpha: 0.8)
                          : const Color(0xFFEDE9FE)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(fromMe ? 16 : 4),
                    bottomRight: Radius.circular(fromMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: fromMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: fromMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        )),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: fromMe
                            ? Colors.white.withValues(alpha: 0.6)
                            : (isDark
                                ? AppColors.textSecondary.withValues(alpha: 0.45)
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (seenLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(
                seenLabel!,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
