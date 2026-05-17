// lib/models/user_model.dart

import '../utils/enum_utils.dart';

enum UserRole { organizer, volunteer, admin }

enum OrganizerApprovalStatus { notRequired, pending, approved, rejected }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final String? bio;
  final String? phone;
  final String? location;
  final List<String> skills; // for volunteers
  final String? organization; // for organizers
  final int? totalEvents; // for organizers
  final int? totalHours; // for volunteers
  final OrganizerApprovalStatus organizerApprovalStatus;
  final String? approvalNotes;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.bio,
    this.phone,
    this.location,
    this.skills = const [],
    this.organization,
    this.totalEvents,
    this.totalHours,
    this.organizerApprovalStatus = OrganizerApprovalStatus.notRequired,
    this.approvalNotes,
    required this.createdAt,
  });

  bool get isOrganizerApproved =>
      role != UserRole.organizer ||
      organizerApprovalStatus == OrganizerApprovalStatus.approved ||
      organizerApprovalStatus == OrganizerApprovalStatus.notRequired;

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? bio,
    String? phone,
    String? location,
    List<String>? skills,
    String? organization,
    int? totalEvents,
    int? totalHours,
    OrganizerApprovalStatus? organizerApprovalStatus,
    String? approvalNotes,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: clearPhotoUrl ? null : photoUrl ?? this.photoUrl,
      role: role,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      organization: organization ?? this.organization,
      totalEvents: totalEvents ?? this.totalEvents,
      totalHours: totalHours ?? this.totalHours,
      organizerApprovalStatus:
          organizerApprovalStatus ?? this.organizerApprovalStatus,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': enumValueName(role),
      'bio': bio,
      'phone': phone,
      'location': location,
      'skills': skills,
      'organization': organization,
      'totalEvents': totalEvents,
      'totalHours': totalHours,
      'organizerApprovalStatus': enumValueName(organizerApprovalStatus),
      'approvalNotes': approvalNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = enumFromName(UserRole.values, map['role']);
    final rawApprovalStatus = map['organizerApprovalStatus'];

    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      role: role,
      bio: map['bio'],
      phone: map['phone'],
      location: map['location'],
      skills: List<String>.from(map['skills'] ?? []),
      organization: map['organization'],
      totalEvents: map['totalEvents'],
      totalHours: map['totalHours'],
      organizerApprovalStatus: OrganizerApprovalStatus.values.firstWhere(
        (status) => enumValueName(status) ==
            (rawApprovalStatus ??
                (role == UserRole.organizer
                    ? enumValueName(OrganizerApprovalStatus.approved)
                    : enumValueName(OrganizerApprovalStatus.notRequired))),
        orElse: () => role == UserRole.organizer
            ? OrganizerApprovalStatus.approved
            : OrganizerApprovalStatus.notRequired,
      ),
      approvalNotes: map['approvalNotes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
