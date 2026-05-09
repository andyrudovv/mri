class Patient {
  final dynamic id;
  final String? iin;
  final String name;
  final int age;
  final String gender;
  String disease;
  final String? notes;
  final String? doctorName;
  final String? doctorSpecialization;
  final DateTime createdAt;
  final String url;

  Patient({
    required this.id,
    this.iin,
    required this.name,
    required this.age,
    required this.gender,
    required this.disease,
    this.notes,
    this.doctorName,
    this.doctorSpecialization,
    required this.createdAt,
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iin': iin,
      'name': name,
      'age': age,
      'gender': gender,
      'disease': disease,
      'notes': notes,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'createdAt': createdAt.toIso8601String(),
      'url': url,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      iin: json['iin'],
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      disease: json['disease'] ?? '',
      notes: json['notes'],
      doctorName: json['doctorName'],
      doctorSpecialization: json['doctorSpecialization'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      url: json['url'] ?? '',
    );
  }

  Patient copyWith({
    dynamic id,
    String? iin,
    String? name,
    int? age,
    String? gender,
    String? disease,
    String? notes,
    String? doctorName,
    String? doctorSpecialization,
    DateTime? createdAt,
    String? url,
  }) {
    return Patient(
      id: id ?? this.id,
      iin: iin ?? this.iin,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      disease: disease ?? this.disease,
      notes: notes ?? this.notes,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
      createdAt: createdAt ?? this.createdAt,
      url: url ?? this.url,
    );
  }
}
