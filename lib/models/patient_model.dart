class Patient {
  final String visitId, profileId, name, age, doctorName, diagnosis;
  final int queue;
  Patient({
    required this.visitId, 
    required this.profileId, 
    required this.name, 
    required this.age, 
    required this.queue, 
    required this.doctorName, 
    required this.diagnosis
  });
  
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      visitId: json['id']?.toString() ?? '', 
      profileId: json['profileId']?.toString() ?? '',
      name: json['name'] ?? 'غير معروف', 
      age: json['age'] ?? '',
      queue: int.tryParse(json['queue'].toString()) ?? 0,
      doctorName: json['note'] ?? '', 
      diagnosis: json['diag'] ?? '',
    );
  }
}
