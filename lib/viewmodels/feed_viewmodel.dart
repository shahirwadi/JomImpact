// lib/viewmodels/feed_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_feed_service.dart';

class FeedViewModel extends ChangeNotifier {
  final FirebaseFeedService _service = FirebaseFeedService();

  bool _isPosting = false;
  String? _error;

  bool get isPosting => _isPosting;
  String? get error => _error;
  FirebaseFeedService get service => _service;

  Future<bool> createPost({
    required UserModel author,
    required String content,
    String? imageUrl,
  }) async {
    if (content.trim().isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      _error = 'Add some text or a photo before publishing.';
      notifyListeners();
      return false;
    }

    _isPosting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createPost(
        author: author,
        content: content,
        imageUrl: imageUrl,
      );
      _isPosting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isPosting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addComment({
    required String postId,
    required UserModel author,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;

    try {
      await _service.addComment(
        postId: postId,
        author: author,
        content: content,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool shouldLike,
  }) async {
    try {
      await _service.toggleLike(
        postId: postId,
        userId: userId,
        shouldLike: shouldLike,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) async {
    if (content.trim().isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      _error = 'Post needs text or a photo.';
      notifyListeners();
      return false;
    }

    try {
      await _service.updatePost(
        postId: postId,
        content: content,
        imageUrl: imageUrl,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _service.deletePost(postId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
