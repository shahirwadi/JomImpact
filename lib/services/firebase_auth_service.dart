// lib/services/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/enum_utils.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream of auth state changes ──────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ── Register ──────────────────────────────────────────────────────────────
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? organization,
  }) async {
    // 1. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // 2. Build Firestore user doc
    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      role: role,
      organization: organization,
      skills: const [],
      totalEvents: role == UserRole.organizer ? 0 : null,
      totalHours: role == UserRole.volunteer ? 0 : null,
      organizerApprovalStatus: role == UserRole.organizer
          ? OrganizerApprovalStatus.pending
          : OrganizerApprovalStatus.notRequired,
      createdAt: DateTime.now(),
    );

    // 3. Write to Firestore
    await _db
        .collection('users')
        .doc(uid)
        .set(user.toMap());

    return user;
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    return _fetchUserDoc(uid);
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() => _auth.signOut();

  // ── Fetch current user profile from Firestore ─────────────────────────────
  Future<UserModel?> fetchCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _fetchUserDoc(fbUser.uid);
  }

  // ── Update user profile ───────────────────────────────────────────────────
  Future<UserModel> updateUser(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.id)
        .update(user.toMap());
    return user;
  }

  Future<List<UserModel>> getPendingOrganizerRequests() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: enumValueName(UserRole.organizer))
        .where(
          'organizerApprovalStatus',
          isEqualTo: enumValueName(OrganizerApprovalStatus.pending),
        )
        .orderBy('createdAt', descending: false)
        .get();

    return snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<List<UserModel>> getApprovedOrganizers() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: enumValueName(UserRole.organizer))
        .where(
          'organizerApprovalStatus',
          isEqualTo: enumValueName(OrganizerApprovalStatus.approved),
        )
        .get();

    return snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<UserModel> reviewOrganizerRequest({
    required String userId,
    required OrganizerApprovalStatus status,
    String? approvalNotes,
  }) async {
    await _db.collection('users').doc(userId).update({
      'organizerApprovalStatus': enumValueName(status),
      'approvalNotes': approvalNotes,
    });

    return _fetchUserDoc(userId);
  }

  // ── Internal helper ───────────────────────────────────────────────────────
  Future<UserModel> _fetchUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User document not found.');
    return UserModel.fromMap(doc.data()!);
  }
}
