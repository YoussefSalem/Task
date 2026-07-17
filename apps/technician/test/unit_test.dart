import 'package:flutter_test/flutter_test.dart';
import 'package:task_domain/task_domain.dart';
import 'package:technician/features/profile/technician_profile.dart';
import 'package:technician/util/money.dart';

void main() {
  group('money', () {
    test('egpLabel groups thousands', () {
      expect(egpLabel(0), 'EGP 0');
      expect(egpLabel(1250), 'EGP 1,250');
      expect(egpLabel(1000000), 'EGP 1,000,000');
    });
  });

  group('TechProfile', () {
    test('isComplete needs a name and a trade', () {
      const bare = TechProfile();
      expect(bare.isComplete, isFalse);

      const named = TechProfile(firstName: 'Sara');
      expect(named.isComplete, isFalse, reason: 'no trade yet');

      const full =
          TechProfile(firstName: 'Sara', primaryCategory: JobCategory.ac);
      expect(full.isComplete, isTrue);
    });

    test('initials fall back to ? when empty', () {
      expect(const TechProfile().initials, '?');
      expect(
          const TechProfile(firstName: 'Omar', lastName: 'Ali').initials, 'OA');
    });

    test('isVerified only when KYC approved', () {
      expect(const TechProfile(kycStatus: KycStatus.approved).isVerified, isTrue);
      expect(const TechProfile(kycStatus: KycStatus.applied).isVerified, isFalse);
    });
  });

  group('JobRequest', () {
    test('settledPrice uses the accepted offer, else the fixed price', () {
      final job = JobRequest(
        id: 'j1',
        category: JobCategory.plumbing,
        title: 'Leak',
        description: '',
        fixedPrice: 500,
        urgency: Urgency.soon,
        propertyType: PropertyType.apartment,
        locationLabel: 'Cairo',
        status: JobStatus.biddingActive,
        createdAt: DateTime(2026, 7, 1),
      );
      expect(job.settledPrice, 500);

      final hired = job.copyWith(
        status: JobStatus.accepted,
        offers: <Offer>[
          Offer(
            id: 't1',
            technicianId: 't1',
            technicianName: 'Pro',
            rating: 4.8,
            jobsDone: 30,
            etaLabel: 'Today',
            status: OfferStatus.accepted,
            proposals: <PriceProposal>[
              PriceProposal(
                  amount: 450,
                  by: ProposalAuthor.technician,
                  at: DateTime(2026, 7, 1)),
            ],
          ),
        ],
      );
      expect(hired.settledPrice, 450);
    });
  });
}
