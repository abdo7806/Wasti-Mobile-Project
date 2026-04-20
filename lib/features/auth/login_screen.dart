import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  bool _obscurePassword = true;

  // دالة لاستخراج الـ Role من التوكن (مثل extractRoleFromPayload في الويب)
  String extractRoleFromToken(Map<String, dynamic> decodedToken) {
    return decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ?? 
           decodedToken['role'] ?? 
           '';
  }

  // دالة لاستخراج الـ Email من التوكن
  String extractEmailFromToken(Map<String, dynamic> decodedToken) {
    return decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/email'] ?? 
           decodedToken['email'] ?? 
           '';
  }

  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'يجب ملء جميع الحقول');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://localhost:7219/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['token'] == null) {
        setState(() => errorMessage = data['message'] ?? 'فشل تسجيل الدخول');
        return;
      }

      final token = data['token'];
      final decodedToken = JwtDecoder.decode(token);

      // استخراج الدور باستخدام الدالة المساعدة (نفس طريقة الويب)
      final userRole = extractRoleFromToken(decodedToken);
      
      if (userRole != 'Patient') {
        setState(() => errorMessage = 'هذه الواجهة مخصصة للمرضى فقط');
        return;
      }

      // استخراج البريد باستخدام الدالة المساعدة (نفس طريقة الويب)
      final userEmail = extractEmailFromToken(decodedToken);

      // حفظ التوكن والبيانات في localStorage (نفس الطريقة القديمة)
      html.window.localStorage['token'] = token;
      html.window.localStorage['userData'] = jsonEncode({
        'fullName': data['user']['fullName'],
        'userId': data['user']['id'],
        'email': userEmail,
        'role': userRole,
      });

      // توجيه المريض
      Navigator.pushReplacementNamed(context, '/patientHome');
    } catch (e) {
      setState(() => errorMessage = 'حدث خطأ أثناء الاتصال بالخادم');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.primaryColor.withOpacity(0.8),
                theme.colorScheme.secondary.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: size.width > 500 ? 500 : size.width * 0.9,
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.medical_services,
                    size: 100,
                    color: Colors.blue,
                  ),
                  Text(
                    'تسجيل الدخول',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(fontSize: 12),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ليس لديك حساب؟'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('سجل الآن'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}