class XRay {
  final String id, name;
  XRay({required this.id, required this.name});
  factory XRay.fromJson(Map<String, dynamic> json) => 
    XRay(id: json['id']??'', name: json['name']??'');
}
