import '../utils/firestore_utils.dart';

class DoctorModel {
  final String uid;
  final String name;
  final String specialty;
  final String experience;
  final String fee;
  final String? imageUrl;
  final Map<String, List<String>> availability;
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
    required this.uid,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.fee,
    this.imageUrl,
    required this.availability,
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

  List<String> get availableDays => availability.keys.toList();

  List<String> getSlotsForDay(String dayName) {
    return availability[dayName] ?? [];
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'specialty': specialty,
      'experience': experience,
      'fee': fee,
      'imageUrl': imageUrl,
      'availability': availability,
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

  factory DoctorModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    Map<String, List<String>> parsedAvailability = {};

    if (map['availability'] != null && map['availability'] is Map) {
      final raw = map['availability'] as Map;
      raw.forEach((key, value) {
        if (value is List) {
          parsedAvailability[key.toString()] =
              List<String>.from(value.map((e) => e.toString()));
        }
      });
    } else {
      final days = List<String>.from(map['availableDays'] ?? []);
      final slots = List<String>.from(map['availableSlots'] ?? []);
      if (days.isNotEmpty && slots.isNotEmpty) {
        for (final day in days) {
          parsedAvailability[day] = List<String>.from(slots);
        }
      }
    }

    return DoctorModel(
      uid: map['uid'] ?? docId ?? '',
      name: map['name'] ?? 'Unknown Doctor',
      specialty: map['specialty'] ?? 'General Physician',
      experience: map['experience'] ?? '0 Years',
      fee: map['fee'] ?? 'Rs. 0',
      imageUrl: map['imageUrl'],
      availability: parsedAvailability,
      rating: (map['rating'] ?? 5.0).toDouble(),
      bio: map['bio'],
      phoneNumber: map['phoneNumber'],
      licenseNumber: map['licenseNumber'],
      university: map['university'],
      totalReviews: map['totalReviews'] ?? 0,
      totalAppointments: map['totalAppointments'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }

  DoctorModel copyWith({
    String? uid,
    String? name,
    String? specialty,
    String? experience,
    String? fee,
    String? imageUrl,
    Map<String, List<String>>? availability,
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
      uid: uid ?? this.uid,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      experience: experience ?? this.experience,
      fee: fee ?? this.fee,
      imageUrl: imageUrl ?? this.imageUrl,
      availability: availability ?? this.availability,
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
