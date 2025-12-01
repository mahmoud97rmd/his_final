import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/clinic_model.dart';
import 'patients_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedType;
  bool _loading = false;

  final Map<String, Map<String, String>> _credentials = {
    'emergency': {'user': 'quds-doc18', 'facility': 'مشفى القدس', 'label': 'إسعاف عام'},
    'clinic': {'user': 'quds-doc18', 'facility': 'مشفى القدس', 'label': 'عيادة عامة'},
    'ward': {'user': 'quds-admi22', 'facility': 'مشفى القدس', 'label': 'جناح / عناية مشددة'},
  };

  void _login(String type) async {
    setState(() => _loading = true);
    
    ApiService.currentUser = _credentials[type]!['user'];
    ApiService.currentFacility = _credentials[type]!['facility'];
    ApiService.userType = type;
    
    // حفظ نوع المستخدم
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userType', type);
    
    var clinics = await ApiService().getClinics(ApiService.currentUser!);
    setState(() => _loading = false);
    
    if (clinics.isNotEmpty && mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => PatientsListScreen(clinics: clinics))
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل الدخول: تأكد من الاتصال بالإنترنت'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Widget _buildLoginCard(String type) {
    final info = _credentials[type]!;
    IconData icon;
    Color color;
    
    switch(type) {
      case 'emergency':
        icon = Icons.local_hospital;
        color = Colors.red.shade600;
        break;
      case 'clinic':
        icon = Icons.medical_services;
        color = Colors.blue.shade600;
        break;
      case 'ward':
        icon = Icons.bed;
        color = Colors.green.shade600;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: _loading ? null : () => _login(type),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                info['label']!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded, 
                    size: 80, 
                    color: Color(0xFF1E88E5)
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "نظام المعلومات الصحية",
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1E88E5)
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "مشفى القدس",
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.grey.shade600
                  ),
                ),
                const SizedBox(height: 48),
                
                // بطاقات الدخول
                if (_loading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تسجيل الدخول...'),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildLoginCard('emergency'),
                      const SizedBox(height: 16),
                      _buildLoginCard('clinic'),
                      const SizedBox(height: 16),
                      _buildLoginCard('ward'),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
