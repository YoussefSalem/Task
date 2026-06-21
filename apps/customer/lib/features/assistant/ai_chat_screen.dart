import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

/// Task Assistant — an in-app AI helper for customers. Replies are stubbed for
/// the prototype (the live model wires in with the comms phase), but the
/// composer, suggestion chips, typing indicator and message list are all live.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  static const String routePath = '/ai-chat';

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _Message {
  _Message(this.text, {required this.fromUser});
  final String text;
  final bool fromUser;
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Message> _messages = <_Message>[
    _Message(
      "Hi Ahmed! I'm your Task assistant. Tell me what needs fixing and I'll line up the right pro.",
      fromUser: false,
    ),
  ];
  bool _typing = false;
  Timer? _replyTimer;

  static const List<String> _suggestions = <String>[
    'My AC is leaking water',
    'Power keeps tripping',
    'Need a deep clean this weekend',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _replyTimer?.cancel();
    super.dispose();
  }

  void _send(String raw) {
    final String textValue = raw.trim();
    if (textValue.isEmpty) return;
    setState(() {
      _messages.add(_Message(textValue, fromUser: true));
      _input.clear();
      _typing = true;
    });
    _scrollToEnd();
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(_Message(
          "Got it. Based on that, I'd book a verified pro for you. Tap a category on Home, or say 'book now' and I'll start an ASAP request.",
          fromUser: false,
        ));
      });
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Task Assistant',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('AI · always on',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.success,
                    )),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.12),
          SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: _messages.length + (_typing ? 1 : 0),
                    itemBuilder: (BuildContext context, int i) {
                      if (i == _messages.length) return _typingBubble(text);
                      return _bubble(_messages[i], text);
                    },
                  ),
                ),
                if (_messages.length == 1) _suggestionRow(text),
                _composer(text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Message m, TextTheme text) {
    final bool user = m.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: user
              ? AppColors.primary
              : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 4),
            bottomRight: Radius.circular(user ? 4 : 18),
          ),
        ),
        child: Text(m.text,
            style: text.bodyMedium?.copyWith(
              color: Colors.white,
              height: 1.35,
            )),
      ),
    );
  }

  Widget _typingBubble(TextTheme text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                child: const _Dot(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionRow(TextTheme text) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int i) {
          return GestureDetector(
            onTap: () => _send(_suggestions[i]),
            child: Container(
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(_suggestions[i],
                  style: text.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _composer(TextTheme text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl,
          AppSpacing.md + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Message the assistant…',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => _send(_input.text),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
        child: SizedBox(height: 7, width: 7),
      ),
    );
  }
}
