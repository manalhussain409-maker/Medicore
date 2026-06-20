import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    try {
      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snapshot) {
            final appointments = snapshot.docs
                .map(
                  (doc) => AppointmentModel.fromMap(doc.data(), docId: doc.id),
                )
                .toList();
            appointments.sort(
              (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
            );
            return appointments;
          });
    } catch (e) {
      throw Exception('Error fetching patient appointments: $e');
    }
  }

  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    try {
      return _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots()
          .map((snapshot) {
            final appointments = snapshot.docs
                .map(
                  (doc) => AppointmentModel.fromMap(doc.data(), docId: doc.id),
                )
                .toList();
            appointments.sort(
              (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
            );
            return appointments;
          });
    } catch (e) {
      throw Exception('Error fetching doctor appointments: $e');
    }
  }

  Stream<List<AppointmentModel>> getUpcomingAppointments(String patientId) {
    try {
      final now = DateTime.now();
      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snapshot) {
            final appointments = snapshot.docs
                .map(
                  (doc) => AppointmentModel.fromMap(doc.data(), docId: doc.id),
                )
                .where(
                  (a) =>
                      a.status != 'Cancelled' &&
                      a.status != 'Completed' &&
                      !a.appointmentDate.isBefore(
                        DateTime(now.year, now.month, now.day),
                      ),
                )
                .toList();
            appointments.sort(
              (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
            );
            return appointments;
          });
    } catch (e) {
      throw Exception('Error fetching upcoming appointments: $e');
    }
  }

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

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'Cancelled',
      });
    } catch (e) {
      throw Exception('Error cancelling appointment: $e');
    }
  }

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

  Future<void> addNotes(String appointmentId, String notes) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Error adding notes: $e');
    }
  }

  Future<void> markAsPaid(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'isPaid': true,
      });
    } catch (e) {
      throw Exception('Error marking as paid: $e');
    }
  }

  Future<Set<String>> getBookedSlotsForDoctorOnDate(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', whereIn: ['Pending', 'Confirmed'])
          .get();

      final bookedSlots = <String>{};
      for (var doc in snapshot.docs) {
        final apptDate = doc['appointmentDate'] as String?;
        if (apptDate != null) {
          final parsed = DateTime.tryParse(apptDate);
          if (parsed != null &&
              parsed.year == date.year &&
              parsed.month == date.month &&
              parsed.day == date.day) {
            bookedSlots.add(doc['timeSlot'] as String);
          }
        }
      }
      return bookedSlots;
    } catch (e) {
      return {};
    }
  }
}
