class Diagnosis {
  final String id, code, arName;
  Diagnosis({required this.id, required this.code, required this.arName});
  factory Diagnosis.fromJson(Map<String, dynamic> json) => 
    Diagnosis(id: json['id']??'', code: json['code']??'', arName: json['arName']??'');
}
