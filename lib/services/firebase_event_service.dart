// lib/services/firebase_event_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../utils/enum_utils.dart';

class FirebaseEventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Collections ────────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');
  CollectionReference<Map<String, dynamic>> get _applications =>
      _db.collection('applications');
  CollectionReference<Map<String, dynamic>> get _applicationReviews =>
      _db.collection('applicationReviews');
  CollectionReference<Map<String, dynamic>> get _impactAwards =>
      _db.collection('impactAwards');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ══════════════════════════════════════════════════════════════
  // EVENTS
  // ══════════════════════════════════════════════════════════════

  /// All published events (volunteer browse feed)
  Future<List<EventModel>> getAllPublishedEvents() async {
    final snap = await _events
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
  }

  /// Real-time stream for published events
  Stream<List<EventModel>> publishedEventsStream() {
    return _events
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => EventModel.fromMap(d.data())).toList());
  }

  /// Events created by a specific organizer
  Future<List<EventModel>> getOrganizerEvents(String organizerId) async {
    final snap = await _events
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
  }

  /// Real-time stream of organizer's own events
  Stream<List<EventModel>> organizerEventsStream(String organizerId) {
    return _events
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => EventModel.fromMap(d.data())).toList());
  }

  /// Fetch single event by ID
  Future<EventModel?> getEventById(String id) async {
    final doc = await _events.doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromMap(doc.data()!);
  }

  /// Create new event
  Future<EventModel> createEvent(EventModel event) async {
    await _events.doc(event.id).set(event.toMap());

    // Increment organizer's totalEvents counter
    await _users.doc(event.organizerId).update({
      'totalEvents': FieldValue.increment(1),
    });

    return event;
  }

  /// Update existing event
  Future<void> updateEvent(EventModel event) async {
    await _events.doc(event.id).update(event.toMap());
  }

  Future<void> markEventCompleted(String eventId) async {
    await _db.runTransaction((tx) async {
      final eventRef = _events.doc(eventId);
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw Exception('event_not_found');
      final event = EventModel.fromMap(eventSnap.data()!);
      if (event.status == EventStatus.finalized) {
        throw Exception('event_already_finalized');
      }
      if (event.endDate.isAfter(DateTime.now())) {
        throw Exception('event_not_finished');
      }
      tx.update(eventRef, {'status': enumValueName(EventStatus.completed)});
    });
  }

  /// Delete event and its applications
  Future<void> deleteEvent(String eventId, String organizerId) async {
    final batch = _db.batch();

    // Delete the event
    batch.delete(_events.doc(eventId));

    // Delete all related applications
    final appSnap =
        await _applications.where('eventId', isEqualTo: eventId).get();
    for (final doc in appSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Decrement organizer totalEvents
    await _users.doc(organizerId).update({
      'totalEvents': FieldValue.increment(-1),
    });
  }

  // ══════════════════════════════════════════════════════════════
  // APPLICATIONS
  // ══════════════════════════════════════════════════════════════

  /// Apply for an event
  Future<ApplicationModel> applyForEvent({
    required String eventId,
    required String eventTitle,
    required UserModel volunteer,
    String? message,
  }) async {
    // Check duplicate
    final existing = await _applications
        .where('eventId', isEqualTo: eventId)
        .where('volunteerId', isEqualTo: volunteer.id)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('already_applied');
    }

    final eventDoc = await _events.doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('event_not_found');
    }

    final event = EventModel.fromMap(eventDoc.data()!);
    if (event.status != EventStatus.published) {
      throw Exception('event_not_open');
    }
    if (event.isFull) {
      throw Exception('event_full');
    }

    final app = ApplicationModel(
      id: _uuid.v4(),
      eventId: eventId,
      eventTitle: eventTitle,
      volunteerId: volunteer.id,
      volunteerName: volunteer.name,
      volunteerPhotoUrl: volunteer.photoUrl ?? '',
      volunteerBio: volunteer.bio,
      status: ApplicationStatus.pending,
      message: message,
      reviewNotes: null,
      reviewedBy: null,
      reviewedAt: null,
      withdrawnAt: null,
      appliedAt: DateTime.now(),
    );

    final batch = _db.batch();

    // Write application
    batch.set(_applications.doc(app.id), app.toMap());

    await batch.commit();
    return app;
  }

  /// Get applications for a specific event (organizer view)
  Future<List<ApplicationModel>> getApplicationsForEvent(String eventId) async {
    final snap = await _applications
        .where('eventId', isEqualTo: eventId)
        .orderBy('appliedAt', descending: true)
        .get();
    return _withReviewNotes(eventId, snap.docs.map((d) => d.data()).toList());
  }

  /// Real-time stream of applications for an event
  Stream<List<ApplicationModel>> applicationsForEventStream(String eventId) {
    return _applications
        .where('eventId', isEqualTo: eventId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snap) =>
            _withReviewNotes(eventId, snap.docs.map((d) => d.data()).toList()));
  }

  /// Get all applications submitted by a volunteer
  Future<List<ApplicationModel>> getApplicationsForVolunteer(
      String volunteerId) async {
    final snap = await _applications
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('appliedAt', descending: true)
        .get();
    return snap.docs.map((d) => ApplicationModel.fromMap(d.data())).toList();
  }

  /// Stream of volunteer's own applications
  Stream<List<ApplicationModel>> volunteerApplicationsStream(
      String volunteerId) {
    return _applications
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ApplicationModel.fromMap(d.data())).toList());
  }

  /// Update an application while keeping event capacity in sync.
  Future<void> updateApplicationStatus(
    String appId,
    ApplicationStatus status, {
    required String reviewedBy,
    String? reviewNotes,
  }) async {
    String? applicationEventId;
    await _db.runTransaction((tx) async {
      final appRef = _applications.doc(appId);
      final appSnap = await tx.get(appRef);
      if (!appSnap.exists) {
        throw Exception('application_not_found');
      }

      final app = ApplicationModel.fromMap(appSnap.data()!);
      applicationEventId = app.eventId;
      final currentStatus = app.status;
      if (currentStatus == ApplicationStatus.withdrawn) {
        throw Exception('application_withdrawn');
      }
      final eventRef = _events.doc(app.eventId);
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) {
        throw Exception('event_not_found');
      }

      final event = EventModel.fromMap(eventSnap.data()!);
      if (event.status == EventStatus.completed ||
          event.status == EventStatus.finalized ||
          event.status == EventStatus.cancelled) {
        throw Exception('application_review_closed');
      }
      var volunteerDelta = 0;

      if (currentStatus != ApplicationStatus.accepted &&
          status == ApplicationStatus.accepted) {
        if (event.isFull) {
          throw Exception('event_full');
        }
        volunteerDelta = 1;
      } else if (currentStatus == ApplicationStatus.accepted &&
          status != ApplicationStatus.accepted) {
        volunteerDelta = -1;
      }

      final reviewedAt = DateTime.now().toIso8601String();
      tx.update(appRef, {
        'status': enumValueName(status),
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt,
      });
      if (volunteerDelta != 0) {
        tx.update(eventRef, {
          'currentVolunteers': FieldValue.increment(volunteerDelta),
        });
      }
    });

    // Notes are optional metadata. Keep them outside the capacity transaction
    // so a stale rules deployment cannot roll back the status change.
    final eventId = applicationEventId;
    if (eventId == null) return;
    try {
      await _applicationReviews.doc(appId).set({
        'applicationId': appId,
        'eventId': eventId,
        'reviewNotes':
            reviewNotes?.trim().isEmpty == true ? null : reviewNotes?.trim(),
        'reviewedBy': reviewedBy,
        'reviewedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }
  }

  Future<void> withdrawApplication(String appId, String volunteerId) async {
    await _db.runTransaction((tx) async {
      final appRef = _applications.doc(appId);
      final appSnap = await tx.get(appRef);
      if (!appSnap.exists) throw Exception('application_not_found');

      final app = ApplicationModel.fromMap(appSnap.data()!);
      if (app.volunteerId != volunteerId) {
        throw Exception('not_application_owner');
      }
      if (app.status == ApplicationStatus.withdrawn ||
          app.status == ApplicationStatus.rejected) {
        throw Exception('application_closed');
      }

      final eventRef = _events.doc(app.eventId);
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw Exception('event_not_found');
      final event = EventModel.fromMap(eventSnap.data()!);
      if (event.status == EventStatus.completed ||
          event.status == EventStatus.finalized ||
          event.status == EventStatus.cancelled) {
        throw Exception('application_withdrawal_closed');
      }
      if (app.status == ApplicationStatus.accepted) {
        tx.update(eventRef, {'currentVolunteers': FieldValue.increment(-1)});
      }
      tx.update(appRef, {
        'status': enumValueName(ApplicationStatus.withdrawn),
        'withdrawnAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> reviewAttendance({
    required String appId,
    required AttendanceStatus attendanceStatus,
    required int verifiedHours,
    required String reviewedBy,
  }) async {
    if (verifiedHours < 0 ||
        ((attendanceStatus == AttendanceStatus.attended ||
                attendanceStatus == AttendanceStatus.partial) &&
            verifiedHours == 0) ||
        ((attendanceStatus == AttendanceStatus.noShow ||
                attendanceStatus == AttendanceStatus.excused) &&
            verifiedHours != 0)) {
      throw Exception('invalid_attendance_hours');
    }

    await _db.runTransaction((tx) async {
      final appRef = _applications.doc(appId);
      final appSnap = await tx.get(appRef);
      if (!appSnap.exists) throw Exception('application_not_found');
      final app = ApplicationModel.fromMap(appSnap.data()!);
      if (app.status != ApplicationStatus.accepted) {
        throw Exception('application_not_accepted');
      }

      final eventSnap = await tx.get(_events.doc(app.eventId));
      if (!eventSnap.exists) throw Exception('event_not_found');
      final event = EventModel.fromMap(eventSnap.data()!);
      if (event.status != EventStatus.completed) {
        throw Exception('event_not_completed');
      }

      tx.update(appRef, {
        'attendanceStatus': enumValueName(attendanceStatus),
        'verifiedHours': verifiedHours,
        'attendanceReviewedBy': reviewedBy,
        'attendanceReviewedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> finalizeEvent(String eventId, String organizerId) async {
    final accepted = await _applications
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: enumValueName(ApplicationStatus.accepted))
        .get();

    await _db.runTransaction((tx) async {
      final eventRef = _events.doc(eventId);
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw Exception('event_not_found');
      final event = EventModel.fromMap(eventSnap.data()!);
      if (event.organizerId != organizerId) throw Exception('not_event_owner');
      if (event.status == EventStatus.finalized) return;
      if (event.status != EventStatus.completed) {
        throw Exception('event_not_completed');
      }

      final applications = <ApplicationModel>[];
      for (final doc in accepted.docs) {
        final current = await tx.get(doc.reference);
        if (!current.exists) continue;
        final app = ApplicationModel.fromMap(current.data()!);
        if (app.status == ApplicationStatus.accepted) applications.add(app);
      }
      if (applications
          .any((app) => app.attendanceStatus == AttendanceStatus.pending)) {
        throw Exception('attendance_incomplete');
      }

      final awardedAt = DateTime.now().toIso8601String();
      for (final app in applications) {
        final earnsPoints = app.attendanceStatus == AttendanceStatus.attended ||
            app.attendanceStatus == AttendanceStatus.partial;
        final points = earnsPoints ? app.verifiedHours * 10 : 0;
        tx.update(_applications.doc(app.id), {
          'impactPoints': points,
          'pointsAwardedAt': awardedAt,
        });
        if (points > 0) {
          tx.set(_impactAwards.doc('${eventId}_${app.volunteerId}'), {
            'eventId': eventId,
            'eventTitle': event.title,
            'applicationId': app.id,
            'volunteerId': app.volunteerId,
            'hours': app.verifiedHours,
            'points': points,
            'awardedAt': awardedAt,
            'awardedBy': organizerId,
          });
        }
      }
      tx.update(eventRef, {
        'status': enumValueName(EventStatus.finalized),
        'finalizedAt': awardedAt,
      });
    });
  }

  Stream<ImpactSummary> impactSummaryStream(String volunteerId) {
    return _impactAwards
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots()
        .map((snapshot) {
      var points = 0;
      var hours = 0;
      for (final doc in snapshot.docs) {
        points += (doc.data()['points'] as num? ?? 0).toInt();
        hours += (doc.data()['hours'] as num? ?? 0).toInt();
      }
      return ImpactSummary(
          points: points, hours: hours, events: snapshot.docs.length);
    });
  }

  Future<List<ApplicationModel>> _withReviewNotes(
      String eventId, List<Map<String, dynamic>> applications) async {
    try {
      final reviewSnapshot =
          await _applicationReviews.where('eventId', isEqualTo: eventId).get();
      final notesByApplication = {
        for (final review in reviewSnapshot.docs)
          review.data()['applicationId']: review.data()['reviewNotes'],
      };
      return applications.map((data) {
        final merged = Map<String, dynamic>.from(data);
        merged['reviewNotes'] = notesByApplication[data['id']];
        return ApplicationModel.fromMap(merged);
      }).toList();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
      return applications.map(ApplicationModel.fromMap).toList();
    }
  }

  /// Check if a volunteer has applied for an event
  Future<bool> hasApplied(String eventId, String volunteerId) async {
    final snap = await _applications
        .where('eventId', isEqualTo: eventId)
        .where('volunteerId', isEqualTo: volunteerId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Get the application status for a volunteer on an event
  Future<ApplicationStatus?> getApplicationStatus(
      String eventId, String volunteerId) async {
    final snap = await _applications
        .where('eventId', isEqualTo: eventId)
        .where('volunteerId', isEqualTo: volunteerId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return enumFromName(
      ApplicationStatus.values,
      snap.docs.first.data()['status'],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // USERS (public read for volunteer browse)
  // ══════════════════════════════════════════════════════════════

  Future<List<UserModel>> getAllOrganizers() async {
    final snap = await _users
        .where('role', isEqualTo: enumValueName(UserRole.organizer))
        .where(
          'organizerApprovalStatus',
          isEqualTo: enumValueName(OrganizerApprovalStatus.approved),
        )
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
