import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/clinic_model.dart';
import '../models/patient_model.dart';
import 'patient_tabs_screen.dart';
import 'login_screen.dart';

class PatientsListScreen extends StatefulWidget {
  final List<Clinic> clinics;
  const PatientsListScreen({super.key, required this.clinics});
  @override
  _PatientsListScreenState createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  Clinic? _selClinic;
  List<Patient> _patients = [], _filtered = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.clinics.isNotEmpty) {
      _selClinic = widget.clinics.first;
      _loadPatients();
    }
  }

  void _loadPatients() async {
    if (_selClinic == null) return;
    setState(() => _loading = true);
    _patients = await ApiService().getQueue(
      ApiService.currentFacility!, 
      "د. أحمد حلاق", 
      _selClinic!.name
    );
    _filtered = _patients;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<Clinic>(
            value: _selClinic, 
            dropdownColor: const Color(0xFF1565C0),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPatients)
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E88E5)), 
              accountName: Text(ApiService.currentUser ?? ""), 
              accountEmail: Text(ApiService.currentFacility ?? "")
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red), 
              title: const Text("خروج"), 
              onTap: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen())
              )
            ),
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            padding: const EdgeInsets.all(10), 
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final p = _filtered[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25, 
                    backgroundColor: const Color(0xFFE3F2FD), 
                    child: Text(
                      p.queue.toString(), 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18, 
                        color: Color(0xFF1E88E5)
                      )
                    )
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${p.age} - ${p.doctorName}"),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => PatientTabsScreen(patient: p))
                  ),
                ),
              );
            },
          ),
    );
  }
}
