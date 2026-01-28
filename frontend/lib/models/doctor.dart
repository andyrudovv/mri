import 'patient.dart';

class Doctor {
  final dynamic id; // Can be int or String
  final String name;
  final String email;
  final String specialization;
  final String? profileImage;
  final List<Patient> patients;
  final DateTime createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.specialization,
    this.profileImage,
    this.patients = const [],
    required this.createdAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialization': specialization,
      'profileImage': profileImage,
      'patients': patients.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  // Inside doctor.dart
factory Doctor.fromJson(Map<String, dynamic> json) {
  return Doctor(
    // Force ID to String if it comes as an int from Postgres
    id: json['id'].toString(), 
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    specialization: json['specialization'] ?? '',
    profileImage: json['profileImage'],
    // Defensive check for patients list
    patients: (json['patients'] as List<dynamic>?)
            ?.map((p) => Patient.fromJson(p as Map<String, dynamic>))
            .toList() ?? [], 
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );
}

  // Copy with method
  Doctor copyWith({
    dynamic id,
    String? name,
    String? email,
    String? specialization,
    String? profileImage,
    List<Patient>? patients,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
      profileImage: profileImage ?? this.profileImage,
      patients: patients ?? this.patients,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Add a patient
  Doctor addPatient(Patient patient) {
    final updatedPatients = [...patients, patient];
    return copyWith(patients: updatedPatients);
  }

  // Remove a patient by ID
  Doctor removePatient(dynamic patientId) {
    final updatedPatients =
        patients.where((p) => p.id != patientId).toList();
    return copyWith(patients: updatedPatients);
  }
}

class AuthResponse {
  final String token;
  final String? refreshToken;
  final Doctor doctor;

  AuthResponse({
    required this.token,
    this.refreshToken,
    required this.doctor,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      refreshToken: json['refresh_token'],
      // We pass the nested 'doctor' object to your Doctor.fromJson
      doctor: Doctor.fromJson(json['doctor'] as Map<String, dynamic>),
    );
  }
}