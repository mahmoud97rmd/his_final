import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../models/clinic_model.dart';
import '../models/medicine_model.dart';
import '../models/xray_model.dart';
import '../models/lab_test_model.dart';
import '../models/diagnosis_model.dart';
import '../models/nursing_model.dart';
import '../models/admission_dest_model.dart';
import '../models/visit_model.dart';

class ApiService {
  static const String baseUrl = 'https://hisandroidapi.azurewebsites.net';
  static String? currentFacility;
  static String? currentUser;
  static String? userType; // 'emergency', 'clinic', 'ward'
  
  // Cache للبيانات
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const cacheDuration = Duration(minutes: 5);
  
  final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl, 
    connectTimeout: const Duration(seconds: 10), 
    receiveTimeout: const Duration(seconds: 10)
  ));

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() { 
    _initNotif();
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // إضافة retry logic
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          // محاولة مرة أخرى
          try {
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  void _initNotif() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: android));
  }

  Future<void> showNotif(String body) async {
    const details = AndroidNotificationDetails(
      'his_ch', 'HIS', 
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

  // Cache Helper
  T? _getFromCache<T>(String key) {
    if (_cache.containsKey(key) && _cacheTime.containsKey(key)) {
      if (DateTime.now().difference(_cacheTime[key]!) < cacheDuration) {
        return _cache[key] as T;
      }
    }
    return null;
  }

  void _saveToCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTime[key] = DateTime.now();
  }

  // --- GET Requests مع Cache ---
  Future<List<Clinic>> getClinics(String user) async {
    String cacheKey = 'clinics_$user';
    var cached = _getFromCache<List<Clinic>>(cacheKey);
    if (cached != null) return cached;

    if (!await _checkNet()) return [];
    try {
      var res = await _dio.get('/hisapi.asmx/getClinicList', queryParameters: {'user': user});
      if (res.statusCode == 200) {
        var clinics = (res.data as List).map((e) => Clinic.fromJson(e)).toList();
        _saveToCache(cacheKey, clinics);
        return clinics;
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<Patient>> getQueue(String facility, String doc, String clinic) async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      var res = await _dio.get('/hisapi.asmx/getQueueToday', 
        queryParameters: {'facility': facility, 'doctor': doc, 'clinic': clinic, 'dt': date});
      if (res.statusCode == 200) {
        return (res.data as List).map((e) => Patient.fromJson(e)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  // جلب الزيارات السابقة للمريض
  Future<List<Visit>> getPatientVisits(String profileId) async {
    try {
      var res = await _dio.get('/hisapi.asmx/getPatientVisits', 
        queryParameters: {'profileId': profileId});
      if (res.statusCode == 200) {
        return (res.data as List).map((e) => Visit.fromJson(e)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  // تحميل كل البيانات دفعة واحدة (للتسريع)
  Future<Map<String, dynamic>> loadAllData() async {
    String cacheKey = 'all_data';
    var cached = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      var results = await Future.wait([
        getMedicines(),
        getXRays(),
        getLabs(),
        getDiagnosis(),
        getNursing(),
        getAdmissions(),
      ]);

      Map<String, dynamic> data = {
        'medicines': results[0],
        'xrays': results[1],
        'labs': results[2],
        'diagnosis': results[3],
        'nursing': results[4],
        'admissions': results[5],
      };

      _saveToCache(cacheKey, data);
      return data;
    } catch (e) {
      return {};
    }
  }

  Future<List<Medicine>> getMedicines() async {
    String cacheKey = 'medicines';
    var cached = _getFromCache<List<Medicine>>(cacheKey);
    if (cached != null) return cached;

    try {
      var res = await _dio.get('/hisapi.asmx/getMedicineList', 
        queryParameters: {'user': currentUser, 'facility': currentFacility});
      if (res.statusCode == 200) {
        var meds = (res.data as List).map((e) => Medicine.fromJson(e)).toList();
        _saveToCache(cacheKey, meds);
        return meds;
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<XRay>> getXRays() async {
    String cacheKey = 'xrays';
    var cached = _getFromCache<List<XRay>>(cacheKey);
    if (cached != null) return cached;

    try {
      var res = await _dio.get('/hisapi.asmx/getXRayList');
      if (res.statusCode == 200) {
        var xrays = (res.data as List).map((e) => XRay.fromJson(e)).toList();
        _saveToCache(cacheKey, xrays);
        return xrays;
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<LabTest>> getLabs() async {
    String cacheKey = 'labs';
    var cached = _getFromCache<List<LabTest>>(cacheKey);
    if (cached != null) return cached;

    try {
      var res = await _dio.get('/hisapi.asmx/getLaboratoryList', 
        queryParameters: {'user': currentUser, 'facility': currentFacility, 'search': ''});
      if (res.statusCode == 200) {
        var labs = (res.data as List).map((e) => LabTest.fromJson(e)).where((t) => !t.isGroup).toList();
        _saveToCache(cacheKey, labs);
        return labs;
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<Diagnosis>> getDiagnosis() async {
    String cacheKey = 'diagnosis';
    var cached = _getFromCache<List<Diagnosis>>(cacheKey);
    if (cached != null) return cached;

    try {
      var res = await _dio.get('/hisapi.asmx/getDiagnosisList');
      if (res.statusCode == 200) {
        var diag = (res.data as List).map((e) => Diagnosis.fromJson(e)).toList();
        _saveToCache(cacheKey, diag);
        return diag;
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<NursingService>> getNursing() async {
    String cacheKey = 'nursing';
    var cached = _getFromCache<List<NursingService>>(cacheKey);
    if (cached != null) return cached;

    try {
      var res = await _dio.get('/hisapi.asmx/getServiceList');
      if (res.statusCode == 200) {
        var nursing = (res.data as List).map((e) => NursingService.fromJson(e)).toList();
        _saveToCache(cacheKey, nursing);
        return nursing;
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<AdmissionDest>> getAdmissions() async {
    String cacheKey = 'admissions';
    var cached = _getFromCache<List<AdmissionDest>>(cacheKey);
    if (cached != null) return cached;

    try {
      var res = await _dio.get('/hisapi.asmx/getAdmDestList', 
        queryParameters: {'facility': currentFacility});
      if (res.statusCode == 200) {
        var adms = (res.data as List).map((e) => AdmissionDest.fromJson(e)).toList();
        _saveToCache(cacheKey, adms);
        return adms;
      }
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
        
        // مسح الـ Cache بعد الحفظ
        _cache.clear();
        _cacheTime.clear();
        
        return true;
      }
      return false;
    } catch (e) { return false; }
  }
}
