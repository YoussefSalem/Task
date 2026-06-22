import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// Args passed via GoRouter extra when navigating to chat.
class ChatArgs {
  const ChatArgs({required this.technicianId, required this.technicianName});
  final String technicianId;
  final String technicianName;
}

/// In-app chat between customer and technician during the offer phase.
/// Messages are mocked — real transport would go through a messaging service.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  static const String routePath = '/chat';
  static const String routeName = 'chat';

  final String technicianId;
  final String technicianName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focusNode = FocusNode();

  final List<_ChatMsg> _messages = [
    _ChatMsg(
        text: 'Hello! I reviewed your job. I can arrive within 30 minutes.',
        fromMe: false,
        time: '3:41 PM'),
    _ChatMsg(
        text: 'My quote includes all materials. Any specific brand preference?',
        fromMe: false,
        time: '3:41 PM'),
  ];

  void _send() {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(_ChatMsg(
        text: txt,
        fromMe: true,
        time: TimeOfDay.now().format(context),
      ));
    });
    _ctrl.clear();
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Mock reply
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(
          text: 'Got it! I\'ll bring everything needed. See you soon.',
          fromMe: false,
          time: TimeOfDay.now().format(context),
        ));
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  widget.technicianName
                      .split(' ')
                      .map((s) => s.isEmpty ? '' : s[0])
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
              children: [
                Text(widget.technicianName,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.success),
                    ),
                    const SizedBox(width: 5),
                    Text('Online',
                        style: text.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md,
              AppSpacing.sm + mq.padding.bottom,
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
              children: [
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
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message…',
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
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
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

class _ChatMsg {
  const _ChatMsg({
    required this.text,
    required this.fromMe,
    required this.time,
  });
  final String text;
  final bool fromMe;
  final String time;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _ChatMsg msg;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: msg.fromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.fromMe
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surface.withValues(alpha: 0.8)
                      : const Color(0xFFEDE9FE)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.fromMe ? 16 : 4),
                bottomRight: Radius.circular(msg.fromMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: msg.fromMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.text,
                    style: text.bodyMedium?.copyWith(
                      color: msg.fromMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    )),
                const SizedBox(height: 3),
                Text(
                  msg.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: msg.fromMe
                        ? Colors.white.withValues(alpha: 0.6)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondary.withValues(alpha: 0.45)
                            : AppColors.textSecondaryLight),
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
