class Medicine {
  final String id, name, unit;
  String dosage;
  Medicine({required this.id, required this.name, required this.unit, this.dosage = ""});
  factory Medicine.fromJson(Map<String, dynamic> json) => 
    Medicine(id: json['id']??'', name: json['name']??'', unit: json['unit']??'');
}
