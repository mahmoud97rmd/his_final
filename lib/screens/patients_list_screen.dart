import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/clinic_model.dart';
import '../models/patient_model.dart';
import 'patient_detail_screen.dart';
import 'login_screen.dart';

class PatientsListScreen extends StatefulWidget {
  final List<Clinic> clinics;
  const PatientsListScreen({super.key, required this.clinics});
  @override
  _PatientsListScreenState createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  Clinic? _selClinic;
  List<Patient> _allPatients = [];
  List<Patient> _waitingPatients = [];
  List<Patient> _processedPatients = [];
  bool _loading = false;
  bool _showProcessed = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.clinics.isNotEmpty) {
      _selClinic = widget.clinics.first;
      _loadPatients();
      
      // تحديث تلقائي كل 30 ثانية
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _loadPatients(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadPatients({bool silent = false}) async {
    if (_selClinic == null) return;
    if (!silent) setState(() => _loading = true);
    
    _allPatients = await ApiService().getQueue(
      ApiService.currentFacility!, 
      "د. أحمد حلاق", 
      _selClinic!.name
    );
    
    // فصل المرضى حسب الحالة
    _waitingPatients = _allPatients.where((p) => !p.isProcessed).toList();
    _processedPatients = _allPatients.where((p) => p.isProcessed).toList();
    
    // للجناح والعناية: إظهار الجميع في قائمة واحدة
    if (ApiService.userType == 'ward') {
      _waitingPatients = _allPatients;
      _processedPatients = [];
    }
    
    if (!silent) setState(() => _loading = false);
    else setState(() {});
  }

  Widget _buildPatientCard(Patient patient, {bool isProcessed = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isProcessed ? Colors.green.shade100 : const Color(0xFFE3F2FD),
          child: Text(
            patient.queue.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isProcessed ? Colors.green.shade700 : const Color(0xFF1E88E5),
            ),
          ),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(patient.age),
                const SizedBox(width: 12),
                Icon(Icons.medical_services, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(child: Text(patient.doctorName, overflow: TextOverflow.ellipsis)),
              ],
            ),
            if (patient.diagnosis.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.description, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      patient.diagnosis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: isProcessed 
          ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 28)
          : Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: patient))
          );
          _loadPatients();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWard = ApiService.userType == 'ward';
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<Clinic>(
                value: _selClinic,
                dropdownColor: const Color(0xFF1565C0),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                items: widget.clinics.map((c) =>
                  DropdownMenuItem(value: c, child: Text(c.name))
                ).toList(),
                onChanged: (v) {
                  setState(() => _selClinic = v);
                  _loadPatients();
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPatients(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E88E5)),
              accountName: Text(ApiService.currentUser ?? ""),
              accountEmail: Text(ApiService.currentFacility ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF1E88E5)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("خروج"),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen())
              ),
            ),
          ],
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // إحصائيات
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'قيد الانتظار',
                      _waitingPatients.length,
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                    if (!isWard)
                      _buildStatCard(
                        'تم الدخول',
                        _processedPatients.length,
                        Icons.check_circle,
                        Colors.green,
                      ),
                    _buildStatCard(
                      'المجموع',
                      _allPatients.length,
                      Icons.people,
                      Colors.blue,
                    ),
                  ],
                ),
              ),
              
              // Tabs للتبديل بين القوائم (للعيادة والإسعاف فقط)
              if (!isWard)
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _showProcessed = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !_showProcessed ? const Color(0xFF1E88E5) : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              'قيد الانتظار (${_waitingPatients.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_showProcessed ? const Color(0xFF1E88E5) : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _showProcessed = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _showProcessed ? const Color(0xFF1E88E5) : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              'تم الدخول (${_processedPatients.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _showProcessed ? const Color(0xFF1E88E5) : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // قائمة المرضى
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadPatients(),
                  child: _buildPatientsList(),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    bool isWard = ApiService.userType == 'ward';
    List<Patient> displayList = isWard 
      ? _waitingPatients 
      : (_showProcessed ? _processedPatients : _waitingPatients);
    
    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'لا يوجد مرضى',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayList.length,
      itemBuilder: (ctx, i) => _buildPatientCard(
        displayList[i],
        isProcessed: _showProcessed,
      ),
    );
  }
}
