class Medication {
  final String name;

  Medication({required this.name});

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(name: json['name'] ?? 'غير معروف');
  }
}
