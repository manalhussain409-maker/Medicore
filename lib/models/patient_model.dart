import '../utils/firestore_utils.dart';

class PatientModel {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? city;
  final String? bloodGroup;
  final List<String>? allergies;
  final List<String>? medicalHistory;
  final String? emergencyContact;
  final String? insuranceProvider;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  PatientModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.city,
    this.bloodGroup,
    this.allergies,
    this.medicalHistory,
    this.emergencyContact,
    this.insuranceProvider,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      gender: map['gender'],
      dateOfBirth: parseFirestoreDate(map['dateOfBirth']),
      address: map['address'],
      city: map['city'],
      bloodGroup: map['bloodGroup'],
      allergies: map['allergies'] != null
          ? List<String>.from(map['allergies'])
          : null,
      medicalHistory: map['medicalHistory'] != null
          ? List<String>.from(map['medicalHistory'])
          : null,
      emergencyContact: map['emergencyContact'],
      insuranceProvider: map['insuranceProvider'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: parseFirestoreDate(map['lastSeen']),
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': 'Patient',
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'city': city,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'emergencyContact': emergencyContact,
      'insuranceProvider': insuranceProvider,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  PatientModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? emergencyContact,
    String? insuranceProvider,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return PatientModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
