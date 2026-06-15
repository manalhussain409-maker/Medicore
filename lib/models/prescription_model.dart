class PrescriptionModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final List<Medicine> medicines;
  final String? notes;
  final DateTime issuedDate;
  final DateTime? expiryDate;

  PrescriptionModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.medicines,
    this.notes,
    required this.issuedDate,
    this.expiryDate,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    List<Medicine> medicineList = [];
    if (map['medicines'] != null) {
      medicineList = (map['medicines'] as List)
          .map((med) => Medicine.fromMap(med))
          .toList();
    }

    return PrescriptionModel(
      id: map['id'] ?? docId ?? '',
      appointmentId: map['appointmentId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      patientName: map['patientName'] ?? '',
      medicines: medicineList,
      notes: map['notes'],
      issuedDate: DateTime.parse(
        map['issuedDate'] ?? DateTime.now().toIso8601String(),
      ),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'notes': notes,
      'issuedDate': issuedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}

class Medicine {
  final String name;
  final String dosage;
  final String frequency;
  final int duration; // in days
  final String? instructions;

  Medicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? 7,
      instructions: map['instructions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}
