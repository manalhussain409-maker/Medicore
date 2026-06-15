class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'Patient', 'Doctor', or 'Admin'
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? city;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final String? bio;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.city,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.bio,
  });

  // Convert Firebase Firestore Document Data into our Flutter Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Patient',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      address: map['address'],
      city: map['city'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      bio: map['bio'],
    );
  }

  // Convert our Flutter Model into a Map format to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'city': city,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'bio': bio,
    };
  }

  // Copy with method for easy updates
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? phoneNumber,
    String? profileImageUrl,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
    );
  }
}
