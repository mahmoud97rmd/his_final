class Visit {
  final String visitId, date, diagnosis, medications, labs, xrays, status;
  final String consultation, referral, admission, complaint, exam, death;
  Visit({
    required this.visitId,
    required this.date,
    required this.diagnosis,
    required this.medications,
    required this.labs,
    required this.xrays,
    required this.status,
    this.consultation = '',
    this.referral = '',
    this.admission = '',
    this.complaint = '',
    this.exam = '',
    this.death = '',
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      visitId: json['visitId']?.toString() ?? '',
      date: json['date'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      medications: json['medications'] ?? '',
      labs: json['labs'] ?? '',
      xrays: json['xrays'] ?? '',
      status: json['status'] ?? '',
      consultation: json['consultation'] ?? '',
      referral: json['referral'] ?? '',
      admission: json['admission'] ?? '',
      complaint: json['complaint'] ?? '',
      exam: json['exam'] ?? '',
      death: json['death'] ?? '',
    );
  }
}
