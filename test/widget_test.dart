import 'package:flutter_test/flutter_test.dart';
import 'package:jomimpact/models/event_model.dart';
import 'package:jomimpact/models/marketplace_model.dart';
import 'package:jomimpact/models/user_model.dart';
import 'package:jomimpact/services/event_registration_export_service.dart';

void main() {
  group('MarketplacePurchaseModel', () {
    test('round-trips postage and order information', () {
      final createdAt = DateTime(2026, 6, 29, 10, 30);
      final order = MarketplacePurchaseModel(
        id: 'abcdefgh-1234',
        itemId: 'item-1',
        itemTitle: 'Community Tote Bag',
        organizerId: 'organizer-1',
        buyerId: 'buyer-1',
        buyerName: 'Aina Rahman',
        buyerEmail: 'aina@example.com',
        recipientName: 'Aina Rahman',
        phone: '0123456789',
        addressLine1: '12 Jalan Harmoni',
        city: 'Shah Alam',
        state: 'Selangor',
        postcode: '40100',
        price: 35,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final restored = MarketplacePurchaseModel.fromMap(order.toMap());

      expect(restored.orderNumber, 'ABCDEFGH');
      expect(restored.formattedAddress,
          '12 Jalan Harmoni, 40100 Shah Alam, Selangor, Malaysia');
      expect(restored.status, MarketplacePurchaseStatus.confirmed);
      expect(restored.paymentStatus, MarketplacePaymentStatus.notCollected);
    });

    test('reads legacy pending-payment records as confirmed orders', () {
      final restored = MarketplacePurchaseModel.fromMap({
        'id': 'legacy-1',
        'itemId': 'item-1',
        'itemTitle': 'Legacy item',
        'organizerId': 'organizer-1',
        'buyerId': 'buyer-1',
        'buyerName': 'Legacy buyer',
        'price': 20,
        'status': 'pendingPayment',
        'createdAt': '2026-06-01T10:00:00.000',
      });

      expect(restored.status, MarketplacePurchaseStatus.confirmed);
      expect(restored.country, 'Malaysia');
    });
  });

  test('legacy marketplace listings default to available', () {
    final item = MarketplaceItemModel.fromMap({
      'id': 'item-1',
      'organizerId': 'organizer-1',
      'organizerName': 'Community Kitchen',
      'title': 'Reusable Bag',
      'description': 'A reusable community tote bag.',
      'price': 25,
      'status': 'approved',
      'createdAt': '2026-06-01T10:00:00.000',
    });

    expect(item.isAvailable, isTrue);
  });

  test('filtered applicant export creates safe Excel-friendly CSV', () {
    final application = ApplicationModel(
      id: 'application-1',
      eventId: 'event-1',
      eventTitle: 'Community Cleanup',
      volunteerId: 'volunteer-1',
      volunteerName: 'Fallback name',
      volunteerPhotoUrl: '',
      status: ApplicationStatus.accepted,
      appliedAt: DateTime(2026, 6, 29, 14, 5),
    );
    final volunteer = UserModel(
      id: 'volunteer-1',
      name: '=Unsafe, "Name"',
      email: 'volunteer@example.com',
      phone: '0123456789',
      role: UserRole.volunteer,
      createdAt: DateTime(2026, 1, 1),
    );

    final csv = EventRegistrationExportService().buildCsv(
      applications: [application],
      volunteers: {'volunteer-1': volunteer},
    );

    expect(csv, contains('"Volunteer name","Email","Phone"'));
    expect(csv, contains('"\'=Unsafe, ""Name"""'));
    expect(csv, contains('"Accepted","2026-06-29 14:05"'));
  });
}
