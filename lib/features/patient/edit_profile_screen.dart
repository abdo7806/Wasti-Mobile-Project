import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:convert';
import './widgets/DrawerPage.dart';

// ==================== Models ====================
class User {
  final int id;
  final String fullName;
  final String email;
  final int role;
  final String createdAt;
  final String roleName;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.roleName,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        role: json['role'],
        createdAt: json['createdAt'],
        roleName: json['roleName'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role,
        'createdAt': createdAt,
        'roleName': roleName,
      };
}

class Patient {
  final int id;
  final int userId;
  final String dateOfBirth;
  final String gender;
  final String bloodType;
  final User user;

  Patient({
    required this.id,
    required this.userId,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodType,
    required this.user,
  });

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'],
        userId: json['userId'],
        dateOfBirth: json['dateOfBirth'],
        gender: json['gender'],
        bloodType: json['bloodType'],
        user: User.fromJson(json['user']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'bloodType': bloodType,
        'user': user.toJson(),
      };
}

// ==================== EditProfileScreen ====================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  Patient? patient;
  bool isLoading = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form Keys
  final _formKeyPersonal = GlobalKey<FormState>();
  final _formKeySecurity = GlobalKey<FormState>();

  // Other fields
  DateTime? _dob;
  String? _bloodType;
  String _gender = 'M';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadPatientData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void loadPatientData() {
    final jsonString = html.window.localStorage['patientData'];
    if (jsonString == null) return;

    final jsonData = jsonDecode(jsonString);
    patient = Patient.fromJson(jsonData);

    _fullNameController.text = patient!.user.fullName;
    _emailController.text = patient!.user.email;
    _dob = DateTime.tryParse(patient!.dateOfBirth) ?? DateTime.now();
    _bloodType = patient!.bloodType.toUpperCase();
    _gender = (patient!.gender == 'F') ? 'F' : 'M';

    setState(() {});
  }

  Future<void> updatePatientData() async {
    if (!_formKeyPersonal.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = html.window.localStorage['token'];
      if (token == null) throw Exception("Token not found");

      final updatedData = {
        "dateOfBirth": DateFormat('yyyy-MM-dd').format(_dob!),
        "gender": _gender,
        "bloodType": _bloodType ?? '',
      };

      final userResponse = await _updateUserData(token);
      final patientResponse = await _updatePatientData(token, updatedData);

      if (!userResponse || !patientResponse) {
        throw Exception("Failed to update data");
      }

      _updateLocalStorage();
      _showSuccessSnackbar('تم تحديث المعلومات الشخصية بنجاح');
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _updateUserData(String token) async {
    final response = await _fetchPut(
      url: 'https://localhost:7219/api/User/${patient!.userId}',
      token: token,
      body: {
        "fullName": _fullNameController.text.trim(),
        "email": _emailController.text.trim(),
        "role": 3,
      },
    );
    return response;
  }

  Future<bool> _updatePatientData(
      String token, Map<String, dynamic> data) async {
    final response = await _fetchPut(
      url: 'https://localhost:7219/api/PatientController/${patient!.id}',
      token: token,
      body: data,
    );
    return response;
  }

  void _updateLocalStorage() {
    patient = Patient(
      id: patient!.id,
      userId: patient!.userId,
      dateOfBirth: DateFormat('yyyy-MM-dd').format(_dob!),
      gender: _gender,
      bloodType: _bloodType ?? '',
      user: User(
        id: patient!.user.id,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        role: 3,
        createdAt: patient!.user.createdAt,
        roleName: patient!.user.roleName,
      ),
    );
    html.window.localStorage['patientData'] = jsonEncode(patient!.toJson());
  }

  Future<void> changePassword() async {
    if (!_formKeySecurity.currentState!.validate()) return;

    final newPassword = _newPasswordController.text.trim();
    if (newPassword != _confirmPasswordController.text.trim()) {
      _showErrorSnackbar('كلمة المرور الجديدة غير متطابقة');
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = html.window.localStorage['token'];
      if (token == null) throw Exception("Token not found");

      final response = await _fetchPost(
        url: 'https://localhost:7219/api/Auth/change-password',
        token: token,
        body: {
          "userId": patient!.userId,
          "currentPassword": _currentPasswordController.text.trim(),
          "newPassword": newPassword,
        },
      );

      if (!response) throw Exception("فشل تغيير كلمة المرور");

      _clearPasswordFields();
      _showSuccessSnackbar('تم تغيير كلمة المرور بنجاح');
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ: $error')),
    );
  }

  Future<bool> _fetchPut({
    required String url,
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await html.HttpRequest.request(
      url,
      method: 'PUT',
      sendData: jsonEncode(body),
      requestHeaders: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.status == 200 || response.status == 204;
  }

  Future<bool> _fetchPost({
    required String url,
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await html.HttpRequest.request(
      url,
      method: 'POST',
      sendData: jsonEncode(body),
      requestHeaders: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.status == 200 || response.status == 204;
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          locale: const Locale('ar', 'EG'),
        );
        if (picked != null) {
          setState(() => _dob = picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ الميلاد',
          border: OutlineInputBorder(),
        ),
        child: Text(
          _dob == null ? 'اختر التاريخ' : DateFormat('yyyy-MM-dd').format(_dob!),
        ),
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'فصيلة الدم',
        border: OutlineInputBorder(),
      ),
      value: _bloodType,
      items: const [
        DropdownMenuItem(value: 'A+', child: Text('A+')),
        DropdownMenuItem(value: 'A-', child: Text('A-')),
        DropdownMenuItem(value: 'B+', child: Text('B+')),
        DropdownMenuItem(value: 'B-', child: Text('B-')),
        DropdownMenuItem(value: 'AB+', child: Text('AB+')),
        DropdownMenuItem(value: 'AB-', child: Text('AB-')),
        DropdownMenuItem(value: 'O+', child: Text('O+')),
        DropdownMenuItem(value: 'O-', child: Text('O-')),
      ],
      onChanged: (val) => setState(() => _bloodType = val),
      validator: (val) => val == null ? 'يرجى اختيار فصيلة الدم' : null,
    );
  }

  Widget _buildGenderRadio() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('ذكر'),
            value: 'M',
            groupValue: _gender,
            onChanged: (val) => setState(() => _gender = val!),
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('أنثى'),
            value: 'F',
            groupValue: _gender,
            onChanged: (val) => setState(() => _gender = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyPersonal,
        child: ListView(
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? 'يرجى إدخال الاسم الكامل' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value!)) {
                  return 'يرجى إدخال بريد إلكتروني صالح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildBloodTypeDropdown(),
            const SizedBox(height: 16),
            _buildGenderRadio(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updatePatientData,
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeySecurity,
        child: ListView(
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'يرجى إدخال كلمة المرور الحالية' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'يرجى إدخال كلمة المرور الجديدة';
                }
                if (value!.length < 6) {
                  return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور الجديدة',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'يرجى تأكيد كلمة المرور الجديدة';
                }
                if (value != _newPasswordController.text) {
                  return 'كلمة المرور غير متطابقة';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: changePassword,
              child: const Text('تغيير كلمة المرور'),
            ),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return  Scaffold(
      drawer: CustomDrawer(
        fullName: patient?.user.fullName ?? '',
        email: patient?.user.email ?? '',
      ),
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المعلومات الشخصية'),
            Tab(text: 'الأمان'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(),
                _buildSecurityTab(),
              ],
            ),
   
  );
}
}