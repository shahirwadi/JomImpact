// lib/services/mock_data_service.dart

import '../models/user_model.dart';
import '../models/event_model.dart';
import 'package:uuid/uuid.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  final _uuid = const Uuid();

  // Seed users
  final List<UserModel> _users = [
    UserModel(
      id: 'org_001',
      name: 'Yayasan Sejahtera',
      email: 'organizer@demo.com',
      role: UserRole.organizer,
      organization: 'Yayasan Sejahtera Malaysia',
      bio:
          'We are a non-profit organization dedicated to community development across Malaysia since 2010.',
      location: 'Kuala Lumpur, Malaysia',
      phone: '+60 12-345 6789',
      totalEvents: 24,
      createdAt: DateTime(2023, 1, 15),
    ),
    UserModel(
      id: 'vol_001',
      name: 'Ahmad Faiz',
      email: 'volunteer@demo.com',
      role: UserRole.volunteer,
      bio: 'Passionate about community service and environmental conservation.',
      location: 'Petaling Jaya, Selangor',
      phone: '+60 11-234 5678',
      skills: ['Teaching', 'Photography', 'First Aid', 'Cooking'],
      totalHours: 120,
      createdAt: DateTime(2023, 3, 20),
    ),
    UserModel(
      id: 'org_002',
      name: 'EcoWarriors MY',
      email: 'eco@demo.com',
      role: UserRole.organizer,
      organization: 'EcoWarriors Malaysia',
      bio:
          'Environmental NGO focused on clean oceans, reforestation, and sustainability education.',
      location: 'Penang, Malaysia',
      totalEvents: 15,
      createdAt: DateTime(2023, 2, 10),
    ),
    UserModel(
      id: 'org_003',
      name: 'Rumah Harapan',
      email: 'harapan@demo.com',
      role: UserRole.organizer,
      organization: 'Rumah Harapan Foundation',
      bio:
          'Supporting underprivileged children and elderly through education and care programs.',
      location: 'Johor Bahru, Johor',
      totalEvents: 31,
      createdAt: DateTime(2022, 11, 5),
    ),
  ];

  final List<EventModel> _events = [
    EventModel(
      id: 'evt_001',
      organizerId: 'org_001',
      organizerName: 'Yayasan Sejahtera',
      organizerPhotoUrl: '',
      title: 'Komuniti Bersih Sungai Klang',
      description:
          'Join us for a river cleanup initiative along Sungai Klang! Together we will remove plastic waste and restore the natural ecosystem. This event includes guided cleanup, environmental briefing, and a tree planting ceremony. Lunch and refreshments provided for all volunteers.',
      location: 'Sungai Klang, Kuala Lumpur',
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 7, hours: 8)),
      category: EventCategory.environment,
      status: EventStatus.published,
      maxVolunteers: 50,
      currentVolunteers: 32,
      requirements: [
        'Comfortable outdoor clothing',
        'Waterproof footwear',
        'Bring own water tumbler'
      ],
      benefits: [
        'Free T-shirt',
        'Certificate of participation',
        'Lunch provided',
        'Volunteer hours logged'
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    EventModel(
      id: 'evt_002',
      organizerId: 'org_001',
      organizerName: 'Yayasan Sejahtera',
      organizerPhotoUrl: '',
      title: 'Tutor Bijak — Free Tuition for B40 Students',
      description:
          'Volunteer as a tutor for underprivileged students in Form 3 and SPM preparation. We need dedicated tutors in Mathematics, Science, Bahasa Malaysia, and English. Make a real difference in a student\'s life!',
      location: 'Chow Kit Community Hall, KL',
      startDate: DateTime.now().add(const Duration(days: 14)),
      endDate: DateTime.now().add(const Duration(days: 14, hours: 4)),
      category: EventCategory.education,
      status: EventStatus.published,
      maxVolunteers: 20,
      currentVolunteers: 8,
      requirements: [
        'SPM or above qualification',
        'Patient and enthusiastic',
        'Commitment to full session'
      ],
      benefits: ['Certificate', 'Volunteer hours', 'Networking with educators'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    EventModel(
      id: 'evt_003',
      organizerId: 'org_002',
      organizerName: 'EcoWarriors MY',
      organizerPhotoUrl: '',
      title: 'Mangrove Planting at Kuala Selangor',
      description:
          'Help restore Malaysia\'s mangrove forests! We will plant 500 mangrove saplings along the coastline of Kuala Selangor Nature Park. Mangroves are critical for coastal protection and marine biodiversity.',
      location: 'Kuala Selangor Nature Park, Selangor',
      startDate: DateTime.now().add(const Duration(days: 21)),
      endDate: DateTime.now().add(const Duration(days: 21, hours: 6)),
      category: EventCategory.environment,
      status: EventStatus.published,
      maxVolunteers: 40,
      currentVolunteers: 40,
      requirements: [
        'Physical fitness',
        'Closed-toe shoes',
        'Sunscreen recommended'
      ],
      benefits: ['Free T-shirt', 'Nature guide tour', 'Certificate'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    EventModel(
      id: 'evt_004',
      organizerId: 'org_003',
      organizerName: 'Rumah Harapan',
      organizerPhotoUrl: '',
      title: 'Jom Masak! Cooking for the Elderly',
      description:
          'Spend a meaningful Saturday cooking nutritious meals for 80 senior citizens at Rumah Orang Tua Setapak. Bring joy through food! No cooking experience needed — our team will guide you.',
      location: 'Rumah Orang Tua Setapak, KL',
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 3, hours: 5)),
      category: EventCategory.elderly,
      status: EventStatus.published,
      maxVolunteers: 15,
      currentVolunteers: 11,
      requirements: ['Friendly and caring attitude', 'Arrive on time'],
      benefits: ['Heartwarming experience', 'Certificate', 'Volunteer hours'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    EventModel(
      id: 'evt_005',
      organizerId: 'org_003',
      organizerName: 'Rumah Harapan',
      organizerPhotoUrl: '',
      title: 'Children\'s Art Therapy Workshop',
      description:
          'Facilitate art therapy sessions for children from low-income families. Help kids express themselves through painting, drawing, and crafts. Training provided on day of event.',
      location: 'Kampung Bharu Community Center, KL',
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 10, hours: 4)),
      category: EventCategory.children,
      status: EventStatus.published,
      maxVolunteers: 12,
      currentVolunteers: 5,
      requirements: [
        'Love for children',
        'Creative mindset',
        'Basic art supplies provided'
      ],
      benefits: [
        'Art materials',
        'Certificate',
        'Volunteer hours',
        'Snacks provided'
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    EventModel(
      id: 'evt_006',
      organizerId: 'org_002',
      organizerName: 'EcoWarriors MY',
      organizerPhotoUrl: '',
      title: 'Beach Cleanup — Batu Ferringhi',
      description:
          'Keep Penang beautiful! Join our monthly beach cleanup at Batu Ferringhi. We will collect data on plastic waste to support marine conservation research.',
      location: 'Batu Ferringhi Beach, Penang',
      startDate: DateTime.now().add(const Duration(days: 28)),
      endDate: DateTime.now().add(const Duration(days: 28, hours: 5)),
      category: EventCategory.environment,
      status: EventStatus.published,
      maxVolunteers: 60,
      currentVolunteers: 18,
      requirements: ['Old clothes', 'Gloves provided', 'Min age 12'],
      benefits: [
        'Free breakfast',
        'Certificate',
        'T-shirt',
        'Conservation report'
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<ApplicationModel> _applications = [
    ApplicationModel(
      id: 'app_001',
      eventId: 'evt_001',
      eventTitle: 'Komuniti Bersih Sungai Klang',
      volunteerId: 'vol_001',
      volunteerName: 'Ahmad Faiz',
      volunteerPhotoUrl: '',
      volunteerBio:
          'Passionate about community service and environmental conservation.',
      status: ApplicationStatus.accepted,
      message:
          'I am very interested in environmental conservation and would love to contribute!',
      appliedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ApplicationModel(
      id: 'app_002',
      eventId: 'evt_004',
      eventTitle: 'Jom Masak! Cooking for the Elderly',
      volunteerId: 'vol_001',
      volunteerName: 'Ahmad Faiz',
      volunteerPhotoUrl: '',
      volunteerBio:
          'Passionate about community service and environmental conservation.',
      status: ApplicationStatus.pending,
      message:
          'I love cooking and spending time with elderly people. Happy to help!',
      appliedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  // Auth
  UserModel? login(String email, String password) {
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  UserModel? register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? organization,
  }) {
    if (_users.any((u) => u.email == email)) return null;
    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      role: role,
      organization: organization,
      skills: [],
      totalEvents: role == UserRole.organizer ? 0 : null,
      totalHours: role == UserRole.volunteer ? 0 : null,
      createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  // Events
  List<EventModel> getAllPublishedEvents() =>
      _events.where((e) => e.status == EventStatus.published).toList();

  List<EventModel> getOrganizerEvents(String organizerId) =>
      _events.where((e) => e.organizerId == organizerId).toList();

  EventModel? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  EventModel createEvent(EventModel event) {
    _events.add(event);
    return event;
  }

  EventModel? updateEvent(EventModel updated) {
    final idx = _events.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return null;
    _events[idx] = updated;
    return updated;
  }

  bool deleteEvent(String eventId) {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return false;
    _events.removeAt(idx);
    return true;
  }

  // Applications
  List<ApplicationModel> getApplicationsForEvent(String eventId) =>
      _applications.where((a) => a.eventId == eventId).toList();

  List<ApplicationModel> getApplicationsForVolunteer(String volunteerId) =>
      _applications.where((a) => a.volunteerId == volunteerId).toList();

  ApplicationModel? applyForEvent({
    required String eventId,
    required String eventTitle,
    required UserModel volunteer,
    String? message,
  }) {
    if (_applications
        .any((a) => a.eventId == eventId && a.volunteerId == volunteer.id)) {
      return null; // already applied
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
    _applications.add(app);

    // Increment volunteer count on event
    final eventIdx = _events.indexWhere((e) => e.id == eventId);
    if (eventIdx != -1) {
      _events[eventIdx] = _events[eventIdx].copyWith(
        currentVolunteers: _events[eventIdx].currentVolunteers + 1,
      );
    }
    return app;
  }

  bool updateApplicationStatus(String appId, ApplicationStatus status) {
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx == -1) return false;
    _applications[idx] = _applications[idx].copyWith(status: status);
    return true;
  }

  bool hasApplied(String eventId, String volunteerId) => _applications
      .any((a) => a.eventId == eventId && a.volunteerId == volunteerId);

  ApplicationStatus? getApplicationStatus(String eventId, String volunteerId) {
    try {
      return _applications
          .firstWhere(
              (a) => a.eventId == eventId && a.volunteerId == volunteerId)
          .status;
    } catch (_) {
      return null;
    }
  }

  // Organizers
  List<UserModel> getAllOrganizers() =>
      _users.where((u) => u.role == UserRole.organizer).toList();

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  UserModel? updateUser(UserModel updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx == -1) return null;
    _users[idx] = updated;
    return updated;
  }
}
