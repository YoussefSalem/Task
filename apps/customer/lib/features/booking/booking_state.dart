import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/service_catalog.dart';

/// The three v1 booking engines (design spec §2).
enum BookingMode { asap, scheduled, quote }

extension BookingModeX on BookingMode {
  String get label => switch (this) {
        BookingMode.asap => 'Book now',
        BookingMode.scheduled => 'Schedule',
        BookingMode.quote => 'Get quotes',
      };

  String get blurb => switch (this) {
        BookingMode.asap =>
          'We dispatch the nearest available pro to you right now.',
        BookingMode.scheduled =>
          'Pick a date and time that works, and we lock a pro in advance.',
        BookingMode.quote =>
          'Describe the job and compare sealed offers from up to 5 pros.',
      };

  IconData get icon => switch (this) {
        BookingMode.asap => Icons.flash_on_rounded,
        BookingMode.scheduled => Icons.event_rounded,
        BookingMode.quote => Icons.gavel_rounded,
      };
}

/// How the customer pays (design spec §2 payments).
enum PaymentMethod { cash, card, wallet, instapay }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash on delivery',
        PaymentMethod.card => 'Card',
        PaymentMethod.wallet => 'Vodafone Cash',
        PaymentMethod.instapay => 'InstaPay',
      };

  String get sub => switch (this) {
        PaymentMethod.cash => 'Pay the pro directly when the job is done',
        PaymentMethod.card => 'Visa, Mastercard, Meeza · via Paymob',
        PaymentMethod.wallet => 'Pay from your mobile wallet',
        PaymentMethod.instapay => 'Bank transfer, confirmed by our team',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_rounded,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.wallet => Icons.account_balance_wallet_rounded,
        PaymentMethod.instapay => Icons.account_balance_rounded,
      };
}

@immutable
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line,
    required this.icon,
  });

  final String id;
  final String label;
  final String line;
  final IconData icon;
}

const List<SavedAddress> kSavedAddresses = <SavedAddress>[
  SavedAddress(
    id: 'home',
    label: 'Home',
    line: '14 Road 9, Maadi · Floor 3, Apt 6',
    icon: Icons.home_rounded,
  ),
  SavedAddress(
    id: 'work',
    label: 'Work',
    line: 'Smart Village, Building B12 · Reception',
    icon: Icons.work_rounded,
  ),
];

/// A sealed bid from a pro (quote engine).
@immutable
class Bid {
  const Bid({
    required this.id,
    required this.proName,
    required this.rating,
    required this.jobsDone,
    required this.price,
    required this.etaLabel,
    required this.note,
  });

  final String id;
  final String proName;
  final double rating;
  final int jobsDone;
  final int price;
  final String etaLabel;
  final String note;
}

const List<Bid> kBids = <Bid>[
  Bid(
    id: 'b1',
    proName: 'Khaled Mansour',
    rating: 4.9,
    jobsDone: 1284,
    price: 165,
    etaLabel: 'Can start in 40 min',
    note: 'I carry spare valves and seals, no second trip needed.',
  ),
  Bid(
    id: 'b2',
    proName: 'Sayed Abdel-Rahman',
    rating: 4.7,
    jobsDone: 612,
    price: 140,
    etaLabel: 'Available this evening',
    note: 'Fixed-price including parts under 50 EGP.',
  ),
  Bid(
    id: 'b3',
    proName: 'Mostafa Eid',
    rating: 4.8,
    jobsDone: 903,
    price: 190,
    etaLabel: 'Can start in 25 min',
    note: 'Closest to you, 1.2 km away.',
  ),
];

/// Live stages used by the tracking screen (subset of the job state machine).
enum JobStage { searching, accepted, enRoute, inProgress, completed }

extension JobStageX on JobStage {
  String get title => switch (this) {
        JobStage.searching => 'Finding your pro',
        JobStage.accepted => 'Pro assigned',
        JobStage.enRoute => 'On the way',
        JobStage.inProgress => 'Work in progress',
        JobStage.completed => 'Job complete',
      };
}

/// The in-progress booking the customer is assembling.
@immutable
class BookingDraft {
  const BookingDraft({
    this.serviceId,
    this.mode = BookingMode.asap,
    this.addressId = 'home',
    this.scheduledFor,
    this.notes = '',
    this.selectedBidId,
    this.payment = PaymentMethod.cash,
  });

  final String? serviceId;
  final BookingMode mode;
  final String addressId;
  final DateTime? scheduledFor;
  final String notes;
  final String? selectedBidId;
  final PaymentMethod payment;

  Service? get service => serviceId == null ? null : serviceById(serviceId!);
  SavedAddress get address =>
      kSavedAddresses.firstWhere((SavedAddress a) => a.id == addressId,
          orElse: () => kSavedAddresses.first);
  Bid? get selectedBid => selectedBidId == null
      ? null
      : kBids.firstWhere((Bid b) => b.id == selectedBidId);

  /// Total in EGP — bid price wins for the quote engine, else service base.
  int get total => selectedBid?.price ?? service?.basePrice ?? 0;

  BookingDraft copyWith({
    String? serviceId,
    BookingMode? mode,
    String? addressId,
    DateTime? scheduledFor,
    bool clearSchedule = false,
    String? notes,
    String? selectedBidId,
    bool clearBid = false,
    PaymentMethod? payment,
  }) {
    return BookingDraft(
      serviceId: serviceId ?? this.serviceId,
      mode: mode ?? this.mode,
      addressId: addressId ?? this.addressId,
      scheduledFor: clearSchedule ? null : (scheduledFor ?? this.scheduledFor),
      notes: notes ?? this.notes,
      selectedBidId: clearBid ? null : (selectedBidId ?? this.selectedBidId),
      payment: payment ?? this.payment,
    );
  }
}

/// Holds the draft the customer is building across the booking flow.
class BookingController extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();

  void start(String serviceId) =>
      state = BookingDraft(serviceId: serviceId);
  void setMode(BookingMode mode) => state = state.copyWith(mode: mode);
  void setAddress(String id) => state = state.copyWith(addressId: id);
  void setSchedule(DateTime when) => state = state.copyWith(scheduledFor: when);
  void setNotes(String notes) => state = state.copyWith(notes: notes);
  void selectBid(String id) => state = state.copyWith(selectedBidId: id);
  void setPayment(PaymentMethod m) => state = state.copyWith(payment: m);
  void reset() => state = const BookingDraft();
}

final bookingProvider =
    NotifierProvider<BookingController, BookingDraft>(BookingController.new);

/// A completed booking shown in the Bookings tab.
@immutable
class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.serviceId,
    required this.whenLabel,
    required this.total,
    required this.status,
    required this.completed,
  });

  final String id;
  final String serviceId;
  final String whenLabel;
  final int total;
  final String status;
  final bool completed;

  Service get service => serviceById(serviceId);
}

/// Seeded history + the live one the customer just booked gets prepended.
class BookingsController extends Notifier<List<BookingRecord>> {
  @override
  List<BookingRecord> build() => const <BookingRecord>[
        BookingRecord(
          id: 'TK-4821',
          serviceId: 'ac_service',
          whenLabel: 'Today · 2:40 PM',
          total: 240,
          status: 'In progress',
          completed: false,
        ),
        BookingRecord(
          id: 'TK-4790',
          serviceId: 'elec_fault',
          whenLabel: 'Yesterday · 6:15 PM',
          total: 150,
          status: 'Completed',
          completed: true,
        ),
        BookingRecord(
          id: 'TK-4711',
          serviceId: 'deep_clean',
          whenLabel: 'Mar 12 · 11:00 AM',
          total: 320,
          status: 'Completed',
          completed: true,
        ),
      ];

  void add(BookingRecord record) => state = <BookingRecord>[record, ...state];
}

final bookingsProvider =
    NotifierProvider<BookingsController, List<BookingRecord>>(
        BookingsController.new);
