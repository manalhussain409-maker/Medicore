import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          role: role,
        );

        await _firestore.collection('users').doc(user.uid).set({
          ...newUser.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (role == 'Doctor') {
          await _migratePendingDoctorRecord(
            email: email,
            realUid: user.uid,
            name: name,
          );
        }

        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _migratePendingDoctorRecord({
    required String email,
    required String realUid,
    required String name,
  }) async {
    try {
      final pendingUid = 'pending_${email.replaceAll(RegExp(r'[@.]'), '_')}';
      final pendingDoc =
          await _firestore.collection('users').doc(pendingUid).get();

      if (!pendingDoc.exists || pendingDoc.data() == null) return;

      final pendingData = pendingDoc.data()!;

      if (pendingData['isRegistered'] == true) return;

      Map<String, List<String>> availability = {};
      if (pendingData['availability'] != null &&
          pendingData['availability'] is Map) {
        final raw = pendingData['availability'] as Map;
        raw.forEach((key, value) {
          if (value is List) {
            availability[key.toString()] =
                List<String>.from(value.map((e) => e.toString()));
          }
        });
      } else {
        final days = List<String>.from(
            pendingData['availableDays'] ?? ['Monday', 'Wednesday', 'Friday']);
        final slots = List<String>.from(pendingData['availableSlots'] ??
            ['09:00 AM', '11:00 AM', '03:00 PM']);
        for (final day in days) {
          availability[day] = List<String>.from(slots);
        }
      }

      final doctorFields = {
        'specialty': pendingData['specialty'] ?? 'General Physician',
        'experience': pendingData['experience'] ?? '1',
        'fee': pendingData['fee'] ?? '500',
        'imageUrl': pendingData['imageUrl'],
        'profileImageUrl':
            pendingData['profileImageUrl'] ?? pendingData['imageUrl'],
        'availability': availability,
        'rating': pendingData['rating'] ?? 5.0,
        'totalReviews': pendingData['totalReviews'] ?? 0,
        'totalAppointments': pendingData['totalAppointments'] ?? 0,
        'isVerified': pendingData['isVerified'] ?? false,
        'isAvailable': true,
        'isRegistered': true,
        'bio': pendingData['bio'],
        'phoneNumber': pendingData['phoneNumber'],
        'licenseNumber': pendingData['licenseNumber'],
        'university': pendingData['university'],
      };

      await _firestore.collection('users').doc(realUid).update(doctorFields);

      await pendingDoc.reference.delete();
    } catch (e) {
      print('Migration error: $e');
    }
  }

  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  User? get currentUser => _auth.currentUser;
}
