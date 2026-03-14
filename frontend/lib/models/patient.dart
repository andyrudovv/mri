class Patient {
  final dynamic id; // Can be int or String
  final String name;
  final int age;
  final String gender;
  String disease; // Non-final to allow updates after analysis
  final String? notes;
  final DateTime createdAt;
  final String url;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.disease,
    this.notes,
    required this.createdAt,
    required this.url
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'disease': disease,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'url': url
    };
  }

  // Create from JSON
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      disease: json['disease'] ?? '',
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      url: json['url'] ?? ''
    );
  }

  // Copy with method
  Patient copyWith({
    dynamic id,
    String? name,
    int? age,
    String? gender,
    String? disease,
    String? notes,
    DateTime? createdAt,
    String? url
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      disease: disease ?? this.disease,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      url: url ?? this.url
    );
  }
}
