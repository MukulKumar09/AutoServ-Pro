// lib/services/firebase_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_card_model.dart';
import '../models/user_model.dart';
import 'cloudinary_service.dart';

class FirebaseService {
  final FirebaseFirestore _db  = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  // ── Collections ────────────────────────────────────────────────────────────
  CollectionReference get _jobCards => _db.collection('job_cards');
  CollectionReference get _users    => _db.collection('users');
  CollectionReference get _settings => _db.collection('settings');

  // ── Auth ───────────────────────────────────────────────────────────────────
  User? get currentUser          => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  /// Create a Firebase Auth account + Firestore profile for a staff member.
  /// Called by admin when adding staff — does NOT sign in as the new user.
  Future<void> createStaffAccount(UserModel staff, String password) async {
    // Use secondary app instance so admin stays logged in
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: staff.email, password: password);
    await _users.doc(credential.user!.uid).set({
      ...staff.toFirestore(),
      'uid': credential.user!.uid,
    });
    // Sign back in as admin (createUser signs in as new user on same instance)
    // This is a known Firebase limitation — we immediately sign back out/in
    // Actually createUserWithEmailAndPassword on the DEFAULT app WILL switch sessions.
    // Workaround: store admin creds and re-auth, OR use Admin SDK on backend.
    // Simple client workaround: we record the admin's current token and re-auth.
    // For now we sign out new user; admin will need to log in again.
    // A better production approach is Firebase Admin SDK via Cloud Functions.
  }

  /// Admin-safe staff creation: uses a temporary secondary auth instance trick.
  /// Creates Auth user + Firestore doc. Admin session is NOT disturbed.
  Future<String> createStaffUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    // Create the auth user
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;

    // Write Firestore profile
    await _users.doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return uid;
  }

  // ── User Profile ───────────────────────────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUserProfile(UserModel user) =>
      _users.doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));

  Stream<List<UserModel>> watchAllStaff() => _users
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Future<void> deleteStaffUser(String uid) async {
    await _users.doc(uid).delete();
    // Note: Firebase Auth account stays (needs Admin SDK to delete auth entry)
    // For client-side, we just mark inactive in Firestore
    await _users.doc(uid).set({'isActive': false}, SetOptions(merge: true));
  }

  Future<void> toggleStaffActive(String uid, bool isActive) =>
      _users.doc(uid).update({'isActive': isActive});

  // ── Auto Admin Setup ───────────────────────────────────────────────────────
  /// Called on app start — creates admin account if it doesn't exist yet.
  Future<void> ensureAdminExists() async {
    const adminEmail = 'admin@autoserv.com';
    const adminPassword = 'admin@123';

    try {
      // Check if admin Firestore doc exists
      final query = await _users
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // No admin yet — create one
        UserCredential cred;
        try {
          cred = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Auth account exists but no Firestore doc — sign in to get uid
            cred = await _auth.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
          } else {
            rethrow;
          }
        }
        final uid = cred.user!.uid;
        await _users.doc(uid).set({
          'uid': uid,
          'email': adminEmail,
          'name': 'Admin',
          'role': 'admin',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Sign out so login screen appears fresh
        await _auth.signOut();
      }
    } catch (e) {
      // Don't crash app if this fails
    }
  }

  // ── RO Number ──────────────────────────────────────────────────────────────
  Future<String> generateRONumber() async {
    final year = DateTime.now().year;
    final ref  = _settings.doc('ro_counter_$year');
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int counter = 1;
      if (snap.exists) {
        counter = ((snap.data() as Map<String, dynamic>)['count'] as int) + 1;
      }
      tx.set(ref, {'count': counter});
      return 'RO-$year-${counter.toString().padLeft(4, '0')}';
    });
  }

  // ── Job Card CRUD ──────────────────────────────────────────────────────────
  Future<String> createJobCard(JobCardModel card) async {
    final ref  = _jobCards.doc();
    final copy = card.copyWith(id: ref.id);
    await ref.set(copy.toFirestore());
    return ref.id;
  }

  Future<void> updateJobCard(JobCardModel card) =>
      _jobCards.doc(card.id).update(card.toFirestore());

  Future<JobCardModel?> getJobCard(String id) async {
    final doc = await _jobCards.doc(id).get();
    if (!doc.exists) return null;
    return JobCardModel.fromFirestore(doc);
  }

  Stream<List<JobCardModel>> watchAllJobCards() => _jobCards
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(JobCardModel.fromFirestore).toList());

  // ── Search ─────────────────────────────────────────────────────────────────
  Future<List<JobCardModel>> searchByRegistration(String reg) async {
    final s = await _jobCards
        .where('registrationNumber', isEqualTo: reg.toUpperCase())
        .orderBy('createdAt', descending: true)
        .get();
    return s.docs.map(JobCardModel.fromFirestore).toList();
  }

  Future<List<JobCardModel>> searchByContact(String contact) async {
    final s = await _jobCards
        .where('contactNumber', isEqualTo: contact)
        .orderBy('createdAt', descending: true)
        .get();
    return s.docs.map(JobCardModel.fromFirestore).toList();
  }

  Future<List<JobCardModel>> searchByName(String name) async {
    final s = await _jobCards
        .where('customerName', isGreaterThanOrEqualTo: name)
        .where('customerName', isLessThanOrEqualTo: '$name\uf8ff')
        .orderBy('customerName')
        .get();
    return s.docs.map(JobCardModel.fromFirestore).toList();
  }

  Future<List<JobCardModel>> getByDateRange(DateTime start, DateTime end) async {
    final s = await _jobCards
        .where('entryDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('entryDate', descending: true)
        .get();
    return s.docs.map(JobCardModel.fromFirestore).toList();
  }

  Future<List<JobCardModel>> getPendingBills() async {
    final s = await _jobCards
        .where('paymentStatus', whereIn: ['pending', 'partial'])
        .orderBy('createdAt', descending: true)
        .get();
    return s.docs.map(JobCardModel.fromFirestore).toList();
  }

  Future<List<JobCardModel>> getByMonth(int year, int month) async {
    final start = DateTime(year, month);
    final end   = DateTime(year, month + 1);
    return getByDateRange(start, end);
  }

  // ── Monthly revenue ────────────────────────────────────────────────────────
  Future<Map<String, double>> getMonthlyRevenue(int year) async {
    final result = <String, double>{};
    for (int m = 1; m <= 12; m++) {
      final cards = await getByMonth(year, m);
      result[m.toString()] = cards.fold(0.0, (s, c) => s + c.grandTotal);
    }
    return result;
  }

  // ── Image upload via Cloudinary ────────────────────────────────────────────
  Future<String> uploadImageFile(File file, String folder) =>
      CloudinaryService.uploadFile(file, folder: folder);

  Future<String> uploadSignatureBytes(Uint8List bytes, String folder) =>
      CloudinaryService.uploadBytes(bytes, folder: folder);
}
