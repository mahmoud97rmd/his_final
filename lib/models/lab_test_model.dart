class LabTest {
  final String id, name;
  final bool isGroup;
  LabTest({required this.id, required this.name, required this.isGroup});
  factory LabTest.fromJson(Map<String, dynamic> json) => 
    LabTest(id: json['id']??'', name: json['name']??'', isGroup: (json['isGroup'] == 1));
}
