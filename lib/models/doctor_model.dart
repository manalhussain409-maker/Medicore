class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String experience;
  final String fee;
  final String imageUrl;
  final List<String> availableDays;
  final List<String> availableSlots;
  final double rating;
  final String? bio;
  final String? phoneNumber;
  final String? licenseNumber;
  final String? university;
  final int? totalReviews;
  final int? totalAppointments;
  final bool isVerified;
  final bool isAvailable;
  final DateTime? createdAt;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.fee,
    required this.imageUrl,
    required this.availableDays,
    required this.availableSlots,
    required this.rating,
    this.bio,
    this.phoneNumber,
    this.licenseNumber,
    this.university,
    this.totalReviews,
    this.totalAppointments,
    this.isVerified = false,
    this.isAvailable = true,
    this.createdAt,
  });

  // Convert a DoctorModel instance into a Map to save to Firebase Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'experience': experience,
      'fee': fee,
      'imageUrl': imageUrl,
      'availableDays': availableDays,
      'availableSlots': availableSlots,
      'rating': rating,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'university': university,
      'totalReviews': totalReviews ?? 0,
      'totalAppointments': totalAppointments ?? 0,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Factory constructor to safely create a DoctorModel from a Firestore Document Snapshot
  factory DoctorModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return DoctorModel(
      id: map['id'] ?? docId ?? '',
      name: map['name'] ?? 'Unknown Doctor',
      specialty: map['specialty'] ?? 'General Physician',
      experience: map['experience'] ?? '0 Years',
      fee: map['fee'] ?? 'Rs. 0',
      imageUrl: map['imageUrl'] ?? 'placeholder',
      availableDays: List<String>.from(map['availableDays'] ?? []),
      availableSlots: List<String>.from(map['availableSlots'] ?? []),
      rating: (map['rating'] ?? 5.0).toDouble(),
      bio: map['bio'],
      phoneNumber: map['phoneNumber'],
      licenseNumber: map['licenseNumber'],
      university: map['university'],
      totalReviews: map['totalReviews'] ?? 0,
      totalAppointments: map['totalAppointments'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
    );
  }

  DoctorModel copyWith({
    String? id,
    String? name,
    String? specialty,
    String? experience,
    String? fee,
    String? imageUrl,
    List<String>? availableDays,
    List<String>? availableSlots,
    double? rating,
    String? bio,
    String? phoneNumber,
    String? licenseNumber,
    String? university,
    int? totalReviews,
    int? totalAppointments,
    bool? isVerified,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      experience: experience ?? this.experience,
      fee: fee ?? this.fee,
      imageUrl: imageUrl ?? this.imageUrl,
      availableDays: availableDays ?? this.availableDays,
      availableSlots: availableSlots ?? this.availableSlots,
      rating: rating ?? this.rating,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      university: university ?? this.university,
      totalReviews: totalReviews ?? this.totalReviews,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
