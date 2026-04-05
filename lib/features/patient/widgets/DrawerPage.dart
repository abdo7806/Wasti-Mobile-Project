import 'package:flutter/material.dart';
import './LogoutWidget.dart';

class CustomDrawer extends StatelessWidget {
  final String fullName;
  final String email;

  const CustomDrawer({super.key, required this.fullName, required this.email });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2D9CDB), // لون الخلفية
            ),
            accountName: Text(
              fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            accountEmail: Text(email.isNotEmpty ? email : 'البريد الإلكتروني غير متوفر'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 24, color: Color(0xFF2D9CDB)),
              ),
            ),
          ),
          _createDrawerItem(
            icon: Icons.home,
            text: 'الصفحة الرئيسية',
            onTap: () => Navigator.pushNamed(context, '/patientHome'),
          ),
          _createDrawerItem(
            icon: Icons.person,
            text: 'الملف الشخصي',
            onTap: () => Navigator.pushNamed(context, '/editProfile'),
          ),
          _createDrawerItem(
            icon: Icons.list,
            text: 'عرض الوصفات الطبية',
            onTap: () => Navigator.pushNamed(context, '/prescriptions'),
          ),
          const Divider(),
          _createDrawerItem(
            icon: Icons.logout,
            text: 'تسجيل الخروج',
            onTap: () => LogoutWidget.logout(context),
          ),
        ],
      ),
    );
  }

  Widget _createDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D9CDB)), // لون الأيقونة
      title: Text(text, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}