import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// A bookable home service. Prototype data — the live catalog will come from
/// Firestore once the booking backend lands.
@immutable
class Service {
  const Service({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.tint,
    required this.basePrice,
    required this.durationLabel,
    required this.rating,
    required this.jobsDone,
  });

  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color tint;

  /// Starting price in EGP.
  final int basePrice;
  final String durationLabel;
  final double rating;
  final int jobsDone;
}

@immutable
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// The home grid categories.
const List<ServiceCategory> kCategories = <ServiceCategory>[
  ServiceCategory(id: 'all', label: 'All', icon: Icons.grid_view_rounded),
  ServiceCategory(
      id: 'plumbing', label: 'Plumbing', icon: Icons.plumbing_rounded),
  ServiceCategory(
      id: 'electrical', label: 'Electrical', icon: Icons.bolt_rounded),
  ServiceCategory(id: 'ac', label: 'AC & Cooling', icon: Icons.ac_unit_rounded),
  ServiceCategory(
      id: 'cleaning', label: 'Cleaning', icon: Icons.cleaning_services_rounded),
  ServiceCategory(
      id: 'carpentry', label: 'Carpentry', icon: Icons.handyman_rounded),
  ServiceCategory(id: 'painting', label: 'Painting', icon: Icons.format_paint_rounded),
];

/// Prototype service list. Realistic copy, organic numbers.
const List<Service> kServices = <Service>[
  Service(
    id: 'plumb_leak',
    name: 'Leak & pipe repair',
    tagline: 'Stop drips, fix burst pipes, clear blockages',
    icon: Icons.plumbing_rounded,
    tint: Color(0xFF38BDF8),
    basePrice: 180,
    durationLabel: '45-90 min',
    rating: 4.8,
    jobsDone: 2140,
  ),
  Service(
    id: 'elec_fault',
    name: 'Electrical fault',
    tagline: 'Tripping breakers, dead sockets, wiring faults',
    icon: Icons.bolt_rounded,
    tint: Color(0xFFFBBF24),
    basePrice: 150,
    durationLabel: '30-75 min',
    rating: 4.7,
    jobsDone: 1876,
  ),
  Service(
    id: 'ac_service',
    name: 'AC service & gas refill',
    tagline: 'Clean, recharge and tune split or window units',
    icon: Icons.ac_unit_rounded,
    tint: Color(0xFF22D3EE),
    basePrice: 240,
    durationLabel: '60-120 min',
    rating: 4.9,
    jobsDone: 3312,
  ),
  Service(
    id: 'deep_clean',
    name: 'Deep home cleaning',
    tagline: 'Full apartment scrub, kitchens and bathrooms',
    icon: Icons.cleaning_services_rounded,
    tint: Color(0xFF34D399),
    basePrice: 320,
    durationLabel: '2-4 hrs',
    rating: 4.6,
    jobsDone: 1502,
  ),
  Service(
    id: 'carpentry',
    name: 'Carpentry & fittings',
    tagline: 'Doors, shelves, cabinets and furniture repair',
    icon: Icons.handyman_rounded,
    tint: Color(0xFFF472B6),
    basePrice: 200,
    durationLabel: '1-3 hrs',
    rating: 4.7,
    jobsDone: 980,
  ),
  Service(
    id: 'painting',
    name: 'Wall painting',
    tagline: 'Touch-ups to full rooms, materials included',
    icon: Icons.format_paint_rounded,
    tint: Color(0xFFA78BFA),
    basePrice: 280,
    durationLabel: '3-6 hrs',
    rating: 4.5,
    jobsDone: 744,
  ),
];

Service serviceById(String id) =>
    kServices.firstWhere((Service s) => s.id == id, orElse: () => kServices.first);

/// Maps a category id onto the services that belong to it.
List<Service> servicesForCategory(String categoryId) {
  if (categoryId == 'all') return kServices;
  const Map<String, List<String>> map = <String, List<String>>{
    'plumbing': <String>['plumb_leak'],
    'electrical': <String>['elec_fault'],
    'ac': <String>['ac_service'],
    'cleaning': <String>['deep_clean'],
    'carpentry': <String>['carpentry'],
    'painting': <String>['painting'],
  };
  final List<String> ids = map[categoryId] ?? const <String>[];
  return kServices.where((Service s) => ids.contains(s.id)).toList();
}

/// Brand-tinted accent used for the service tile glow.
Color serviceGlow(Service s) => s.tint.withValues(alpha: 0.18);

const Color kBrand = AppColors.primary;
