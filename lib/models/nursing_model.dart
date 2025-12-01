class NursingService {
  final String id, name;
  String resultValue;
  NursingService({required this.id, required this.name, this.resultValue = ""});
  factory NursingService.fromJson(Map<String, dynamic> json) => 
    NursingService(id: json['id']??'', name: json['name']??'');
}
