import 'package:flutter/material.dart';
import 'dart:html' as html;

class LogoutWidget {
  static void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('تأكيد تسجيل الخروج'),
            ],
          ),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق الحوار
              },
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('إلغاء'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                html.window.localStorage.clear();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 4),
                  Text('نعم، تسجيل الخروج'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}