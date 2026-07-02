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
    return _posts.orderBy('createdAt', descending: true).snapshots().map(
        (snap) =>
            snap.docs.map((doc) => FeedPostModel.fromMap(doc.data())).toList());
  }

  Stream<List<FeedPostModel>> userPostsStream(String userId) {
    return _posts.where('authorId', isEqualTo: userId).snapshots().map((snap) {
      final posts =
          snap.docs.map((doc) => FeedPostModel.fromMap(doc.data())).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
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

  Stream<int> commentCountStream(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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

    final commentRef =
        _posts.doc(postId).collection('comments').doc(comment.id);
    await commentRef.set(comment.toMap());
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

  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'content': content.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      data['imageUrl'] = FieldValue.delete();
    } else {
      data['imageUrl'] = imageUrl.trim();
    }

    await _posts.doc(postId).update(data);
  }

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }
}
