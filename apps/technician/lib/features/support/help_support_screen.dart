import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// Self-serve help for pros: the common questions, plus how to reach a human.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String routeName = 'help-support';
  static const String routePath = '/help';

  static const List<({String q, String a})> _faqs = <({String q, String a})>[
    (
      q: 'How do bids work?',
      a: 'Open a job, name your price and arrival window, and send. The customer '
          'can accept, decline, or counter. You can update or withdraw your bid '
          'any time before they hire someone.'
    ),
    (
      q: 'When do I get paid?',
      a: 'You settle the agreed price with the customer on completion. Your '
          'earnings and available payout balance appear on the Earnings tab.'
    ),
    (
      q: 'Why am I not seeing jobs?',
      a: 'Make sure you are online on the Dashboard. New jobs appear the moment a '
          'customer posts one in your area.'
    ),
    (
      q: 'How does live location work?',
      a: 'On an active job, turn on “Share live location” so the customer can '
          'watch you approach. It stops automatically when you complete the job.'
    ),
    (
      q: 'How do I raise my rating?',
      a: 'Arrive on time, communicate through chat, and finish the work well. '
          'Customers rate you after each completed job.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & support'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.support_agent_rounded, color: scheme.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Need a hand?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Email support@taskpro.app and we’ll get back within '
                          'one business day.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Frequently asked'),
          const SizedBox(height: AppSpacing.sm),
          ..._faqs.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    childrenPadding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    title: Text(f.q,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(f.a,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5)),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
