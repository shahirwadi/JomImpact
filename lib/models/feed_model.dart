// lib/models/feed_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enum_utils.dart';
import 'user_model.dart';

class FeedPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final UserRole authorRole;
  final String content;
  final String? imageUrl;
  final List<String> likedBy;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FeedPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.authorRole,
    required this.content,
    this.imageUrl,
    this.likedBy = const [],
    this.commentCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  int get likeCount => likedBy.length;

  bool isLikedBy(String userId) => likedBy.contains(userId);

  bool get wasEdited => updatedAt != null;

  bool get canEdit => true;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'authorRole': enumValueName(authorRole),
      'content': content,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory FeedPostModel.fromMap(Map<String, dynamic> map) {
    return FeedPostModel(
      id: map['id'],
      authorId: map['authorId'],
      authorName: map['authorName'],
      authorPhotoUrl: map['authorPhotoUrl'],
      authorRole: enumFromName(UserRole.values, map['authorRole']),
      content: map['content'],
      imageUrl: map['imageUrl'],
      likedBy: List<String>.from(map['likedBy'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: map['updatedAt'] == null ? null : _dateFromValue(map['updatedAt']),
    );
  }
}

class FeedCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final UserRole authorRole;
  final String content;
  final DateTime createdAt;

  FeedCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.authorRole,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'authorRole': enumValueName(authorRole),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedCommentModel.fromMap(Map<String, dynamic> map) {
    return FeedCommentModel(
      id: map['id'],
      postId: map['postId'],
      authorId: map['authorId'],
      authorName: map['authorName'],
      authorPhotoUrl: map['authorPhotoUrl'],
      authorRole: enumFromName(UserRole.values, map['authorRole']),
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

DateTime _dateFromValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.parse(value as String);
}
