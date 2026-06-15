import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';
import '../models/review_model.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all doctors
  Stream<List<DoctorModel>> getAllDoctors() {
    try {
      return _firestore
          .collection('doctors')
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => DoctorModel.fromMap(doc.data(), docId: doc.id))
                .toList();
          });
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  // Get doctors by specialty
  Stream<List<DoctorModel>> getDoctorsBySpecialty(String specialty) {
    try {
      return _firestore
          .collection('doctors')
          .where('specialty', isEqualTo: specialty)
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => DoctorModel.fromMap(doc.data(), docId: doc.id))
                .toList();
          });
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  // Get doctor details
  Future<DoctorModel?> getDoctorById(String doctorId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

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

  // Get doctor stream for real-time updates
  Stream<DoctorModel?> getDoctorStream(String doctorId) {
    try {
      return _firestore.collection('doctors').doc(doctorId).snapshots().map((
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

  // Add review for doctor
  Future<String> addReview({
    required String doctorId,
    required String patientId,
    required String patientName,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewId = _firestore
          .collection('doctors/$doctorId/reviews')
          .doc()
          .id;

      await _firestore
          .collection('doctors')
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

      // Update doctor rating
      await _updateDoctorRating(doctorId);

      return reviewId;
    } catch (e) {
      throw Exception('Error adding review: $e');
    }
  }

  // Get reviews for doctor
  Stream<List<ReviewModel>> getDoctorReviews(String doctorId) {
    try {
      return _firestore
          .collection('doctors')
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

  // Update doctor rating
  Future<void> _updateDoctorRating(String doctorId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc['rating'] ?? 0).toDouble();
      }

      double averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('doctors').doc(doctorId).update({
        'rating': averageRating,
        'totalReviews': reviewsSnapshot.docs.length,
      });
    } catch (e) {
      throw Exception('Error updating rating: $e');
    }
  }

  // Search doctors
  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      final snapshot = await _firestore
          .collection('doctors')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error searching doctors: $e');
    }
  }

  // Get top-rated doctors
  Stream<List<DoctorModel>> getTopRatedDoctors({int limit = 10}) {
    try {
      return _firestore
          .collection('doctors')
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

  // Update doctor availability
  Future<void> updateDoctorAvailability(
    String doctorId,
    bool isAvailable,
  ) async {
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      throw Exception('Error updating availability: $e');
    }
  }

  // Get specialties
  Future<List<String>> getSpecialties() async {
    try {
      final snapshot = await _firestore.collection('doctors').get();

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
}
