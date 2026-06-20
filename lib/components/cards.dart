import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onBook;
  final VoidCallback onChat;
  final bool hasActiveAppointment;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onBook,
    required this.onChat,
    this.hasActiveAppointment = false,
  });

  @override
  Widget build(BuildContext context) {
    final availableDaysStr = doctor.availableDays.join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildDoctorImage(doctor.imageUrl),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doctor.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0A1931),
                          ),
                        ),
                      ),
                      if (doctor.isVerified)
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                  Text(
                    doctor.specialty,
                    style: const TextStyle(
                      color: Color(0xFF008080),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(
                        ' ${doctor.rating.toStringAsFixed(1)} - ${doctor.totalReviews ?? 0} reviews',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${doctor.fee} - ${doctor.experience} Yrs',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (availableDaysStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Available: $availableDaysStr',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Book',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: onChat,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF008080).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Color(0xFF008080),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        try {
          final base64Str = imageUrl.split(',').last;
          return Image.memory(
            base64Decode(base64Str),
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          );
        } catch (e) {
          return const Icon(Icons.person, color: Color(0xFF008080));
        }
      }
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF008080),
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) =>
            const Icon(Icons.person, color: Color(0xFF008080)),
      );
    }
    return const Icon(Icons.person, color: Color(0xFF008080));
  }
}

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onDetails;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onDetails,
    this.onCancel,
    this.onReschedule,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF4CAF50);
      case 'Pending':
        return const Color(0xFFFFC107);
      case 'Completed':
        return const Color(0xFF2196F3);
      case 'Cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1931),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year} at ${appointment.timeSlot}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (appointment.consultationFee != null)
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rs. ${appointment.consultationFee}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (appointment.isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: appointment.status != 'Completed' &&
                            appointment.status != 'Cancelled'
                        ? onCancel
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: appointment.status != 'Completed' &&
                                appointment.status != 'Cancelled'
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: appointment.status != 'Completed' &&
                                appointment.status != 'Cancelled'
                            ? Colors.red
                            : Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: appointment.status != 'Completed' &&
                            appointment.status != 'Cancelled'
                        ? onReschedule
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: appointment.status != 'Completed' &&
                                appointment.status != 'Cancelled'
                            ? const Color(0xFF008080)
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Reschedule',
                      style: TextStyle(
                        color: appointment.status != 'Completed' &&
                                appointment.status != 'Cancelled'
                            ? const Color(0xFF008080)
                            : Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
