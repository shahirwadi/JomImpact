// lib/models/event_model.dart

import '../utils/enum_utils.dart';

enum EventCategory { environment, education, health, community, animals, elderly, children, disaster }
enum EventStatus { draft, published, ongoing, completed, cancelled }
enum ApplicationStatus { pending, accepted, rejected }
enum VolunteerHourApprovalStatus { pending, approved }

class EventModel {
  final String id;
  final String organizerId;
  final String organizerName;
  final String organizerPhotoUrl;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final EventCategory category;
  final EventStatus status;
  final int maxVolunteers;
  final int currentVolunteers;
  final String? imageUrl;
  final List<String> requirements;
  final List<String> benefits;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.organizerPhotoUrl,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.status,
    required this.maxVolunteers,
    required this.currentVolunteers,
    this.imageUrl,
    this.requirements = const [],
    this.benefits = const [],
    required this.createdAt,
  });

  bool get isFull => currentVolunteers >= maxVolunteers;
  int get spotsLeft => maxVolunteers - currentVolunteers;
  double get fillRate => currentVolunteers / maxVolunteers;

  EventModel copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    EventCategory? category,
    EventStatus? status,
    int? maxVolunteers,
    int? currentVolunteers,
    String? imageUrl,
    bool clearImageUrl = false,
    List<String>? requirements,
    List<String>? benefits,
  }) {
    return EventModel(
      id: id,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerPhotoUrl: organizerPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      status: status ?? this.status,
      maxVolunteers: maxVolunteers ?? this.maxVolunteers,
      currentVolunteers: currentVolunteers ?? this.currentVolunteers,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerPhotoUrl': organizerPhotoUrl,
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': enumValueName(category),
      'status': enumValueName(status),
      'maxVolunteers': maxVolunteers,
      'currentVolunteers': currentVolunteers,
      'imageUrl': imageUrl,
      'requirements': requirements,
      'benefits': benefits,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      organizerId: map['organizerId'],
      organizerName: map['organizerName'],
      organizerPhotoUrl: map['organizerPhotoUrl'] ?? '',
      title: map['title'],
      description: map['description'],
      location: map['location'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      category: enumFromName(EventCategory.values, map['category']),
      status: enumFromName(EventStatus.values, map['status']),
      maxVolunteers: map['maxVolunteers'],
      currentVolunteers: map['currentVolunteers'],
      imageUrl: map['imageUrl'],
      requirements: List<String>.from(map['requirements'] ?? []),
      benefits: List<String>.from(map['benefits'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class ApplicationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String volunteerId;
  final String volunteerName;
  final String volunteerPhotoUrl;
  final String? volunteerBio;
  final ApplicationStatus status;
  final String? message;
  final DateTime appliedAt;

  ApplicationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.volunteerId,
    required this.volunteerName,
    required this.volunteerPhotoUrl,
    this.volunteerBio,
    required this.status,
    this.message,
    required this.appliedAt,
  });

  ApplicationModel copyWith({ApplicationStatus? status}) {
    return ApplicationModel(
      id: id,
      eventId: eventId,
      eventTitle: eventTitle,
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      volunteerPhotoUrl: volunteerPhotoUrl,
      volunteerBio: volunteerBio,
      status: status ?? this.status,
      message: message,
      appliedAt: appliedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'volunteerPhotoUrl': volunteerPhotoUrl,
        'volunteerBio': volunteerBio,
        'status': enumValueName(status),
        'message': message,
        'appliedAt': appliedAt.toIso8601String(),
      };

  factory ApplicationModel.fromMap(Map<String, dynamic> map) => ApplicationModel(
        id: map['id'],
        eventId: map['eventId'],
        eventTitle: map['eventTitle'],
        volunteerId: map['volunteerId'],
        volunteerName: map['volunteerName'],
        volunteerPhotoUrl: map['volunteerPhotoUrl'] ?? '',
        volunteerBio: map['volunteerBio'],
        status: enumFromName(ApplicationStatus.values, map['status']),
        message: map['message'],
        appliedAt: DateTime.parse(map['appliedAt']),
      );
}

class VolunteerHourRecord {
  final String id;
  final String eventId;
  final String eventTitle;
  final String organizerId;
  final String volunteerId;
  final String volunteerName;
  final String volunteerPhotoUrl;
  final int hours;
  final VolunteerHourApprovalStatus status;
  final DateTime eventEndDate;
  final DateTime assignedAt;
  final DateTime? approvedAt;

  VolunteerHourRecord({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.organizerId,
    required this.volunteerId,
    required this.volunteerName,
    required this.volunteerPhotoUrl,
    required this.hours,
    required this.status,
    required this.eventEndDate,
    required this.assignedAt,
    this.approvedAt,
  });

  bool get isApproved => status == VolunteerHourApprovalStatus.approved;

  VolunteerHourRecord copyWith({
    int? hours,
    VolunteerHourApprovalStatus? status,
    DateTime? assignedAt,
    DateTime? approvedAt,
  }) {
    return VolunteerHourRecord(
      id: id,
      eventId: eventId,
      eventTitle: eventTitle,
      organizerId: organizerId,
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      volunteerPhotoUrl: volunteerPhotoUrl,
      hours: hours ?? this.hours,
      status: status ?? this.status,
      eventEndDate: eventEndDate,
      assignedAt: assignedAt ?? this.assignedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'organizerId': organizerId,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'volunteerPhotoUrl': volunteerPhotoUrl,
        'hours': hours,
        'status': enumValueName(status),
        'eventEndDate': eventEndDate.toIso8601String(),
        'assignedAt': assignedAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
      };

  factory VolunteerHourRecord.fromMap(Map<String, dynamic> map) =>
      VolunteerHourRecord(
        id: map['id'],
        eventId: map['eventId'],
        eventTitle: map['eventTitle'],
        organizerId: map['organizerId'],
        volunteerId: map['volunteerId'],
        volunteerName: map['volunteerName'],
        volunteerPhotoUrl: map['volunteerPhotoUrl'] ?? '',
        hours: map['hours'] ?? 0,
        status: enumFromName(
          VolunteerHourApprovalStatus.values,
          map['status'],
        ),
        eventEndDate: DateTime.parse(map['eventEndDate']),
        assignedAt: DateTime.parse(map['assignedAt']),
        approvedAt: map['approvedAt'] != null
            ? DateTime.parse(map['approvedAt'])
            : null,
      );
}
