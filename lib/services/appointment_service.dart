import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Book appointment
  Future<String> bookAppointment({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
    required DateTime appointmentDate,
    required String timeSlot,
    required double consultationFee,
  }) async {
    try {
      final appointmentId = _firestore.collection('appointments').doc().id;

      await _firestore.collection('appointments').doc(appointmentId).set({
        'id': appointmentId,
        'patientId': patientId,
        'doctorId': doctorId,
        'patientName': patientName,
        'doctorName': doctorName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'timeSlot': timeSlot,
        'status': 'Pending',
        'consultationFee': consultationFee,
        'isPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return appointmentId;
    } catch (e) {
      throw Exception('Error booking appointment: $e');
    }
  }

  // Get appointments for patient
  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    try {
      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('appointmentDate', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => AppointmentModel.fromMap(doc.data(), docId: doc.id),
                )
                .toList();
          });
    } catch (e) {
      throw Exception('Error fetching patient appointments: $e');
    }
  }

  // Get appointments for doctor
  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    try {
      return _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('appointmentDate', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => AppointmentModel.fromMap(doc.data(), docId: doc.id),
                )
                .toList();
          });
    } catch (e) {
      throw Exception('Error fetching doctor appointments: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        if (newStatus == 'Completed')
          'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating appointment status: $e');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'Cancelled',
      });
    } catch (e) {
      throw Exception('Error cancelling appointment: $e');
    }
  }

  // Add prescription
  Future<void> addPrescription(
    String appointmentId,
    String prescription,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'prescription': prescription,
      });
    } catch (e) {
      throw Exception('Error adding prescription: $e');
    }
  }

  // Add appointment notes
  Future<void> addNotes(String appointmentId, String notes) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Error adding notes: $e');
    }
  }

  // Mark appointment as paid
  Future<void> markAsPaid(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'isPaid': true,
      });
    } catch (e) {
      throw Exception('Error marking as paid: $e');
    }
  }

  // Get upcoming appointments for patient
  Stream<List<AppointmentModel>> getUpcomingAppointments(String patientId) {
    try {
      final now = DateTime.now();
      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: now.toIso8601String(),
          )
          .where('status', isNotEqualTo: 'Cancelled')
          .orderBy('appointmentDate')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => AppointmentModel.fromMap(doc.data(), docId: doc.id),
                )
                .toList();
          });
    } catch (e) {
      throw Exception('Error fetching upcoming appointments: $e');
    }
  }

  // Get completed appointments
  Stream<List<AppointmentModel>> getCompletedAppointments(String patientId) {
    try {
      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'Completed')
          .orderBy('appointmentDate', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => AppointmentModel.fromMap(doc.data(), docId: doc.id),
                )
                .toList();
          });
    } catch (e) {
      throw Exception('Error fetching completed appointments: $e');
    }
  }
}
