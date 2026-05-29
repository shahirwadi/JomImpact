// lib/viewmodels/auth_viewmodel.dart
//
// Replaces MockDataService with FirebaseAuthService.
// Listens to Firebase Auth state so the app auto-logs-in on restart.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  static const _startupAuthTimeout = Duration(seconds: 8);
  static const _authOperationTimeout = Duration(seconds: 15);

  final FirebaseAuthService _authService = FirebaseAuthService();

  UserModel? _currentUser;
  List<UserModel> _pendingOrganizerRequests = [];
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isOrganizer => _currentUser?.role == UserRole.organizer;
  bool get isVolunteer => _currentUser?.role == UserRole.volunteer;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isOrganizerApproved => _currentUser?.isOrganizerApproved ?? false;
  List<UserModel> get pendingOrganizerRequests => _pendingOrganizerRequests;

  AuthViewModel() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService
          .fetchCurrentUser()
          .timeout(_startupAuthTimeout);
    } on TimeoutException {
      _currentUser = null;
      _error = 'Unable to restore your session. Please sign in again.';
    } catch (e) {
      _currentUser = null;
      _error = 'Something went wrong while restoring your session.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _authService.authStateChanges.listen((User? fbUser) async {
      if (fbUser == null) {
        _currentUser = null;
        notifyListeners();
      } else if (_currentUser == null || _currentUser!.id != fbUser.uid) {
        try {
          _currentUser = await _authService
              .fetchCurrentUser()
              .timeout(_startupAuthTimeout);
          _error = null;
        } on TimeoutException {
          _currentUser = null;
          _error = 'Unable to restore your session. Please sign in again.';
        } catch (e) {
          _currentUser = null;
          _error = 'Something went wrong while restoring your session.';
        }
        notifyListeners();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService
          .login(email: email, password: password)
          .timeout(_authOperationTimeout);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException {
      _error =
          'Sign in is taking too long. Check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? organization,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService
          .register(
            name: name,
            email: email,
            password: password,
            role: role,
            organization: organization,
          )
          .timeout(_authOperationTimeout);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException {
      _error =
          'Registration is taking too long. Check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updated) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.updateUser(updated);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.fetchCurrentUser();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPendingOrganizerRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _pendingOrganizerRequests =
          await _authService.getPendingOrganizerRequests();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> reviewOrganizerRequest({
    required String userId,
    required OrganizerApprovalStatus status,
    String? approvalNotes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.reviewOrganizerRequest(
        userId: userId,
        status: status,
        approvalNotes: approvalNotes,
      );
      _pendingOrganizerRequests =
          await _authService.getPendingOrganizerRequests();
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser = await _authService.fetchCurrentUser();
      }
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'email-already-in-use': return 'This email is already registered.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      case 'network-request-failed': return 'No internet connection.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
