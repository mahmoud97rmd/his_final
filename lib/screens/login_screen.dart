import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/clinic_model.dart';
import 'patients_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _uCtrl = TextEditingController(text: 'quds-doc18');
  final _fCtrl = TextEditingController(text: 'مشفى القدس');
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    ApiService.currentUser = _uCtrl.text;
    ApiService.currentFacility = _fCtrl.text;
    var clinics = await ApiService().getClinics(_uCtrl.text);
    setState(() => _loading = false);
    
    if (clinics.isNotEmpty && mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => PatientsListScreen(clinics: clinics))
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الدخول: تأكد من المستخدم أو الإنترنت'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_hospital_rounded, size: 80, color: Color(0xFF1E88E5)),
              const SizedBox(height: 20),
              const Text(
                "HIS System", 
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1E88E5)
                )
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _uCtrl, 
                decoration: const InputDecoration(
                  labelText: "المستخدم", 
                  prefixIcon: Icon(Icons.person), 
                  border: OutlineInputBorder()
                )
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _fCtrl, 
                decoration: const InputDecoration(
                  labelText: "المنشأة", 
                  prefixIcon: Icon(Icons.business), 
                  border: OutlineInputBorder()
                )
              ),
              const SizedBox(height: 30),
              _loading 
                ? const CircularProgressIndicator() 
                : SizedBox(
                    width: double.infinity, 
                    height: 50, 
                    child: ElevatedButton(
                      onPressed: _login, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5)
                      ), 
                      child: const Text(
                        "دخول", 
                        style: TextStyle(fontSize: 18, color: Colors.white)
                      )
                    )
                  )
            ],
          ),
        ),
      ),
    );
  }
}
