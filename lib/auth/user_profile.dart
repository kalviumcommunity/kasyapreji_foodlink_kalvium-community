import 'package:cloud_firestore/cloud_firestore.dart';

/// A user's profile document at `users/{uid}`, matching the PRD's field
/// list. [role] is `null` until Role Setup is completed.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.phone,
    required this.photoUrl,
    required this.active,
  });

  final String uid;
  final String displayName;
  final String email;

  /// `'volunteer'`, `'coordinator'`, or `null` if not chosen yet.
  final String? role;
  final String phone;
  final String? photoUrl;
  final bool active;

  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String?,
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      active: data['active'] as bool? ?? true,
    );
  }
}

/// Reads and writes `users/{uid}` profile documents.
///
/// This is the only place in the app that talks to that collection, so the
/// field names and write shapes used here are the ones the Firestore
/// security rules were written against — see `firestore.rules`.
class UserProfileService {
  UserProfileService._();

  static final _users = FirebaseFirestore.instance.collection('users');

  /// Loads the signed-in user's profile, or `null` if it doesn't exist yet
  /// (for example, an account created before this existed, or a write that
  /// failed partway through last time).
  static Future<UserProfile?> load(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromSnapshot(doc);
  }

  /// Creates the profile document for a brand-new account, without a role
  /// (role is chosen next, in Role Setup). Does nothing if a profile
  /// already exists for this uid, so sign-up can safely call this even if
  /// it's retried — no duplicate writes.
  static Future<void> createIfMissing({
    required String uid,
    required String displayName,
    required String email,
    String phone = '',
  }) async {
    final ref = _users.doc(uid);
    final existing = await ref.get();
    if (existing.exists) return;
    await ref.set({
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'photoUrl': null,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sets `role` for the first time. Firestore's security rules — not this
  /// function — are what actually enforce that this can only happen once,
  /// and that `'coordinator'` requires prior approval; this can throw a
  /// [FirebaseException] with code `permission-denied` if that's violated,
  /// which callers must handle.
  static Future<void> setRole({required String uid, required String role}) {
    return _users.doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
