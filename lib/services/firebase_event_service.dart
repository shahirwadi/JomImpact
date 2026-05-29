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
  CollectionReference<Map<String, dynamic>> get _volunteerHours =>
      _db.collection('volunteer_hours');
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

    final hoursSnap =
        await _volunteerHours.where('eventId', isEqualTo: eventId).get();
    for (final doc in hoursSnap.docs) {
      final record = VolunteerHourRecord.fromMap(doc.data());
      if (record.isApproved) {
        batch.update(_users.doc(record.volunteerId), {
          'totalHours': FieldValue.increment(-record.hours),
        });
      }
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
      appliedAt: DateTime.now(),
    );

    final batch = _db.batch();

    // Write application
    batch.set(_applications.doc(app.id), app.toMap());

    await batch.commit();
    return app;
  }

  /// Get applications for a specific event (organizer view)
  Future<List<ApplicationModel>> getApplicationsForEvent(
      String eventId) async {
    final snap = await _applications
        .where('eventId', isEqualTo: eventId)
        .orderBy('appliedAt', descending: true)
        .get();
    return snap.docs.map((d) => ApplicationModel.fromMap(d.data())).toList();
  }

  /// Real-time stream of applications for an event
  Stream<List<ApplicationModel>> applicationsForEventStream(String eventId) {
    return _applications
        .where('eventId', isEqualTo: eventId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ApplicationModel.fromMap(d.data())).toList());
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

  /// Accept or reject an application
  Future<void> updateApplicationStatus(
      String appId, ApplicationStatus status) async {
    await _db.runTransaction((tx) async {
      final appRef = _applications.doc(appId);
      final appSnap = await tx.get(appRef);
      if (!appSnap.exists) {
        throw Exception('application_not_found');
      }

      final app = ApplicationModel.fromMap(appSnap.data()!);
      final currentStatus = app.status;
      final eventRef = _events.doc(app.eventId);
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) {
        throw Exception('event_not_found');
      }

      final event = EventModel.fromMap(eventSnap.data()!);
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

      tx.update(appRef, {'status': enumValueName(status)});

      if (volunteerDelta != 0) {
        tx.update(eventRef, {
          'currentVolunteers': FieldValue.increment(volunteerDelta),
        });
      }
    });
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

  Future<List<VolunteerHourRecord>> getVolunteerHourRecordsForEvent(
      String eventId) async {
    final snap = await _volunteerHours
        .where('eventId', isEqualTo: eventId)
        .orderBy('assignedAt', descending: true)
        .get();
    return snap.docs.map((d) => VolunteerHourRecord.fromMap(d.data())).toList();
  }

  Future<List<VolunteerHourRecord>> getVolunteerHourHistoryForVolunteer(
      String volunteerId) async {
    final snap = await _volunteerHours
        .where('volunteerId', isEqualTo: volunteerId)
        .where(
          'status',
          isEqualTo: enumValueName(VolunteerHourApprovalStatus.approved),
        )
        .orderBy('approvedAt', descending: true)
        .get();
    return snap.docs.map((d) => VolunteerHourRecord.fromMap(d.data())).toList();
  }

  Future<void> setVolunteerHours({
    required EventModel event,
    required ApplicationModel application,
    required int hours,
  }) async {
    if (hours <= 0) {
      throw Exception('invalid_hours');
    }
    if (application.status != ApplicationStatus.accepted) {
      throw Exception('volunteer_not_accepted');
    }
    if (DateTime.now().isBefore(event.endDate) &&
        event.status != EventStatus.completed) {
      throw Exception('event_not_finished');
    }

    final existingSnap = await _volunteerHours
        .where('eventId', isEqualTo: event.id)
        .where('volunteerId', isEqualTo: application.volunteerId)
        .limit(1)
        .get();

    if (existingSnap.docs.isNotEmpty) {
      final existing = VolunteerHourRecord.fromMap(existingSnap.docs.first.data());
      if (existing.isApproved) {
        throw Exception('hours_already_approved');
      }
      final updated = existing.copyWith(
        hours: hours,
        assignedAt: DateTime.now(),
      );
      await _volunteerHours.doc(existing.id).update(updated.toMap());
      return;
    }

    final record = VolunteerHourRecord(
      id: _uuid.v4(),
      eventId: event.id,
      eventTitle: event.title,
      organizerId: event.organizerId,
      volunteerId: application.volunteerId,
      volunteerName: application.volunteerName,
      volunteerPhotoUrl: application.volunteerPhotoUrl,
      hours: hours,
      status: VolunteerHourApprovalStatus.pending,
      eventEndDate: event.endDate,
      assignedAt: DateTime.now(),
    );

    await _volunteerHours.doc(record.id).set(record.toMap());
  }

  Future<void> approveVolunteerHours(String recordId) async {
    await _db.runTransaction((tx) async {
      final recordRef = _volunteerHours.doc(recordId);
      final recordSnap = await tx.get(recordRef);
      if (!recordSnap.exists) {
        throw Exception('hours_record_not_found');
      }

      final record = VolunteerHourRecord.fromMap(recordSnap.data()!);
      if (record.isApproved) {
        return;
      }

      final userRef = _users.doc(record.volunteerId);
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw Exception('volunteer_not_found');
      }

      tx.update(recordRef, {
        'status': enumValueName(VolunteerHourApprovalStatus.approved),
        'approvedAt': DateTime.now().toIso8601String(),
      });
      tx.update(userRef, {
        'totalHours': FieldValue.increment(record.hours),
      });
    });
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
