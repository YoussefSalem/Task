import 'package:customer/l10n/app_localizations.dart';
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
  String label(AppLocalizations l) => switch (this) {
        TechBadge.pro => l.badgePro,
        TechBadge.expert => l.badgeExpert,
        TechBadge.platinum => l.badgePlatinum,
      };

  Color get tint => switch (this) {
        TechBadge.pro => AppColors.success,
        TechBadge.expert => AppColors.primary,
        TechBadge.platinum => AppColors.warning,
      };
}

/// Prototype roster, localized on demand. Names and specialties resolve from
/// the active locale so the home dashboard shows no foreign-language text.
List<Technician> technicians(AppLocalizations l) => <Technician>[
      Technician(
        id: 't1',
        name: l.techNameMohamed,
        specialty: l.specialtyPlumbing,
        jobsLabel: l.jobsCountLabel(150),
        rating: 4.9,
        badge: TechBadge.expert,
        hourlyRate: 350,
        photoUrl: 'https://i.pravatar.cc/160?img=12',
        serviceId: 'plumb_leak',
      ),
      Technician(
        id: 't2',
        name: l.techNameSara,
        specialty: l.specialtyElectrical,
        jobsLabel: l.jobsCountLabel(210),
        rating: 5.0,
        badge: TechBadge.platinum,
        hourlyRate: 400,
        photoUrl: 'https://i.pravatar.cc/160?img=45',
        serviceId: 'elec_fault',
      ),
      Technician(
        id: 't3',
        name: l.techNameKarim,
        specialty: l.specialtyAc,
        jobsLabel: l.jobsCountLabel(320),
        rating: 4.8,
        badge: TechBadge.expert,
        hourlyRate: 380,
        photoUrl: 'https://i.pravatar.cc/160?img=33',
        serviceId: 'ac_service',
      ),
    ];
