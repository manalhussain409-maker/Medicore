import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error getting current user: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (gender != null) updates['gender'] = gender;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = dateOfBirth.toIso8601String();
      }
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (bio != null) updates['bio'] = bio;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // Set user online status
  Future<void> setUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating online status: $e');
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // Get all doctors
  Future<List<UserModel>> getAllDoctors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  // Get all patients
  Future<List<UserModel>> getAllPatients() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Patient')
          .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Error fetching patients: $e');
    }
  }

  // Delete user (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      // Mark user as deleted instead of hard delete
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Error checking user existence: $e');
    }
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String userId) {
    try {
      return _firestore.collection('users').doc(userId).snapshots().map((doc) {
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
        return null;
      });
    } catch (e) {
      throw Exception('Error getting user stream: $e');
    }
  }
}
