import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/patient_model.dart';
import '../models/medicine_model.dart';
import '../models/xray_model.dart';
import '../models/lab_test_model.dart';
import '../models/diagnosis_model.dart';
import '../models/nursing_model.dart';
import '../models/admission_dest_model.dart';

class PatientTabsScreen extends StatefulWidget {
  final Patient patient;
  const PatientTabsScreen({super.key, required this.patient});
  @override
  _PatientTabsScreenState createState() => _PatientTabsScreenState();
}

class _PatientTabsScreenState extends State<PatientTabsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ApiService _api = ApiService();
  String _search = "";
  bool _loading = true, _saving = false;

  List<NursingService> _nursing = [], _selNursing = [];
  List<Diagnosis> _diagnosis = []; 
  Diagnosis? _selDiag;
  List<LabTest> _labs = []; 
  Set<String> _selLabs = {};
  List<XRay> _xrays = []; 
  Set<String> _selXrays = {};
  List<Medicine> _meds = [], _selMeds = [];
  List<AdmissionDest> _adms = []; 
  AdmissionDest? _selAdm;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    _load();
  }

  void _load() async {
    try {
      var res = await Future.wait([
        _api.getNursing(), 
        _api.getDiagnosis(), 
        _api.getLabs(), 
        _api.getXRays(), 
        _api.getMedicines(), 
        _api.getAdmissions()
      ]);
      setState(() {
        _nursing = res[0] as List<NursingService>; 
        _diagnosis = res[1] as List<Diagnosis>;
        _labs = res[2] as List<LabTest>; 
        _xrays = res[3] as List<XRay>;
        _meds = res[4] as List<Medicine>; 
        _adms = res[5] as List<AdmissionDest>;
        _loading = false;
      });
    } catch(e) { 
      setState(() => _loading = false); 
    }
  }

  void _save() async {
    setState(() => _saving = true);
    List<LabTest> fLabs = _labs.where((e) => _selLabs.contains(e.id)).toList();
    List<XRay> fXrays = _xrays.where((e) => _selXrays.contains(e.id)).toList();
    bool ok = await _api.saveFullVisit(
      visitId: widget.patient.visitId, 
      profileId: widget.patient.profileId, 
      doctorName: ApiService.currentUser!,
      nursing: _selNursing, 
      medicines: _selMeds, 
      labs: fLabs, 
      xrays: fXrays,
      diagnosisCode: _selDiag?.code ?? "", 
      admissionDestName: _selAdm?.name ?? ""
    );
    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  void _inp(String t, Function(String) ok) {
    TextEditingController c = TextEditingController();
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: Text(t), 
        content: TextField(controller: c, autofocus: true), 
        actions: [
          ElevatedButton(
            onPressed: () {
              if(c.text.isNotEmpty) {
                ok(c.text); 
                Navigator.pop(context);
              }
            }, 
            child: const Text("تم")
          )
        ]
      )
    );
  }

  Widget _list<T>(List<T> items, Widget Function(T) b) {
    final f = items.where((i) => 
      i.toString().toLowerCase().contains(_search) || 
      (i as dynamic).name.toString().toLowerCase().contains(_search)
    ).toList();
    return ListView.builder(
      itemCount: f.length, 
      itemBuilder: (c, i) => b(f[i])
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(widget.patient.name, style: const TextStyle(fontSize: 16)), 
            Text(
              "ملف: ${widget.patient.profileId}", 
              style: const TextStyle(fontSize: 12, color: Colors.white70)
            )
          ]
        ),
        backgroundColor: const Color(0xFF1E88E5),
        bottom: TabBar(
          controller: _tabCtrl, 
          isScrollable: true, 
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "تمريض", icon: Icon(Icons.monitor_heart)), 
            Tab(text: "تشخيص", icon: Icon(Icons.person_search)), 
            Tab(text: "مخبر", icon: Icon(Icons.science)), 
            Tab(text: "أشعة", icon: Icon(Icons.wb_iridescent)), 
            Tab(text: "أدوية", icon: Icon(Icons.medication)), 
            Tab(text: "قبول", icon: Icon(Icons.bed))
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8), 
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()), 
                  decoration: const InputDecoration(
                    hintText: "بحث...", 
                    prefixIcon: Icon(Icons.search), 
                    border: OutlineInputBorder(), 
                    contentPadding: EdgeInsets.zero
                  )
                )
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl, 
                  children: [
                    // تمريض
                    _list(_nursing, (i) => CheckboxListTile(
                      title: Text(i.name), 
                      subtitle: _selNursing.contains(i) 
                        ? Text(i.resultValue, style: const TextStyle(color: Colors.green)) 
                        : null, 
                      value: _selNursing.contains(i), 
                      onChanged: (v) { 
                        if(v!) {
                          _inp(i.name, (val) {
                            i.resultValue = val; 
                            setState(() => _selNursing.add(i));
                          });
                        } else {
                          setState(() => _selNursing.remove(i)); 
                        }
                      }
                    )),
                    
                    // تشخيص
                    _list(_diagnosis, (i) => ListTile(
                      title: Text(i.arName), 
                      subtitle: Text(i.code), 
                      trailing: _selDiag == i 
                        ? const Icon(Icons.check, color: Colors.green) 
                        : null, 
                      onTap: () => setState(() => _selDiag = i)
                    )),
                    
                    // مخبر
                    _list(_labs, (i) => CheckboxListTile(
                      title: Text(i.name), 
                      value: _selLabs.contains(i.id), 
                      onChanged: (v) => setState(() => 
                        v! ? _selLabs.add(i.id) : _selLabs.remove(i.id)
                      )
                    )),
                    
                    // أشعة
                    _list(_xrays, (i) => CheckboxListTile(
                      title: Text(i.name), 
                      value: _selXrays.contains(i.id), 
                      onChanged: (v) => setState(() => 
                        v! ? _selXrays.add(i.id) : _selXrays.remove(i.id)
                      )
                    )),
                    
                    // أدوية
                    _list(_meds, (i) => ListTile(
                      title: Text(i.name), 
                      subtitle: Text(i.unit), 
                      trailing: const Icon(Icons.add_circle, color: Colors.orange), 
                      onTap: () => _inp("الجرعة: ${i.name}", (val) { 
                        setState(() { 
                          i.dosage = val; 
                          _selMeds.add(i); 
                        }); 
                      })
                    )),
                    
                    // قبول
                    ListView(
                      children: _adms.map((e) => RadioListTile(
                        title: Text(e.name), 
                        value: e, 
                        groupValue: _selAdm, 
                        onChanged: (v) => setState(() => _selAdm = v)
                      )).toList()
                    )
                  ]
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save, 
        label: _saving ? const Text("جاري...") : const Text("حفظ"), 
        icon: const Icon(Icons.save), 
        backgroundColor: const Color(0xFF1E88E5)
      ),
    );
  }
  
  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}
