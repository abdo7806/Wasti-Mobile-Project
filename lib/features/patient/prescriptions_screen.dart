import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "../../models/Medication_model.dart";
import "../../models/Prescription_model.dart";

import './widgets/prescription_details_dialog.dart';
import './widgets/DrawerPage.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  List<Prescription> _prescriptions = [];
  List<Prescription> _filteredPrescriptions = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _statusFilter = 'all';
  String _dateFilter = 'newest';
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
          final userDataJson = html.window.localStorage['userData'];
      if (userDataJson == null) throw Exception('يجب تسجيل الدخول أولاً');
      
      setState(() {
        userData = jsonDecode(userDataJson);
      });

    await Future.delayed(const Duration(milliseconds: 300));
    await fetchPrescriptions();
  }

  Map<String, dynamic>? getPatientData() {
    try {
      final patientData = html.window.localStorage['patientData'];
      if (patientData == null || patientData.isEmpty) {
        debugPrint('No patientData found in localStorage');
        return null;
      }
      return jsonDecode(patientData);
    } catch (e) {
      debugPrint('Error parsing patientData: $e');
      return null;
    }
  }

  Future<void> fetchPrescriptions() async {
    setState(() => _isLoading = true);

    try {
      final patientData = getPatientData();
      if (patientData == null || patientData['id'] == null) {
        throw Exception('بيانات المريض غير صالحة أو مفقودة');
      }

      final patientId = patientData['id'];
      final url = Uri.parse('https://localhost:7219/api/Prescription/GetByPatientId/$patientId');
      final token = html.window.localStorage['token'];

      if (token == null || token.isEmpty) {
        throw Exception('رمز الوصول غير صالح');
      }

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        _prescriptions = responseData.map((json) => Prescription.fromJson(json)).toList();
        applyFilters();
      } else if (response.statusCode == 404) {
        _prescriptions = [];
        applyFilters();
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب البيانات: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void applyFilters() {
    List<Prescription> filtered = _prescriptions.where((p) {
      final matchesSearch = p.id.toString().contains(_searchTerm) ||
          p.doctor.user.fullName.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'dispensed' && p.isDispensed) ||
          (_statusFilter == 'not-dispensed' && !p.isDispensed);

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) => _dateFilter == 'newest' 
        ? b.issuedDate.compareTo(a.issuedDate) 
        : a.issuedDate.compareTo(b.issuedDate));

    setState(() => _filteredPrescriptions = filtered);
  }

  Future<Medication> fetchMedication(int medicationId) async {
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

  void _showPrescriptionDetails(BuildContext context, Prescription prescription) {
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
    return Directionality(
      
      textDirection: TextDirection.rtl,
      child: Scaffold(

        drawer: CustomDrawer(
          fullName: userData?['fullName'] ?? 'مجهول',
          email: userData?['email'] ?? 'غير متوفر',
        ),
        appBar: AppBar(
          title: const Text('الوصفات الطبية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchPrescriptions,
              tooltip: 'تحديث البيانات',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                html.window.localStorage.clear();
                Navigator.pushReplacementNamed(context, '/login');
              },
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildFilterBar(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPrescriptionsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Column(
      children: [
        TextField(
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            suffixIcon: Icon(Icons.search),
            labelText: 'ابحث برقم الوصفة أو اسم الطبيب',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onChanged: (val) {
            _searchTerm = val;
            applyFilters();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'حالة الصرف',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'dispensed', child: Text('تم الصرف')),
                  DropdownMenuItem(value: 'not-dispensed', child: Text('لم يصرف')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _statusFilter = val;
                    applyFilters();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _dateFilter,
                decoration: const InputDecoration(
                  labelText: 'ترتيب حسب التاريخ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('الأحدث أولاً')),
                  DropdownMenuItem(value: 'oldest', child: Text('الأقدم أولاً')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _dateFilter = val;
                    applyFilters();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrescriptionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد وصفات طبية مسجلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('لم يتم العثور على أي وصفات طبية لهذا المريض'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchPrescriptions,
              child: const Text('إعادة تحميل البيانات'),
            ),
          ],
        ),
      );
    }

    if (_filteredPrescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد نتائج مطابقة للبحث',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('حاول تغيير كلمات البحث أو إعادة تعيين الفلاتر'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchTerm = '';
                  _statusFilter = 'all';
                  applyFilters();
                });
              },
              child: const Text('إعادة تعيين الفلاتر'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredPrescriptions.length,
      itemBuilder: (context, index) {
        final prescription = _filteredPrescriptions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: InkWell(
            onTap: () => _showPrescriptionDetails(context, prescription),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: prescription.isDispensed ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      prescription.isDispensed ? 'تم الصرف' : 'لم يصرف',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوصفة رقم #${prescription.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('الطبيب: ${prescription.doctor.user.fullName}'),
                        const SizedBox(height: 4),
                        Text('التاريخ: ${prescription.issuedDate.toLocal().toString().split(' ')[0]}'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}