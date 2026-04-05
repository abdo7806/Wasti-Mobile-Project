import './Doctor_model.dart';
import './PrescriptionItem_model.dart';

class Prescription {
  final int id;
  final DateTime issuedDate;
  final bool isDispensed;
  final Doctor doctor;
  final List<PrescriptionItem> prescriptionItems;

  Prescription({
    required this.id,
    required this.issuedDate,
    required this.isDispensed,
    required this.doctor,
    required this.prescriptionItems,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? 0,
      issuedDate: DateTime.parse(json['issuedDate'] ?? DateTime.now().toString()),
      isDispensed: json['isDispensed'] ?? false,
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
      prescriptionItems: (json['prescriptionItems'] as List? ?? [])
          .map((item) => PrescriptionItem.fromJson(item ?? {}))
          .toList(),
    );
  }
}
