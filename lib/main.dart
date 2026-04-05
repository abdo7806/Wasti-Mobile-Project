import 'package:flutter/material.dart';
import './features/auth/login_screen.dart';
import './features/auth/register_screen.dart';
import './features/patient/edit_profile_screen.dart';
import './features/patient/patient_home_screen.dart';
import './features/patient/prescriptions_screen.dart';
import 'shared/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // هذا الاستيراد الجوهري
void main() {
  runApp(const WasfatyApp());
}

class WasfatyApp extends StatelessWidget {
  const WasfatyApp({super.key});

  @override
  Widget build(BuildContext context) {
  // ...existing code...
    return MaterialApp(
      title: 'منصة وصفة',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
    GlobalMaterialLocalizations.delegate, // الخطوة 3
    GlobalWidgetsLocalizations.delegate, // الخطوة 4
  ],
  supportedLocales: [
    Locale('ar'), // الخطوة 5
  ],
  locale: Locale('ar'), // الخطوة 6
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/patientHome': (_) => const PatientHomeScreen(),
        '/prescriptions': (_) => const PrescriptionsScreen(),
        '/editProfile': (_) => const EditProfileScreen(),
      },
    );
// ...existing code...
}
  // ...existing code...
}