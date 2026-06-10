// lib/services/firebase_feed_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/feed_model.dart';
import '../models/user_model.dart';

class FirebaseFeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('feedPosts');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<List<FeedPostModel>> postsStream() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => FeedPostModel.fromMap(doc.data())).toList());
  }

  Stream<List<FeedCommentModel>> commentsStream(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeedCommentModel.fromMap(doc.data()))
            .toList());
  }

  Stream<UserModel?> userStream(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> createPost({
    required UserModel author,
    required String content,
    String? imageUrl,
  }) async {
    final post = FeedPostModel(
      id: _uuid.v4(),
      authorId: author.id,
      authorName: author.name,
      authorPhotoUrl: author.photoUrl,
      authorRole: author.role,
      content: content.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await _posts.doc(post.id).set(post.toMap());
  }

  Future<void> addComment({
    required String postId,
    required UserModel author,
    required String content,
  }) async {
    final comment = FeedCommentModel(
      id: _uuid.v4(),
      postId: postId,
      authorId: author.id,
      authorName: author.name,
      authorPhotoUrl: author.photoUrl,
      authorRole: author.role,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc(comment.id);
    final batch = _db.batch();
    batch.set(commentRef, comment.toMap());
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool shouldLike,
  }) async {
    await _posts.doc(postId).update({
      'likedBy': shouldLike
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });
  }
}
