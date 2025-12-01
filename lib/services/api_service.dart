import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/patient_model.dart';
import '../models/clinic_model.dart';
import '../models/medicine_model.dart';
import '../models/xray_model.dart';
import '../models/lab_test_model.dart';
import '../models/diagnosis_model.dart';
import '../models/nursing_model.dart';
import '../models/admission_dest_model.dart';

class ApiService {
  static const String baseUrl = 'https://hisandroidapi.azurewebsites.net';
  static String? currentFacility;
  static String? currentUser; 
  
  final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl, 
    connectTimeout: const Duration(seconds: 15), 
    receiveTimeout: const Duration(seconds: 15)
  ));

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() { _initNotif(); }

  void _initNotif() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: android));
  }

  Future<void> showNotif(String body) async {
    const details = AndroidNotificationDetails(
      'his_ch', 
      'HIS', 
      importance: Importance.max, 
      priority: Priority.high
    );
    try { 
      await _notif.show(0, 'تم الإرسال', body, const NotificationDetails(android: details)); 
    } catch(e){}
  }

  Future<bool> _checkNet() async {
    var res = await Connectivity().checkConnectivity();
    return !res.contains(ConnectivityResult.none);
  }

  // --- GET Requests ---
  Future<List<Clinic>> getClinics(String user) async {
    if (!await _checkNet()) return [];
    try {
      var res = await _dio.get('/hisapi.asmx/getClinicList', queryParameters: {'user': user});
      if (res.statusCode == 200) return (res.data as List).map((e) => Clinic.fromJson(e)).toList();
      return [];
    } catch (e) { return []; }
  }

  Future<List<Patient>> getQueue(String facility, String doc, String clinic) async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      var res = await _dio.get('/hisapi.asmx/getQueueToday', 
        queryParameters: {'facility': facility, 'doctor': doc, 'clinic': clinic, 'dt': date});
      if (res.statusCode == 200) return (res.data as List).map((e) => Patient.fromJson(e)).toList();
      return [];
    } catch (e) { return []; }
  }

  Future<List<Medicine>> getMedicines() async {
    try {
      var res = await _dio.get('/hisapi.asmx/getMedicineList', 
        queryParameters: {'user': currentUser, 'facility': currentFacility});
      if (res.statusCode == 200) return (res.data as List).map((e) => Medicine.fromJson(e)).toList();
      return [];
    } catch (e) { return []; }
  }

  Future<List<XRay>> getXRays() async {
    try {
      var res = await _dio.get('/hisapi.asmx/getXRayList');
      if (res.statusCode == 200) return (res.data as List).map((e) => XRay.fromJson(e)).toList();
      return [];
    } catch (e) { return []; }
  }

  Future<List<LabTest>> getLabs() async {
    try {
      var res = await _dio.get('/hisapi.asmx/getLaboratoryList', 
        queryParameters: {'user': currentUser, 'facility': currentFacility, 'search': ''});
      if (res.statusCode == 200) 
        return (res.data as List).map((e) => LabTest.fromJson(e)).where((t) => !t.isGroup).toList();
      return [];
    } catch (e) { return []; }
  }

  Future<List<Diagnosis>> getDiagnosis() async {
    try {
      var res = await _dio.get('/hisapi.asmx/getDiagnosisList');
      if (res.statusCode == 200) return (res.data as List).map((e) => Diagnosis.fromJson(e)).toList();
      return [];
    } catch (e) { return []; }
  }

  Future<List<NursingService>> getNursing() async {
    try {
      var res = await _dio.get('/hisapi.asmx/getServiceList');
      if (res.statusCode == 200) 
        return (res.data as List).map((e) => NursingService.fromJson(e)).toList();
      return [];
    } catch (e) { return []; }
  }

  Future<List<AdmissionDest>> getAdmissions() async {
    try {
      var res = await _dio.get('/hisapi.asmx/getAdmDestList', 
        queryParameters: {'facility': currentFacility});
      if (res.statusCode == 200) 
        return (res.data as List).map((e) => AdmissionDest.fromJson(e)).toList();
      return [];
    } catch (e) { return []; }
  }

  // --- SAVE & EXECUTE ---
  Future<void> executeCmd(String query) async {
    try { 
      await _dio.get('/hisapi.asmx/execCmd', queryParameters: {'cmd': query}); 
    } catch (e) {}
  }

  Future<bool> saveFullVisit({
    required String visitId, 
    required String profileId, 
    required String doctorName,
    List<NursingService> nursing = const [], 
    List<Medicine> medicines = const [],
    List<LabTest> labs = const [], 
    List<XRay> xrays = const [],
    String diagnosisCode = "", 
    String admissionDestName = "",
  }) async {
    
    String nursStr = "";
    for (var i in nursing) {
      nursStr += "0;$visitId;${i.name};auto;1;${i.resultValue};|";
    }
    
    String medStr = "";
    for (var i in medicines) {
      medStr += "0;$visitId;orginal;${i.name};${i.unit};${i.dosage};0;;;|";
    }
    
    String labStr = "";
    for (var i in labs) {
      labStr += "0;$visitId;${i.name};;;|";
    }
    
    String xrayStr = "";
    for (var i in xrays) {
      xrayStr += "0;$visitId;${i.name};;;|";
    }
    
    String diagStr = diagnosisCode.isNotEmpty ? "0;$visitId;$diagnosisCode;|" : "";
    
    String admStr = "";
    if (admissionDestName.isNotEmpty) {
      String dt = DateTime.now().toString().substring(0, 16);
      admStr = "0;$visitId;يس;$admissionDestName;$dt; $diagnosisCode;بارد;$doctorName; ;0;1900-1-1;;0;;1900-1-1;0;|";
    }

    int cNu = nursing.length; 
    int cPh = medicines.length; 
    int cLa = labs.length; 
    int cXr = xrays.length;
    String countStr = "$cPh;$cNu;$cLa;$cXr;|";

    List<Map<String, dynamic>> payload = [{
      "vid": visitId, 
      "pid": profileId, 
      "visit": "$visitId;$doctorName;لا يوجد ممرض / ة;;;;;", 
      "history": "$profileId;;;;;;", 
      "chronicDisease": "", 
      "diagnosis": diagStr,
      "nursing": nursStr, 
      "medicine": medStr, 
      "lab": labStr, 
      "xray": xrayStr,
      "admission": admStr, 
      "surgRequest": "", 
      "discharge": "", 
      "refferal": "", 
      "death": "", 
      "actions": "", 
      "consultation": "", 
      "surgery": "", 
      "anc": "", 
      "pnc": "", 
      "fpl": "", 
      "dlv": "", 
      "dlvMulti": "", 
      "counters": countStr
    }];

    try {
      var res = await _dio.get('/hisapi.asmx/saveVisit', 
        queryParameters: {'json': jsonEncode(payload)});
      if (res.statusCode == 200) {
        String sql = "UPDATE [101_VisitRecords] SET QueueStatus = 1, CountLa = $cLa, CountXr = $cXr, CountPh = $cPh, CountNu = $cNu WHERE VisitID = '$visitId' UPDATE [114RefreshQueue] SET RefreshQueue = 1 WHERE Facility = '$currentFacility'";
        await executeCmd(sql);
        showNotif("تم إرسال الطلبات للمريض بنجاح");
        return true;
      }
      return false;
    } catch (e) { return false; }
  }
}
