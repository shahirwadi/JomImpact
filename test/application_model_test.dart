import 'package:flutter_test/flutter_test.dart';
import 'package:jomimpact/models/event_model.dart';

void main() {
  test('application pipeline fields round-trip through Firestore map', () {
    final reviewedAt = DateTime(2026, 6, 19, 10, 30);
    final withdrawnAt = DateTime(2026, 6, 20, 9);
    final application = ApplicationModel(
      id: 'app-1',
      eventId: 'event-1',
      eventTitle: 'Community Cleanup',
      volunteerId: 'volunteer-1',
      volunteerName: 'Aina',
      volunteerPhotoUrl: '',
      status: ApplicationStatus.withdrawn,
      reviewedBy: 'organizer-1',
      reviewedAt: reviewedAt,
      withdrawnAt: withdrawnAt,
      appliedAt: DateTime(2026, 6, 18),
    );

    final restored = ApplicationModel.fromMap(application.toMap());

    expect(restored.status, ApplicationStatus.withdrawn);
    expect(restored.reviewedBy, 'organizer-1');
    expect(restored.reviewedAt, reviewedAt);
    expect(restored.withdrawnAt, withdrawnAt);
    expect(application.toMap().containsKey('reviewNotes'), isFalse);
  });

  test('legacy pending applications remain the New pipeline stage', () {
    final application = ApplicationModel.fromMap({
      'id': 'app-2',
      'eventId': 'event-1',
      'eventTitle': 'Community Cleanup',
      'volunteerId': 'volunteer-2',
      'volunteerName': 'Kumar',
      'status': 'pending',
      'appliedAt': DateTime(2026, 6, 18).toIso8601String(),
    });

    expect(application.status, ApplicationStatus.pending);
    expect(application.attendanceStatus, AttendanceStatus.pending);
    expect(application.impactPoints, 0);
  });

  test('impact badge thresholds and progress are deterministic', () {
    const bronze = ImpactSummary(points: 250, hours: 25, events: 2);
    const silver = ImpactSummary(points: 750, hours: 75, events: 5);
    const gold = ImpactSummary(points: 1500, hours: 150, events: 10);

    expect(bronze.badge, ImpactBadge.bronze);
    expect(bronze.nextThreshold, ImpactSummary.silverPoints);
    expect(silver.badge, ImpactBadge.silver);
    expect(gold.badge, ImpactBadge.gold);
    expect(gold.progress, 1);
  });
}
