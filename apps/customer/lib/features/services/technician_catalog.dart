import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

/// A bookable professional shown on the home dashboard. Prototype data — the
/// live roster will come from Firestore once dispatch lands.
@immutable
class Technician {
  const Technician({
    required this.id,
    required this.name,
    required this.specialty,
    required this.jobsLabel,
    required this.rating,
    required this.badge,
    required this.hourlyRate,
    required this.photoUrl,
    required this.serviceId,
  });

  final String id;
  final String name;
  final String specialty;
  final String jobsLabel;
  final double rating;
  final TechBadge badge;
  final int hourlyRate;
  final String photoUrl;

  /// The service this pro is booked for when tapped.
  final String serviceId;

  String get initials =>
      name.split(' ').map((String s) => s[0]).take(2).join();

  JobCategory get category => switch (serviceId) {
        'plumb_leak' => JobCategory.plumbing,
        'elec_fault' => JobCategory.electrical,
        'ac_service' => JobCategory.ac,
        _ => JobCategory.plumbing,
      };
}

/// Trust tiers shown as a chip on each technician card.
enum TechBadge { pro, expert, platinum }

extension TechBadgeX on TechBadge {
  String get label => switch (this) {
        TechBadge.pro => 'PRO',
        TechBadge.expert => 'EXPERT',
        TechBadge.platinum => 'PLATINUM',
      };

  Color get tint => switch (this) {
        TechBadge.pro => AppColors.success,
        TechBadge.expert => AppColors.primary,
        TechBadge.platinum => AppColors.warning,
      };
}

const List<Technician> kTechnicians = <Technician>[
  Technician(
    id: 't1',
    name: 'Mohamed Ali',
    specialty: 'Plumbing Specialist',
    jobsLabel: '150+ Jobs',
    rating: 4.9,
    badge: TechBadge.expert,
    hourlyRate: 350,
    photoUrl: 'https://i.pravatar.cc/160?img=12',
    serviceId: 'plumb_leak',
  ),
  Technician(
    id: 't2',
    name: 'Sara Hassan',
    specialty: 'Electrical Expert',
    jobsLabel: '210+ Jobs',
    rating: 5.0,
    badge: TechBadge.platinum,
    hourlyRate: 400,
    photoUrl: 'https://i.pravatar.cc/160?img=45',
    serviceId: 'elec_fault',
  ),
  Technician(
    id: 't3',
    name: 'Karim Fouad',
    specialty: 'AC Technician',
    jobsLabel: '320+ Jobs',
    rating: 4.8,
    badge: TechBadge.expert,
    hourlyRate: 380,
    photoUrl: 'https://i.pravatar.cc/160?img=33',
    serviceId: 'ac_service',
  ),
];
