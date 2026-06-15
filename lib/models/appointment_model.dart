class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final DateTime appointmentDate;
  final String timeSlot;
  final String status; // 'Pending', 'Confirmed', 'Completed', 'Cancelled'
  final String? notes;
  final String? prescription;
  final double? consultationFee;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? completedAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.notes,
    this.prescription,
    this.consultationFee,
    this.isPaid = false,
    required this.createdAt,
    this.completedAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AppointmentModel(
      id: map['id'] ?? docId ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorName: map['doctorName'] ?? '',
      appointmentDate: DateTime.parse(
        map['appointmentDate'] ?? DateTime.now().toIso8601String(),
      ),
      timeSlot: map['timeSlot'] ?? '10:00 AM',
      status: map['status'] ?? 'Pending',
      notes: map['notes'],
      prescription: map['prescription'],
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status,
      'notes': notes,
      'prescription': prescription,
      'consultationFee': consultationFee ?? 0,
      'isPaid': isPaid,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    DateTime? appointmentDate,
    String? timeSlot,
    String? status,
    String? notes,
    String? prescription,
    double? consultationFee,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      prescription: prescription ?? this.prescription,
      consultationFee: consultationFee ?? this.consultationFee,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
