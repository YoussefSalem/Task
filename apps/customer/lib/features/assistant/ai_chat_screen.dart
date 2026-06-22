import 'package:customer/l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import 'assistant_providers.dart';
import 'assistant_service.dart';
import 'posted_success_overlay.dart';

/// Task Assistant — the live, AI-driven booking chat. The assistant gathers the
/// job details, asks the customer what they'd like to pay, confirms, and then
/// posts the request to the technician marketplace. All wired through
/// [bookingChatProvider].
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key, this.initialMessage});

  final String? initialMessage;
  static const String routePath = '/ai-chat';

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static const List<String> _suggestions = <String>[
    'My AC is leaking water',
    'Power keeps tripping',
    'Need a deep clean this weekend',
  ];

  @override
  void initState() {
    super.initState();
    final msg = widget.initialMessage;
    if (msg != null && msg.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(msg));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final String value = raw.trim();
    if (value.isEmpty) return;
    _input.clear();
    _scrollToEnd();
    await ref.read(bookingChatProvider.notifier).send(value);
    _scrollToEnd();
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
    final ChatState chat = ref.watch(bookingChatProvider);
    final List<ChatMessage> messages = chat.messages;
    final bool posted = chat.phase == ChatPhase.posted;

    return Scaffold(
      appBar: posted
          ? null
          : AppBar(
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
        actions: <Widget>[
          if (chat.phase == ChatPhase.posted || messages.length > 1)
            IconButton(
              tooltip: 'New request',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(bookingChatProvider.notifier).reset(),
            ),
        ],
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
                    itemCount: messages.length + (chat.typing ? 1 : 0),
                    itemBuilder: (BuildContext context, int i) {
                      if (i == messages.length) return _typingBubble(text);
                      return _bubble(messages[i], text, i);
                    },
                  ),
                ),
                if (messages.length == 1) _suggestionRow(text),
                _composer(text, chat),
              ],
            ),
          ),
          if (posted)
            Positioned.fill(
              child: PostedSuccessOverlay(onDone: _goHome),
            ),
        ],
      ),
    );
  }

  void _goHome() {
    if (!mounted) return;
    context.go('/home');
    // Clear the conversation so the assistant starts fresh next time.
    ref.read(bookingChatProvider.notifier).reset();
  }

  Widget _bubble(ChatMessage m, TextTheme text, int index) {
    final bool user = m.fromUser;
    final Widget bubble = Align(
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
    return _AnimatedBubble(
      key: ValueKey<int>(index),
      fromUser: user,
      child: bubble,
    );
  }

  Widget _typingBubble(TextTheme text) {
    return _AnimatedBubble(
      key: const ValueKey<String>('typing'),
      fromUser: false,
      child: Align(
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
                  child: _Dot(index: i),
                ),
            ],
          ),
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

  Widget _composer(TextTheme text, ChatState chat) {
    final bool posted = chat.phase == ChatPhase.posted;
    final String hint = switch (chat.phase) {
      ChatPhase.awaitingPrice => 'Enter your price in EGP…',
      ChatPhase.awaitingConfirm => 'Reply yes to post, or no to change…',
      ChatPhase.posted => 'Request posted',
      ChatPhase.gathering => 'Message the assistant…',
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl,
          AppSpacing.md + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !posted && !chat.typing,
              textInputAction: TextInputAction.send,
              keyboardType: chat.phase == ChatPhase.awaitingPrice
                  ? TextInputType.number
                  : TextInputType.text,
              onSubmitted: _send,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(hintText: hint),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SendButton(
            onTap: posted ? null : () => _send(_input.text),
            posted: posted,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staggered wave dot — each dot gets a phase offset so they animate in turn.
// ---------------------------------------------------------------------------
class _Dot extends StatefulWidget {
  const _Dot({required this.index});
  final int index; // 0, 1, 2

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  // Full cycle = 1 200 ms; each dot offset by 200 ms (index/6 of the cycle).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    value: widget.index / 6.0, // phase-offset: 0.0, 0.167, 0.333
  )..repeat();

  // Up → peak → down → rest pattern over the full cycle.
  late final Animation<double> _y = TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30),
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: -6, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30),
    TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: 40), // rest
  ]).animate(_c);

  // Subtle scale pulse accompanying the bounce.
  late final Animation<double> _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30),
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30),
    TweenSequenceItem<double>(
        tween: ConstantTween<double>(1.0),
        weight: 40),
  ]).animate(_c);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _y.value),
        child: Transform.scale(
          scale: _scale.value,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
            child: SizedBox(height: 7, width: 7),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubble entry animation — slide + fade in on mount, direction matches sender.
// ---------------------------------------------------------------------------
class _AnimatedBubble extends StatefulWidget {
  const _AnimatedBubble({
    required super.key,
    required this.fromUser,
    required this.child,
  });

  final bool fromUser;
  final Widget child;

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  late final Animation<double> _opacity =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(widget.fromUser ? 0.12 : -0.12, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final bool reduce =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    if (reduce) {
      _c.value = 1.0;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Send button — press scale + spring-back feedback.
// ---------------------------------------------------------------------------
class _SendButton extends StatefulWidget {
  const _SendButton({required this.onTap, required this.posted});

  final VoidCallback? onTap;
  final bool posted;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.86).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeIn),
  );

  Future<void> _onTap() async {
    if (widget.onTap == null) return;
    final bool reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduce) {
      await _c.forward();
      unawaited(_c.reverse());
    }
    widget.onTap!();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap == null ? null : _onTap,
        child: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: widget.posted
                ? AppColors.textSecondary
                : AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: widget.posted
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ],
          ),
          child: Icon(
            widget.posted
                ? Icons.check_rounded
                : Icons.arrow_upward_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
