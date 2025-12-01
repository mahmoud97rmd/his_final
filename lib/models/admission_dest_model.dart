class AdmissionDest {
  final String id, name;
  AdmissionDest({required this.id, required this.name});
  factory AdmissionDest.fromJson(Map<String, dynamic> json) => 
    AdmissionDest(id: json['id']??'', name: json['name']??'');
}
