import './User_model.dart';
import './MedicalCenter_model.dart';

class Doctor {
  final int id;
  final User user;
  final String specialization;
  final String licenseNumber;
  final MedicalCenter medicalCenter;

  Doctor({
    required this.id,
    required this.user,
    required this.specialization,
    required this.licenseNumber,
    required this.medicalCenter,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      specialization: json['specialization'] ?? 'غير محدد',
      licenseNumber: json['licenseNumber'] ?? 'غير محدد',
      medicalCenter: MedicalCenter.fromJson(json['medicalCenter'] ?? {}),
    );
  }
}
