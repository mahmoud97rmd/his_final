class Visit {
  final String visitId, date, diagnosis, medications, labs, status;
  Visit({
    required this.visitId,
    required this.date,
    required this.diagnosis,
    required this.medications,
    required this.labs,
    required this.status,
  });
  
  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      visitId: json['visitId']?.toString() ?? '',
      date: json['date'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      medications: json['medications'] ?? '',
      labs: json['labs'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
