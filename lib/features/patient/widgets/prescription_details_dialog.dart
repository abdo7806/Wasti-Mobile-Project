import 'package:flutter/material.dart';
import "../../../models/Medication_model.dart";
import "../../../models/Prescription_model.dart";
import "../../../models/PrescriptionItem_model.dart";
import "../../../models/Doctor_model.dart";
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter/services.dart' show rootBundle;

class PrescriptionDetailsDialog extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailsDialog({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon
              Row(
                children: [
                  Icon(Icons.medical_services, 
                      color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'تفاصيل الوصفة #${prescription.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Doctor Section
              _buildSectionHeader('معلومات الطبيب'),
              _buildDetailItem(Icons.person, 'الطبيب', prescription.doctor.user.fullName),
              _buildDetailItem(Icons.work, 'التخصص', prescription.doctor.specialization),
              _buildDetailItem(Icons.verified, 'رقم الرخصة', prescription.doctor.licenseNumber),
              
              const SizedBox(height: 16),
              
              // Medical Center Section
              _buildSectionHeader('معلومات المركز الطبي'),
              _buildDetailItem(Icons.local_hospital, 'المركز الطبي', 
                  prescription.doctor.medicalCenter.name),
              _buildDetailItem(Icons.location_on, 'العنوان', 
                  prescription.doctor.medicalCenter.address),
              _buildDetailItem(Icons.phone, 'الهاتف', 
                  prescription.doctor.medicalCenter.phone),
              
              const SizedBox(height: 16),
              
              // Prescription Info
              _buildSectionHeader('معلومات الوصفة'),
              _buildDetailItem(Icons.calendar_today, 'تاريخ الإصدار', 
                  prescription.issuedDate.toLocal().toString().split(' ')[0]),
              _buildStatusItem(prescription.isDispensed),
              
              const SizedBox(height: 16),
              
              // Medications Header
              _buildSectionHeader('الأدوية الموصوفة'),
              const SizedBox(height: 8),
              
              // Medications List
              ...prescription.prescriptionItems.map((item) => FutureBuilder<Medication>(
                
                future: fetchMedication(item.medicationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  html.window.console.log('Medication : ${ item.CustomMedicationName}');
                  final medication = snapshot.data ?? Medication(name: item.CustomMedicationName ?? 'غير متوفر');
                  return _buildMedicationItem(item, medication);
                },
              )),
              
              const SizedBox(height: 20),
              
              // Close Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
                ),
                
              ),
          SizedBox(height: 10),
                   Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed:() => printPrescription(),
                  
                  child: const Text('طباعة', style: TextStyle(color: Colors.white)),
                ),
                
              ),
           
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text('$label: ', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, 
                style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(bool isDispensed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(isDispensed ? Icons.check_circle : Icons.error,
              color: isDispensed ? Colors.green : Colors.orange),
          const SizedBox(width: 10),
          const Text('حالة الصرف: ', 
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(isDispensed ? 'تم الصرف' : 'لم يصرف',
              style: TextStyle(
                  color: isDispensed ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(PrescriptionItem item, Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.red[400]),
                const SizedBox(width: 8),
                Text(item.medicationId > 0 ? medication.name : item.CustomMedicationName  ?? 'غير متوفر',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(item.medicationId > 0 ? '' : ' (دواء مخصص)',
                    style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            _buildMedicationDetail('الجرعة', item.dosage),
            _buildMedicationDetail('التكرار', '${item.frequency} مرات يومياً'),
            _buildMedicationDetail('المدة', '${item.duration} يوم'),
            
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<Medication> fetchMedication(int medicationId) async {
    html.window.console.log('Fetching medication with ID: $medicationId');
    if(medicationId <= 0) {
      return Medication(name: 'غير متوفر - ID غير صالح');
    }
    try {
      final url = Uri.parse('https://localhost:7219/api/Medication/$medicationId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${html.window.localStorage['token']}'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return Medication.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('فشل في جلب بيانات الدواء');
      }
    } catch (e) {
      debugPrint('Error fetching medication: $e');
      return Medication(name: 'غير متوفر - خطأ في التحميل');
    }
  }


// دالة للطباعة أو الحفظ
Future<void> printPrescription() async {
  try {
    // 1. إنشاء ملف PDF
    final pdf = await generatePrescriptionPDF();
    
    final bytes = await pdf.save();
    
    // 2. إنشاء Blob من البيانات
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // 3. إنشاء عنصر <a> لتحميل الملف
    final anchor = html.AnchorElement(href: url)
      ..download = 'وصفة_طبية_${DateTime.now().toIso8601String()}.pdf'
      ..target = '_blank';
    
    // 4. إضافة العنصر إلى DOM والنقر عليه برمجياً
    html.document.body?.children.add(anchor);
    anchor.click();
    
    // 5. تنظيف الموارد بعد التنزيل
    Future.delayed(const Duration(seconds: 1), () {
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    });
    
  } catch (e) {
   /* if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: ${e.toString()}')),
      );*/
    }
  }










Future<pw.Document> generatePrescriptionPDF() async {
  final arabicFont = await loadLocalArabicFont();
  final pdf = pw.Document();
  final patientJson = html.window.localStorage['patientData'];
  
  if (patientJson == null) throw Exception('يجب تسجيل الدخول أولاً');
  
  final patientData = jsonDecode(patientJson);

  // جلب بيانات الأدوية مسبقاً
  final medications = await Future.wait(
    prescription.prescriptionItems.map((item) => fetchMedication(item.medicationId))
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginTop: 1.5 * PdfPageFormat.cm,
        marginBottom: 1.5 * PdfPageFormat.cm,
      ),
      theme: pw.ThemeData.withFont(base: arabicFont),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(arabicFont),
              _buildPatientSection(patientData, arabicFont),
              _buildDoctorSection(prescription.doctor, arabicFont),
              _buildPrescriptionDetails(prescription, arabicFont),
              _buildMedicationsList(prescription.prescriptionItems, medications, arabicFont),
              _buildFooter(arabicFont),
            ],
          ),
        );
      },
    ),
  );

  return pdf;
}
// ============= Helper Methods =============

pw.Widget _buildHeader(pw.Font arabicFont) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('الوصفة الطبية',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            )),
          pw.Text('تاريخ الطباعة: ${DateTime.now()}',
            style: pw.TextStyle(font: arabicFont)),
        ],
      ),
      pw.Divider(thickness: 1.5),
      pw.SizedBox(height: 20),
    ],
  );
}

pw.Widget _buildPatientSection(Map<String, dynamic> patientData, pw.Font arabicFont) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.5),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    padding: const pw.EdgeInsets.all(10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('معلومات المريض',
          style: pw.TextStyle(
            font: arabicFont,
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
          )),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _buildInfoItem('الاسم:', patientData['user']?['fullName'] ?? 'غير معروف', arabicFont),
            pw.SizedBox(width: 30),
            _buildInfoItem('رقم الهوية:', patientData['nationalId'] ?? 'غير معروف', arabicFont),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            _buildInfoItem('العمر:', _calculateAge(patientData['dateOfBirth']), arabicFont),
            pw.SizedBox(width: 30),
            _buildInfoItem('الجنس:', patientData['gender'] == 'Male' ? 'ذكر' : 'أنثى', arabicFont),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildDoctorSection(Doctor doctor, pw.Font arabicFont) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 15),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.5),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    padding: const pw.EdgeInsets.all(10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('معلومات الطبيب',
          style: pw.TextStyle(
            font: arabicFont,
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
          )),
        pw.SizedBox(height: 8),
        _buildInfoItem('الاسم:', doctor.user.fullName, arabicFont),
        _buildInfoItem('التخصص:', doctor.specialization, arabicFont),
        _buildInfoItem('رقم الرخصة:', doctor.licenseNumber, arabicFont),
        _buildInfoItem('المركز الطبي:', doctor.medicalCenter.name, arabicFont),
        _buildInfoItem('هاتف المركز:', doctor.medicalCenter.phone, arabicFont),
      ],
    ),
  );
}


pw.Widget _buildPrescriptionDetails(Prescription prescription, pw.Font arabicFont) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 15),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.5),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    padding: const pw.EdgeInsets.all(10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('معلومات الوصفة',
          style: pw.TextStyle(
            font: arabicFont,
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
          )),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _buildInfoItem('رقم الوصفة:', '#${prescription.id}', arabicFont),
            pw.SizedBox(width: 30),
            _buildInfoItem('تاريخ الإصدار:', 
              prescription.issuedDate.toString(), arabicFont),
          ],
        ),
        pw.SizedBox(height: 5),
        _buildInfoItem('حالة الصرف:', 
          prescription.isDispensed ? 'تم الصرف' : 'لم يتم الصرف', arabicFont,
          color: prescription.isDispensed ? PdfColors.green : PdfColors.orange),
      ],
    ),
  );
}
pw.Widget _buildMedicationsList(
  List<PrescriptionItem> items, 
  List<Medication> medications,
  pw.Font arabicFont
) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 20),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('الأدوية الموصوفة',
          style: pw.TextStyle(
            font: arabicFont,
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
          )),
        pw.SizedBox(height: 10),
        
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blueGrey),
              children: [
                'الدواء', 'الجرعة', 'التكرار', 'المدة'
              ].map((text) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(text,
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  )),
              )).toList(),
            ),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final medication = index < medications.length ? medications[index] : null;
              
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      item.medicationId > 0 
                        ? (medication?.name ?? 'غير متوفر') 
                        : item.CustomMedicationName ?? 'دواء مخصص',
                      style: pw.TextStyle(font: arabicFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(item.dosage,
                      style: pw.TextStyle(font: arabicFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${item.frequency} مرات/يوم',
                      style: pw.TextStyle(font: arabicFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${item.duration} يوم',
                      style: pw.TextStyle(font: arabicFont)),
                  ),
              
                ],
              );
            }).toList(),
          ],
        ),
      ],
    ),
  );
}
pw.Widget _buildFooter(pw.Font arabicFont) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 40),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.Column(
          children: [
            pw.Text('توقيع الطبيب', style: pw.TextStyle(font: arabicFont)),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 1),
                ),
              ),
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.Text('ختم العيادة', style: pw.TextStyle(font: arabicFont)),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 1),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildInfoItem(String label, String value, pw.Font arabicFont, {PdfColor? color}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label,
        style: pw.TextStyle(
          font: arabicFont,
          fontWeight: pw.FontWeight.bold,
        )),
      pw.SizedBox(width: 5),
      pw.Text(value,
        style: pw.TextStyle(
          font: arabicFont,
          color: color,
        )),
    ],
  );
}

String _calculateAge(String? dateOfBirth) {
  if (dateOfBirth == null) return 'غير معروف';
  try {
    final dob = DateTime.parse(dateOfBirth);
    final now = DateTime.now();
    final age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      return '${age - 1} سنة';
    }
    return '$age سنة';
  } catch (e) {
    return 'غير معروف';
  }
}



Future<pw.Font> loadLocalArabicFont() async {
  try {
   // final fontData = await rootBundle.load('../../../../assets/fonts/Amiri-Bold.ttf');
    
    final fontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    return pw.Font.ttf(fontData);
  } catch (e) {
    debugPrint('خطأ في تحميل الخط المحلي: $e');
    return pw.Font.helvetica(); // خط احتياطي
  }
}
Future<pw.Font> _loadArabicFont() async {
  try {
    // محاولة تحميل خط محلي أولاً
    final fontData = await rootBundle.load('../../../../assets/fonts/Amiri-Bold.ttf');
    return pw.Font.ttf(fontData);
  } catch (e) {
    debugPrint('خطأ في تحميل الخط المحلي: $e');
    // إذا فشل، جلب خط من الإنترنت
    try {
      final response = await http.get(Uri.parse(
        'https://fonts.gstatic.com/s/amiri/v24/J7aRnpd8CGxBHpUrtLMA7w.ttf'));
      if (response.statusCode == 200) {
        return pw.Font.ttf(response.bodyBytes.buffer.asByteData());
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الخط من الإنترنت: $e');
    }
    // استخدام خط افتراضي إذا فشل كل شيء
    return pw.Font.helvetica();
  }
}

}
