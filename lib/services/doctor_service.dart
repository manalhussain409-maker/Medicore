import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';
import '../models/review_model.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DoctorModel>> getAllDoctors() {
    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .where((doc) => doc.data()['isRegistered'] != false)
            .map((doc) => DoctorModel.fromMap(doc.data(), docId: doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  Stream<List<DoctorModel>> getDoctorsBySpecialty(String specialty) {
    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .where('specialty', isEqualTo: specialty)
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .where((doc) => doc.data()['isRegistered'] != false)
            .map((doc) => DoctorModel.fromMap(doc.data(), docId: doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  Future<DoctorModel?> getDoctorById(String doctorId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(doctorId).get();

      if (doc.exists && doc.data() != null) {
        return DoctorModel.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error getting doctor: $e');
    }
  }

  Stream<DoctorModel?> getDoctorStream(String doctorId) {
    try {
      return _firestore.collection('users').doc(doctorId).snapshots().map((
        doc,
      ) {
        if (doc.exists && doc.data() != null) {
          return DoctorModel.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id,
          );
        }
        return null;
      });
    } catch (e) {
      throw Exception('Error getting doctor stream: $e');
    }
  }

  Future<String> addReview({
    required String doctorId,
    required String patientId,
    required String patientName,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewId =
          _firestore.collection('users/$doctorId/reviews').doc().id;

      await _firestore
          .collection('users')
          .doc(doctorId)
          .collection('reviews')
          .doc(reviewId)
          .set({
        'id': reviewId,
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateDoctorRating(doctorId);

      return reviewId;
    } catch (e) {
      throw Exception('Error adding review: $e');
    }
  }

  Stream<List<ReviewModel>> getDoctorReviews(String doctorId) {
    try {
      return _firestore
          .collection('users')
          .doc(doctorId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), docId: doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }

  Future<void> _updateDoctorRating(String doctorId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('users')
          .doc(doctorId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc['rating'] ?? 0).toDouble();
      }

      double averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('users').doc(doctorId).update({
        'rating': averageRating,
        'totalReviews': reviewsSnapshot.docs.length,
      });
    } catch (e) {
      throw Exception('Error updating rating: $e');
    }
  }

  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error searching doctors: $e');
    }
  }

  Stream<List<DoctorModel>> getTopRatedDoctors({int limit = 10}) {
    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DoctorModel.fromMap(doc.data(), docId: doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Error fetching top-rated doctors: $e');
    }
  }

  Future<void> updateDoctorOnlineStatus(
    String doctorId,
    bool isAvailable,
  ) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      throw Exception('Error updating availability: $e');
    }
  }

  Future<void> updateDoctorProfile({
    required String doctorId,
    String? name,
    String? specialty,
    String? experience,
    String? fee,
    String? imageUrl,
    Map<String, List<String>>? availability,
    String? bio,
    String? phoneNumber,
    String? licenseNumber,
    String? university,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (specialty != null) updates['specialty'] = specialty;
      if (experience != null) updates['experience'] = experience;
      if (fee != null) updates['fee'] = fee;
      if (imageUrl != null) {
        updates['imageUrl'] = imageUrl;
        updates['profileImageUrl'] = imageUrl;
      }
      if (availability != null) updates['availability'] = availability;
      if (bio != null) updates['bio'] = bio;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (licenseNumber != null) updates['licenseNumber'] = licenseNumber;
      if (university != null) updates['university'] = university;

      await _firestore.collection('users').doc(doctorId).update(updates);
    } catch (e) {
      throw Exception('Error updating doctor profile: $e');
    }
  }

  Future<void> updateDoctorAvailabilitySettings(
    String doctorId,
    Map<String, List<String>> availability,
  ) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'availability': availability,
      });
    } catch (e) {
      throw Exception('Error updating availability settings: $e');
    }
  }

  Future<List<String>> getSpecialties() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .get();

      Set<String> specialties = {};
      for (var doc in snapshot.docs) {
        final specialty = doc['specialty'];
        if (specialty != null) {
          specialties.add(specialty);
        }
      }

      return specialties.toList()..sort();
    } catch (e) {
      throw Exception('Error fetching specialties: $e');
    }
  }

  static Map<String, List<String>> get defaultAvailability => {
        'Monday': ['09:00 AM', '11:00 AM', '03:00 PM'],
        'Wednesday': ['09:00 AM', '11:00 AM', '03:00 PM'],
        'Friday': ['09:00 AM', '11:00 AM', '03:00 PM'],
      };

  Future<void> createDoctorProfile({
    required String uid,
    required String name,
    required String specialty,
    required String experience,
    required String fee,
    String? imageUrl,
    String? phoneNumber,
    String? bio,
    Map<String, List<String>>? availability,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'specialty': specialty,
        'experience': experience,
        'fee': fee,
        'imageUrl': imageUrl,
        'profileImageUrl': imageUrl,
        'availability': availability ?? defaultAvailability,
        'rating': 5.0,
        'totalReviews': 0,
        'totalAppointments': 0,
        'isVerified': false,
        'isAvailable': true,
        'phoneNumber': phoneNumber,
        'bio': bio,
      });
    } catch (e) {
      throw Exception('Error creating doctor profile: $e');
    }
  }

  Future<void> createPendingDoctor({
    required String name,
    required String email,
    required String specialty,
    required String experience,
    required String fee,
    String? imageUrl,
    Map<String, List<String>>? availability,
  }) async {
    try {
      final pendingUid = 'pending_${email.replaceAll(RegExp(r'[@.]'), '_')}';
      await _firestore.collection('users').doc(pendingUid).set({
        'uid': pendingUid,
        'name': name,
        'email': email,
        'role': 'Doctor',
        'specialty': specialty,
        'experience': experience,
        'fee': fee,
        'imageUrl': imageUrl,
        'profileImageUrl': imageUrl,
        'availability': availability ?? defaultAvailability,
        'rating': 5.0,
        'totalReviews': 0,
        'totalAppointments': 0,
        'isVerified': false,
        'isAvailable': true,
        'isRegistered': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating pending doctor: $e');
    }
  }

  Future<bool> hasPendingDoctor(String email) async {
    try {
      final pendingUid = 'pending_${email.replaceAll(RegExp(r'[@.]'), '_')}';
      final doc = await _firestore.collection('users').doc(pendingUid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
