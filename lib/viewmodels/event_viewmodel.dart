// lib/viewmodels/event_viewmodel.dart
// Uses FirebaseEventService instead of MockDataService.

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/firebase_event_service.dart';
import '../utils/malaysia_states.dart';

class EventViewModel extends ChangeNotifier {
  final FirebaseEventService _service = FirebaseEventService();
  final _uuid = const Uuid();

  List<EventModel> _allEvents = [];
  List<EventModel> _organizerEvents = [];
  List<ApplicationModel> _applications = [];
  List<UserModel> _organizers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  EventCategory? _selectedCategory;
  String? _selectedState;

  // Cache for hasApplied / getApplicationStatus (to avoid extra Firestore reads)
  final Map<String, ApplicationStatus?> _statusCache = {};

  List<EventModel> get allEvents => _filteredEvents;
  List<EventModel> get organizerEvents => _organizerEvents;
  List<ApplicationModel> get applications => _applications;
  List<UserModel> get organizers => _organizers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  EventCategory? get selectedCategory => _selectedCategory;
  String? get selectedState => _selectedState;

  List<EventModel> get _filteredEvents {
    var events = List<EventModel>.from(_allEvents);
    if (_searchQuery.isNotEmpty) {
      events = events
          .where((e) =>
              e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              e.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (e.state?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false) ||
              e.organizerName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategory != null) {
      events = events.where((e) => e.category == _selectedCategory).toList();
    }
    if (_selectedState != null) {
      events = events.where((e) => e.state == _selectedState).toList();
    }
    return events;
  }

  // ── Load published events ──────────────────────────────────────────────────
  Future<void> loadAllEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allEvents = await _service.getAllPublishedEvents();
      _organizers = await _service.getAllOrganizers();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Load organizer's events ───────────────────────────────────────────────
  Future<void> loadOrganizerEvents(String organizerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _organizerEvents = await _service.getOrganizerEvents(organizerId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Load applications for an event (organizer view) ───────────────────────
  Future<void> loadApplicationsForEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _applications = await _service.getApplicationsForEvent(eventId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Load volunteer's own applications ────────────────────────────────────
  Future<void> loadVolunteerApplications(String volunteerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _applications = await _service.getApplicationsForVolunteer(volunteerId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Load all organizers ───────────────────────────────────────────────────
  Future<void> loadOrganizers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _organizers = await _service.getAllOrganizers();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Create event ──────────────────────────────────────────────────────────
  Future<bool> createEvent({
    required UserModel organizer,
    required String title,
    required String description,
    required String location,
    required String state,
    required DateTime startDate,
    required DateTime endDate,
    required EventCategory category,
    required int maxVolunteers,
    String? imageUrl,
    List<String> requirements = const [],
    List<String> benefits = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!organizer.isOrganizerApproved) {
        throw Exception('Organizer account is waiting for admin approval.');
      }
      if ((organizer.location?.trim().isEmpty ?? true) ||
          !isMalaysiaState(organizer.state)) {
        throw Exception(
            'Complete your profile location and state before creating an event.');
      }
      if (location.trim().isEmpty || !isMalaysiaState(state)) {
        throw Exception(
            'A valid Malaysian event location and state are required.');
      }
      final event = EventModel(
        id: _uuid.v4(),
        organizerId: organizer.id,
        organizerName: organizer.name,
        organizerPhotoUrl: organizer.photoUrl ?? '',
        title: title,
        description: description,
        location: location,
        state: state,
        startDate: startDate,
        endDate: endDate,
        category: category,
        status: EventStatus.published,
        maxVolunteers: maxVolunteers,
        currentVolunteers: 0,
        imageUrl: imageUrl,
        requirements: requirements,
        benefits: benefits,
        createdAt: DateTime.now(),
      );
      await _service.createEvent(event);
      _organizerEvents = await _service.getOrganizerEvents(organizer.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Update event ──────────────────────────────────────────────────────────
  Future<bool> updateEvent(EventModel event) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateEvent(event);
      _organizerEvents = await _service.getOrganizerEvents(event.organizerId);
      _allEvents = await _service.getAllPublishedEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markEventCompleted(String eventId) async {
    try {
      await _service.markEventCompleted(eventId);
      return true;
    } catch (e) {
      _error = e.toString().contains('event_not_finished')
          ? 'The event can only be completed after its end time.'
          : e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Delete event ──────────────────────────────────────────────────────────
  Future<bool> deleteEvent(String eventId, String organizerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteEvent(eventId, organizerId);
      _organizerEvents = await _service.getOrganizerEvents(organizerId);
      _allEvents = await _service.getAllPublishedEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Apply for event ───────────────────────────────────────────────────────
  Future<bool> applyForEvent({
    required String eventId,
    required String eventTitle,
    required UserModel volunteer,
    String? message,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final app = await _service.applyForEvent(
        eventId: eventId,
        eventTitle: eventTitle,
        volunteer: volunteer,
        message: message,
      );
      // Update cache
      _statusCache['${eventId}_${volunteer.id}'] = app.status;
      _allEvents = await _service.getAllPublishedEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e.toString().contains('already_applied')) {
        _error = 'You have already applied for this event.';
      } else if (e.toString().contains('event_full')) {
        _error = 'This event is already full.';
      } else if (e.toString().contains('event_not_open')) {
        _error = 'This event is not open for applications.';
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Update application status (organizer) ─────────────────────────────────
  Future<bool> updateApplicationStatus(
    String appId,
    ApplicationStatus status,
    String eventId, {
    required String reviewedBy,
    String? reviewNotes,
  }) async {
    try {
      await _service.updateApplicationStatus(
        appId,
        status,
        reviewedBy: reviewedBy,
        reviewNotes: reviewNotes,
      );
      await loadApplicationsForEvent(eventId);
      _allEvents = await _service.getAllPublishedEvents();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> withdrawApplication(String appId, String volunteerId) async {
    try {
      await _service.withdrawApplication(appId, volunteerId);
      await loadVolunteerApplications(volunteerId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewAttendance({
    required String appId,
    required AttendanceStatus attendanceStatus,
    required int verifiedHours,
    required String reviewedBy,
    required String eventId,
  }) async {
    try {
      await _service.reviewAttendance(
        appId: appId,
        attendanceStatus: attendanceStatus,
        verifiedHours: verifiedHours,
        reviewedBy: reviewedBy,
      );
      await loadApplicationsForEvent(eventId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> finalizeEvent(String eventId, String organizerId) async {
    try {
      await _service.finalizeEvent(eventId, organizerId);
      await loadApplicationsForEvent(eventId);
      await loadOrganizerEvents(organizerId);
      return true;
    } catch (e) {
      _error = e.toString().contains('attendance_incomplete')
          ? 'Review every accepted volunteer before finalizing.'
          : e.toString();
      notifyListeners();
      return false;
    }
  }

  Stream<ImpactSummary> impactSummaryStream(String volunteerId) =>
      _service.impactSummaryStream(volunteerId);

  // ── Status helpers (cached) ───────────────────────────────────────────────
  bool hasApplied(String eventId, String volunteerId) {
    final key = '${eventId}_$volunteerId';
    return _statusCache.containsKey(key);
  }

  ApplicationStatus? getApplicationStatus(String eventId, String volunteerId) {
    final key = '${eventId}_$volunteerId';
    return _statusCache[key];
  }

  /// Pre-load status for volunteer's applied events (call once after login)
  Future<void> preloadApplicationStatuses(String volunteerId) async {
    try {
      final apps = await _service.getApplicationsForVolunteer(volunteerId);
      for (final app in apps) {
        _statusCache['${app.eventId}_$volunteerId'] = app.status;
      }
      notifyListeners();
    } catch (_) {}
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(EventCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setStateFilter(String? state) {
    _selectedState = state;
    notifyListeners();
  }

  // ── Organizer helpers ─────────────────────────────────────────────────────
  List<UserModel> getAllOrganizers() => _organizers;

  UserModel? getOrganizerById(String id) {
    try {
      return _organizers.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
