class Clinic {
  final String name;
  Clinic({required this.name});
  factory Clinic.fromJson(Map<String, dynamic> json) => Clinic(name: json['name'] ?? '');
}
