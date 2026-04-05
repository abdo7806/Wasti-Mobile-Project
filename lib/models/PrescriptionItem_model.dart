
class PrescriptionItem {
  final int id;
  final int medicationId;
  final String dosage;
  final String frequency;
  final String duration;
    // حقول الدواء المخصص
    final String? CustomMedicationName;
    final String? CustomMedicationDescription;
    final String? CustomDosageForm ;
    final String? CustomStrength;

  PrescriptionItem({
    required this.id,
    required this.medicationId,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.CustomMedicationName,
    required this.CustomMedicationDescription,
    required this.CustomDosageForm,
    required this.CustomStrength,

  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] ?? 0,
      medicationId: json['medicationId'] ?? 0,
      dosage: json['dosage'] ?? 'غير محدد',
      frequency: json['frequency']?.toString() ?? '0',
      duration: json['duration']?.toString() ?? '0',
      CustomMedicationName: json['customMedicationName'] ?? 'غير متوفر',
      CustomMedicationDescription: json['customMedicationDescription'] ?? 'غير متوفر',
      CustomDosageForm: json['customDosageForm'] ?? 'غير متوفر',
      CustomStrength: json['customStrength'] ?? 'غير متوفر',

    );
  }
}
