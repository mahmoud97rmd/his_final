import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../services/api_service.dart';

class PatientSingleScreen extends StatefulWidget {
  final Patient patient;
  const PatientSingleScreen({super.key, required this.patient});
  @override
  State<PatientSingleScreen> createState() => _PatientSingleScreenState();
}

class _PatientSingleScreenState extends State<PatientSingleScreen> {
  List<Visit> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  void _loadVisits() async {
    setState(() => _loading = true);
    _visits = await ApiService().getPatientVisits(widget.patient.profileId);
    setState(() => _loading = false);
  }

  Widget card(String title, Widget child, {Color? color}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        color: color ?? Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Divider(),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Visit? lastVisit = _visits.isNotEmpty ? _visits.last : null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1E88E5),
        title: Text(widget.patient.name),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadVisits),
        ],
      ),
      body: _loading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // بطاقة معلومات أساسية
                card('بيانات المريض',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الاسم: ${widget.patient.name}'),
                      Text('العمر: ${widget.patient.age}'),
                      Text('الملف: ${widget.patient.profileId}'),
                      Text('الطبيب: ${widget.patient.doctorName}'),
                    ],
                  ),
                ),
                // بطاقة الأمراض السابقة
                card('الأمراض السابقة',
                  Text(lastVisit?.diagnosis ?? 'لا توجد بيانات'),
                ),
                // بطاقة الشكوى والفحص
                card('الشكوى والفحص',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الشكوى: ${lastVisit?.complaint ?? ""}'),
                      Text('الفحص: ${lastVisit?.exam ?? ""}'),
                    ],
                  ),
                ),
                // بطاقة التشخيص
                card('التشخيص',
                  lastVisit?.diagnosis != null && lastVisit!.diagnosis.isNotEmpty
                    ? Text(lastVisit.diagnosis)
                    : Text('لا يوجد تشخيص'),
                ),
                // بطاقة الأدوية
                card('الأدوية',
                  lastVisit?.medications != null && lastVisit!.medications.isNotEmpty
                    ? Text(lastVisit.medications)
                    : Text('لا توجد أدوية'),
                ),
                // بطاقة التحاليل
                card('التحاليل',
                  lastVisit?.labs != null && lastVisit!.labs.isNotEmpty
                    ? Text(lastVisit.labs)
                    : Text('لا توجد تحاليل'),
                ),
                // بطاقة الصور الشعاعية
                card('الصور الشعاعية',
                  lastVisit?.xrays != null && lastVisit!.xrays.isNotEmpty
                    ? Text(lastVisit.xrays)
                    : Text('لا توجد صور شعاعية'),
                ),
                // بطاقة الاستشارات
                card('الاستشارات',
                  lastVisit?.consultation != null && lastVisit!.consultation.isNotEmpty
                    ? Text(lastVisit.consultation)
                    : Text('لا توجد استشارات'),
                ),
                // بطاقة الإحالة
                card('الإحالة',
                  lastVisit?.referral != null && lastVisit!.referral.isNotEmpty
                    ? Text(lastVisit.referral)
                    : Text('لا توجد إحالات'),
                ),
                // بطاقة الوفاة
                card('الوفاة',
                  lastVisit?.death != null && lastVisit!.death.isNotEmpty
                    ? Text(lastVisit.death)
                    : Text('لا توجد بيانات وفاة'),
                ),
                // بطاقة القبول
                card('القبول',
                  lastVisit?.admission != null && lastVisit!.admission.isNotEmpty
                    ? Text(lastVisit.admission)
                    : Text('لا يوجد قبول'),
                ),
                const SizedBox(height: 10),
                // أزرار إضافة جديد لكل خانة
                card('إضافة إجراء جديد',
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('إضافة تشخيص'),
                        onPressed: () {/* شيفرة إضافة تشخيص */}),
                      ElevatedButton.icon(
                        icon: Icon(Icons.medical_services),
                        label: Text('إضافة دواء'),
                        onPressed: () {/* شيفرة إضافة دواء */}),
                      ElevatedButton.icon(
                        icon: Icon(Icons.science),
                        label: Text('إضافة تحليل'),
                        onPressed: () {/* شيفرة إضافة تحليل */}),
                      ElevatedButton.icon(
                        icon: Icon(Icons.image),
                        label: Text('إضافة صورة شعاعية'),
                        onPressed: () {/* شيفرة إضافة صورة شعاعية */}),
                      ElevatedButton.icon(
                        icon: Icon(Icons.share),
                        label: Text('إضافة استشارة'),
                        onPressed: () {/* شيفرة إضافة استشارة */}),
                      ElevatedButton.icon(
                        icon: Icon(Icons.transfer_within_a_station),
                        label: Text('إضافة إحالة'),
                        onPressed: () {/* شيفرة إضافة إحالة */}),
                      ElevatedButton.icon(
                        icon: Icon(Icons.exit_to_app),
                        label: Text('إضافة قبول'),
                        onPressed: () {/* شيفرة إضافة قبول */}),
                      ElevatedButton.icon(
                        icon: Icon(Icons.mood_bad),
                        label: Text('إضافة وفاة'),
                        onPressed: () {/* شيفرة إضافة وفاة */}),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
