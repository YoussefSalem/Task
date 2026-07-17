import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// Terms and Privacy in one screen, switched by the `kind` query param. Static
/// placeholder copy for v1 — swap for the finalized legal text before launch.
class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.kind, super.key});

  final String kind; // 'terms' | 'privacy'

  static const String routeName = 'legal';
  static const String routePath = '/legal';

  bool get _isTerms => kind != 'privacy';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<({String h, String b})> sections =
        _isTerms ? _terms : _privacy;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTerms ? 'Terms of service' : 'Privacy policy'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text('Last updated: July 2026',
              style: text.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              )),
          const SizedBox(height: AppSpacing.lg),
          ...sections.expand((s) => <Widget>[
                Text(s.h,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.xs),
                Text(s.b, style: text.bodyMedium?.copyWith(height: 1.55)),
                const SizedBox(height: AppSpacing.lg),
              ]),
        ],
      ),
    );
  }

  static const List<({String h, String b})> _terms = <({String h, String b})>[
    (
      h: '1. Your account',
      b: 'You are responsible for the accuracy of your profile, trade, and the '
          'work you agree to perform. Keep your login secure.'
    ),
    (
      h: '2. Bids and jobs',
      b: 'A bid is a genuine offer to do the work at the stated price and time. '
          'Once a customer hires you, complete the job professionally and on '
          'schedule, or cancel promptly if you cannot.'
    ),
    (
      h: '3. Payments',
      b: 'You settle the agreed amount directly with the customer unless an '
          'in-app payment method is used. Task Pro is not a party to that '
          'transaction.'
    ),
    (
      h: '4. Conduct',
      b: 'Treat customers respectfully, honor quoted prices, and follow local '
          'laws and safety standards. Abuse or fraud may end your access.'
    ),
    (
      h: '5. Liability',
      b: 'Task Pro connects you with customers but does not guarantee jobs, '
          'income, or outcomes, and is not liable for work performed off-platform.'
    ),
  ];

  static const List<({String h, String b})> _privacy = <({String h, String b})>[
    (
      h: 'What we collect',
      b: 'Your name, phone number, trade, and the jobs and messages you exchange '
          'on the platform. With your permission, your device location while you '
          'share it on an active job.'
    ),
    (
      h: 'How we use it',
      b: 'To match you with nearby jobs, let customers track your arrival, show '
          'your public profile (name, trade, rating), and keep the service safe.'
    ),
    (
      h: 'Location',
      b: 'Live location is shared only while you turn it on for an active job, '
          'and stops automatically when the job is complete.'
    ),
    (
      h: 'Your controls',
      b: 'Edit your profile any time, and delete your account from Settings, '
          'which removes your login and device tokens.'
    ),
  ];
}
