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
    setState(() => _loading = true);
    
    // تحميل البيانات دفعة واحدة من الـ Cache
    try {
      var data = await _api.loadAllData();
      
      setState(() {
        _nursing = data['nursing'] ?? [];
        _diagnosis = data['diagnosis'] ?? [];
        _labs = data['labs'] ?? [];
        _xrays = data['xrays'] ?? [];
        _meds = data['medicines'] ?? [];
        _adms = data['admissions'] ?? [];
        _loading = false;
      });
    } catch(e) { 
      setState(() => _loading = false); 
    }
  }

  void _save() async {
    if (_selNursing.isEmpty && _selMeds.isEmpty && _selLabs.isEmpty && 
        _selXrays.isEmpty && _selDiag == null && _selAdm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة بيانات قبل الحفظ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
    
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحفظ بنجاح ✓'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل الحفظ، يرجى المحاولة مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _inp(String t, Function(String) ok) {
    TextEditingController c = TextEditingController();
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: Text(t), 
        content: TextField(
          controller: c, 
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'أدخل القيمة',
          ),
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if(c.text.isNotEmpty) {
                ok(c.text); 
                Navigator.pop(context);
              }
            }, 
            child: const Text("تم")
          ),
        ],
      ),
    );
  }

  Widget _list<T>(List<T> items, Widget Function(T) b) {
    final f = items.where((i) => 
      i.toString().toLowerCase().contains(_search) || 
      (i as dynamic).name.toString().toLowerCase().contains(_search)
    ).toList();
    
    if (f.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    
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
            Tab(text: "تمريض", icon: Icon(Icons.monitor_heart, size: 20)), 
            Tab(text: "تشخيص", icon: Icon(Icons.person_search, size: 20)), 
            Tab(text: "مخبر", icon: Icon(Icons.science, size: 20)), 
            Tab(text: "أشعة", icon: Icon(Icons.wb_iridescent, size: 20)), 
            Tab(text: "أدوية", icon: Icon(Icons.medication, size: 20)), 
            Tab(text: "قبول", icon: Icon(Icons.bed, size: 20))
          ],
        ),
      ),
      body: _loading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري التحميل...'),
              ],
            ),
          )
        : Column(
            children: [
              // شريط البحث
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()), 
                  decoration: InputDecoration(
                    hintText: "بحث...", 
                    prefixIcon: const Icon(Icons.search), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              
              // المحتوى
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl, 
                  children: [
                    // تمريض
                    _list(_nursing, (i) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: CheckboxListTile(
                        title: Text(i.name), 
                        subtitle: _selNursing.contains(i) 
                          ? Text(
                              i.resultValue, 
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                            ) 
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
                      ),
                    )),
                    
                    // تشخيص
                    _list(_diagnosis, (i) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(i.arName), 
                        subtitle: Text(i.code, style: TextStyle(color: Colors.grey.shade600)), 
                        trailing: _selDiag == i 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 28) 
                          : null, 
                        onTap: () => setState(() => _selDiag = i)
                      ),
                    )),
                    
                    // مخبر
                    _list(_labs, (i) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: CheckboxListTile(
                        title: Text(i.name), 
                        value: _selLabs.contains(i.id), 
                        onChanged: (v) => setState(() => 
                          v! ? _selLabs.add(i.id) : _selLabs.remove(i.id)
                        )
                      ),
                    )),
                    
                    // أشعة
                    _list(_xrays, (i) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: CheckboxListTile(
                        title: Text(i.name), 
                        value: _selXrays.contains(i.id), 
                        onChanged: (v) => setState(() => 
                          v! ? _selXrays.add(i.id) : _selXrays.remove(i.id)
                        )
                      ),
                    )),
                    
                    // أدوية
                    _list(_meds, (i) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(i.name), 
                        subtitle: Text(i.unit), 
                        trailing: _selMeds.contains(i)
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.add_circle, color: Colors.orange), 
                        onTap: () {
                          if (_selMeds.contains(i)) {
                            setState(() => _selMeds.remove(i));
                          } else {
                            _inp("الجرعة: ${i.name}", (val) { 
                              setState(() { 
                                i.dosage = val; 
                                _selMeds.add(i); 
                              }); 
                            });
                          }
                        }
                      ),
                    )),
                    
                    // قبول
                    ListView(
                      children: _adms.map((e) => Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: RadioListTile(
                          title: Text(e.name), 
                          value: e, 
                          groupValue: _selAdm, 
                          onChanged: (v) => setState(() => _selAdm = v)
                        ),
                      )).toList()
                    )
                  ]
                ),
              ),
            ],
          ),
      floatingActionButton: _loading ? null : FloatingActionButton.extended(
        onPressed: _saving ? null : _save, 
        label: _saving 
          ? const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text("جاري الحفظ..."),
              ],
            )
          : const Text("حفظ"), 
        icon: _saving ? null : const Icon(Icons.save), 
        backgroundColor: _saving ? Colors.grey : Colors.green.shade600,
      ),
    );
  }
  
  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}
