import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/Prescription_model.dart';
import './widgets/prescription_details_dialog.dart';
import './widgets/LogoutWidget.dart';
import './widgets/DrawerPage.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter/services.dart' show rootBundle;


class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? patientData;
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userDataJson = html.window.localStorage['userData'];
      if (userDataJson == null) throw Exception('يجب تسجيل الدخول أولاً');
      
      setState(() {
        userData = jsonDecode(userDataJson);
      });

      await _getPatientByUserId();
      await _fetchDashboardData();
      
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _getPatientByUserId() async {
    final token = html.window.localStorage['token'];
    if (token == null) throw Exception('لم يتم العثور على رمز الوصول');

    final response = await http.get(
      Uri.parse('https://localhost:7219/api/PatientController/GetPatientByUserId/${userData!['userId']}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في تحميل بيانات المريض');
    }

    final data = jsonDecode(response.body);
    html.window.localStorage['patientData'] = response.body;
    
    if (mounted) {
      setState(() => patientData = data);
    }
  }

  Future<void> _fetchDashboardData() async {
    final token = html.window.localStorage['token'];
    if (token == null) throw Exception('لم يتم العثور على رمز الوصول');

    final response = await http.get(
      Uri.parse('https://localhost:7219/api/PatientController/dashboard/${patientData!['id']}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في جلب بيانات لوحة التحكم');
    }

    if (mounted) {
      setState(() => dashboardData = jsonDecode(response.body));
    }
  }

  Future<Prescription?> fetchPrescription(int prescriptionId) async {
    try {
      final url = Uri.parse('https://localhost:7219/api/Prescription/$prescriptionId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${html.window.localStorage['token']}'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return Prescription.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('فشل في جلب بيانات الوصفة الطبية');
      }
    } catch (e) {
      debugPrint('Error fetching Prescription: $e');
      return null;
    }
  }

  void _showPrescriptionDetails(BuildContext context, int prescriptionId) async {
    final prescription = await fetchPrescription(prescriptionId);
    if (prescription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في جلب تفاصيل الوصفة الطبية')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: PrescriptionDetailsDialog(prescription: prescription),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = userData?['fullName'] ?? 'مستخدم';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,

        drawer: CustomDrawer(
          fullName: fullName,
          email: userData?['email'] ?? 'البريد الإلكتروني غير متوفر',
        ),
        appBar: AppBar(
          title: const Text('لوحة تحكم المريض'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => LogoutWidget.logout(context),
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text('حدث خطأ: $errorMessage'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(



                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً بك في النظام الصحي',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'هذه لوحة التحكم الخاصة بك حيث يمكنك متابعة وصفاتك الطبية والبيانات الشخصية.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int columns = 2;
                            if (constraints.maxWidth < 325) {
                              columns = 1;
                            }
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: columns,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              children: [
                                _buildStatCard(
                                  icon: Icons.medical_services,
                                  title: 'عدد الوصفات',
                                  value: (dashboardData?['totalPrescriptions'] ?? 0).toString(),
                                  color: Colors.blue,
                                ),
                                _buildStatCard(
                                  icon: Icons.medical_information,
                                  title: 'الأدوية المصروفة',
                                  value: (dashboardData?['dispensedMeds'] ?? 0).toString(),
                                  color: Colors.green,
                                )
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'أحدث وصفة طبية',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLatestPrescriptionCard(context),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.list),
                                label: const Text('عرض جميع الوصفات'),
                                onPressed: () => Navigator.pushNamed(context, '/prescriptions'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.person),
                                label: const Text('تحديث البيانات الشخصية'),
                                onPressed: () => Navigator.pushNamed(context, '/editProfile'),
                              ),
                            ),
                          ],
                        ),


                      ],

                      
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestPrescriptionCard(BuildContext context) {
    if (dashboardData?['latestPrescription'] == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              const Text('لا توجد وصفات طبية مسجلة'),
            ],
          ),
        ),
      );
    }

    final prescription = dashboardData!['latestPrescription'];
    final isDispensed = prescription['isDispensed'] ?? false;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الوصفة #${prescription['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    isDispensed ? 'تم الصرف' : 'بانتظار الصرف',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: isDispensed ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'الطبيب: ${prescription['doctor']?['user']?['fullName'] ?? 'غير معروف'}',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'التاريخ: ${prescription['issuedDate']}',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.remove_red_eye, size: 16),
                label: const Text('عرض التفاصيل'),
                onPressed: () {
                  _showPrescriptionDetails(context, prescription['id']);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// دالة لإنشاء محتوى PDF
Future<pw.Document> generatePrescriptionPDF() async {
  final arabicFont = await loadLocalArabicFont();
  
  final pdf = pw.Document();
  final prescription = dashboardData?['latestPrescription'];
  
  if (prescription == null) {
    throw Exception('لا توجد وصفة طبية متاحة');
  }

  pdf.addPage(
    pw.Page(
      theme: pw.ThemeData.withFont(
        base: arabicFont,
        bold: arabicFont,
      ),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('الوصفة الطبية',
                    style: pw.TextStyle(
                      fontSize: 24,
                      font: arabicFont, // التأكيد على تطبيق الخط
                      fontWeight: pw.FontWeight.bold,
                    )),
                ),
                pw.SizedBox(height: 20),
                
                // معلومات المريض (تطبيق الخط على كل النصوص)
                pw.Text('معلومات المريض:',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontWeight: pw.FontWeight.bold,
                  )),
                pw.Text('الاسم: ${patientData?['user']?['fullName'] ?? 'غير معروف'}',
                  style: pw.TextStyle(font: arabicFont)),
                pw.Text('رقم الهوية: ${patientData?['nationalId'] ?? 'غير معروف'}',
                  style: pw.TextStyle(font: arabicFont)),
                pw.Divider(),
                
                // ... باقي العناصر بنفس النمط
              ],
            ),
          ),
        );
      },
    ),
  );
                  html.window.console.log('arabicFont ${arabicFont}');

  return pdf;
}
List<pw.Widget> _buildMedicationList(List<dynamic> medications, pw.Font arabicFont) {
  if (medications.isEmpty) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('لا توجد أدوية في هذه الوصفة',
          style: pw.TextStyle(
            font: arabicFont,
            fontStyle: pw.FontStyle.italic,
          )),
      )
    ];
  }

  return medications.map<pw.Widget>((med) {
    final medMap = med is Map<String, dynamic> ? med : <String, dynamic>{};
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ${medMap['medication']?['name'] ?? 'دواء غير معروف'}',
            style: pw.TextStyle(
              font: arabicFont,
              fontWeight: pw.FontWeight.bold,
            )),
          
          pw.Text('   الجرعة: ${medMap['dosage'] ?? 'غير محدد'}',
            style: pw.TextStyle(font: arabicFont)),
          
          if (medMap['instructions'] != null)
            pw.Text('   التعليمات: ${medMap['instructions']}',
              style: pw.TextStyle(font: arabicFont)),
          
          if (medMap['duration'] != null)
            pw.Text('   المدة: ${medMap['duration']}',
              style: pw.TextStyle(font: arabicFont)),
        ],
      ),
    );
  }).toList();
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: ${e.toString()}')),
      );
    }
  }
}

Future<pw.Font> loadLocalArabicFont() async {
  try {
    final fontData = await rootBundle.load('../../../assets/fonts/Amiri-Bold.ttf');
    return pw.Font.ttf(fontData);
  } catch (e) {
    debugPrint('خطأ في تحميل الخط المحلي: $e');
    return pw.Font.helvetica(); // خط احتياطي
  }
}

Future<pw.Font> loadArabicFontFromWeb() async {
  try {

    final ttfUrl = 'https://fonts.gstatic.com/s/lateef/v23/hESw6XVnNCxEvkbMpheEZo_HM.ttf';
    final response = await http.get(Uri.parse(ttfUrl));
    
    if (response.statusCode == 200) {
      // الطريقة الصحيحة لتحويل response إلى ByteData
      final bytes = response.bodyBytes;
      return pw.Font.ttf(bytes.buffer.asByteData());
    } else {
      throw Exception('فشل في تحميل الخط: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('خطأ في تحميل الخط العربي: $e');
    // خط احتياطي مع دعم عربي (إذا توفر)
    return pw.Font.helvetica(); // قد لا يدعم العربية بالكامل
  }
}

}